#!/usr/bin/env python3
"""permute.py - decomp-permuter-style random source search on the project's exact pipeline.

usage:
  permute.py SRC.c FUNC VRAM [--unit-vram HEX] [--iters N] [--jobs N] [--seed S]
             [--name NAME] [--max-mut K] [--temp T] [--only kinds,...] [--stop-at-zero]

What it does
  1. Preprocesses SRC (system cpp, -P, -I include and the source dir) so pycparser 2.22
     (vendored, BSD-3-Clause, tools/vendor/pycparser) can parse it. Marker comments
     (SPAN / RODATA_VRAM / DATA_VRAM / LDSYM / CFLAGS / MODE) are copied from SRC to every variant.
  2. Applies 1..K random AST mutations to FUNC only (see MUTATIONS) and regenerates C.
  3. Builds each distinct source variant through the production KMC GCC 2.7.2
     compiler and normalizer, then links it at its retail address without masking.
  4. Scores with tools/decomp_score.py: (mismatch words, |size delta|). Output-hash dedup: a variant whose
     compiled bytes were already seen is not re-scored.
  5. Hill-climb with permuter-style acceptance: a variant replaces the current base when it scores
     better, or equal with probability --temp. The global best is kept separately.
  6. Every variant whose FUNC has 0 mismatching words is written to search/NAME/exact_*.c and
     re-gated as a whole unit (text + owned rodata at the real address);
     only a UNIT MATCH there is reported as EXACT.
Rejected at render time: inline asm, register variables, and volatile (FORBID). Some mutations
change evaluation or statement order and are exploratory: only exact whole-unit results are
eligible for integration, and those still require human source review.

Outputs: build/decomp_search/NAME/ledger.tsv (one row per distinct output),
build/decomp_search/NAME/best.c, and build/decomp_search/NAME/exact_*.c.
"""
import argparse, concurrent.futures, copy, hashlib, os, random, re, subprocess, sys, time
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
from pycparser import c_parser, c_ast, c_generator  # noqa: E402
import decomp_compile as kmclib  # noqa: E402
import decomp_score as mclass  # noqa: E402

R = kmclib.R
FORBID = re.compile(r"\b(asm|__asm__|volatile|register)\b")
MARKER = re.compile(r"/\*[^*]*?\b(SPAN|RODATA_VRAM|DATA_VRAM|LDSYM|CFLAGS|MODE)\b[^*]*\*/")
TYPEOF_MAP = {}


# ----------------------------------------------------------------------------- parsing
def preprocess(src, relax_prototypes=False):
    m2c_macros = [
        "-DM2C_FIELD(x,t,o)=(*(t)((char *)(x)+(o)))",
        "-DM2C_UNALIGNED32(x)=(x)",
        "-DM2C_BITWISE(t,x)=(*(t *)&(x))",
        "-DM2C_BREAK(x)=((void)0)",
    ]
    p = subprocess.run(["cpp", "-P", "-nostdinc", "-undef", *m2c_macros,
                        "-I", R + "/include", "-I", os.path.dirname(os.path.abspath(src)), src],
                       capture_output=True, text=True)
    if p.returncode:
        raise SystemExit("cpp failed:\n" + p.stderr)
    text = p.stdout
    # pycparser does not accept GCC's __typeof__(expr), but temp candidates
    # must remain reusable as parents in later campaigns.  Parse stable typedef
    # placeholders, then restore the extension after rendering the AST.
    def hide_typeof(match):
        expr = match.group(1)
        name = "decomp_typeof_" + hashlib.sha1(expr.encode()).hexdigest()[:12]
        TYPEOF_MAP[name] = expr
        return name
    text = re.sub(r"__typeof__\(([^()\n]+)\)", hide_typeof, text)
    # Raw m2c output uses '?' when it cannot infer a type.  Treat that token as
    # an integer-sized unknown for the first scoring pass; a matching candidate
    # still requires replacing every such guess with reviewed real types.
    # m2c also uses the ordinary C ternary operator, so a global replacement
    # of '?' corrupts valid expressions.  Its unknown-type token occurs only
    # where a declaration type may begin: at the start of a line or directly
    # after a parameter-list delimiter.
    text = re.sub(r"(?m)^(\s*)\?(?=\s+[*A-Za-z_])", r"\1M2C_UNK", text)
    text = re.sub(r"([,(]\s*)\?(?=\s+[*A-Za-z_])", r"\1M2C_UNK", text)
    if relax_prototypes:
        # m2c guesses prototypes from call sites and occasionally records fewer
        # parameters than another call in the same draft supplies.  K&R-style
        # declarations preserve the guessed return type while allowing the
        # compiler to score the body.  This is a fallback for search input,
        # never evidence that the relaxed prototype is correct source.
        text = re.sub(
            r"(?m)^(\s*[^;{}\n]*?\b(?:func_|gu)[A-Za-z0-9_]+)"
            r"\([^;{}\n]*\)(\s*;)\s*$",
            r"\1()\2", text,
        )
    primitive_types = {
        "s8": "signed char", "u8": "unsigned char",
        "s16": "signed short", "u16": "unsigned short",
        "s32": "signed int", "u32": "unsigned int",
        "s64": "signed long long", "u64": "unsigned long long",
        "f32": "float", "f64": "double", "M2C_UNK": "signed int",
        "M2C_UNK8": "unsigned char", "M2C_UNK16": "unsigned short",
        "M2C_UNK32": "unsigned int", "M2C_UNK64": "unsigned long long",
    }
    preamble = []
    for name in sorted(TYPEOF_MAP):
        if re.search(r"\b%s\b" % name, text):
            preamble.append("typedef int %s;" % name)
    for name, underlying in primitive_types.items():
        if re.search(r"\b%s\b" % name, text) and not re.search(
                r"\btypedef\b[^;]*\b%s\s*;" % name, text):
            preamble.append("typedef %s %s;" % (underlying, name))
    # m2c drafts often rely on a project header for NULL.  The search parser
    # intentionally does not include system headers, so lower it to the N64 C
    # representation before AST parsing and regeneration.
    text = re.sub(r"\bNULL\b", "((void *) 0)", text)
    return "\n".join(preamble) + ("\n" if preamble else "") + text


def restore_typeof(text):
    for name, expr in TYPEOF_MAP.items():
        text = re.sub(r"(?m)^typedef int %s;\s*\n?" % re.escape(name), "", text)
        text = re.sub(r"\b%s\b" % re.escape(name), "__typeof__(%s)" % expr, text)
    return text


def markers(src):
    text = open(src).read()
    out = []
    for m in re.finditer(r"/\*.*?\*/", text, re.S):
        for line in m.group(0).splitlines():
            for k in ("SPAN", "RODATA_VRAM", "DATA_VRAM", "LDSYM", "CFLAGS", "MODE"):
                mm = re.search(r"(?<![A-Z_])%s (\S.*?)\s*(\*/|$)" % k, line)
                if mm:
                    out.append("/* %s %s */" % (k, mm.group(1)))
    return "\n".join(dict.fromkeys(out)) + "\n"


def parse(text):
    return c_parser.CParser().parse(text, filename="<variant>")


def find_func(ast, name):
    for ext in ast.ext:
        if isinstance(ext, c_ast.FuncDef) and ext.decl.name == name:
            return ext
    raise SystemExit("function %s not found" % name)


# ----------------------------------------------------------------------------- mutations
COMMUT = {"+", "*", "&", "|", "^", "==", "!="}
FLIP = {"<": ">", ">": "<", "<=": ">=", ">=": "<="}


def nodes_of(node, cls):
    out = []

    class V(c_ast.NodeVisitor):
        def generic_visit(self, n):
            if isinstance(n, cls):
                out.append(n)
            for _, c in n.children():
                self.visit(c)
    V().visit(node)
    return out


FOCUS = [None]


def compounds(fn):
    cs = [c for c in nodes_of(fn.body, c_ast.Compound) if c.block_items and len(c.block_items) >= 1]
    if FOCUS[0]:
        g = c_generator.CGenerator()
        foc = []
        for c in cs:
            t = g.visit(c)
            if FOCUS[0] in t and len(t) < FOCUS_MAX[0]:
                foc.append(c)
        # nested compounds of focused ones are in scope too
        cs = foc + [n for c in foc for n in nodes_of(c, c_ast.Compound) if n is not c and n.block_items]
    return cs


FOCUS_MAX = [2500]


def exprs_in_focus(fn, cls):
    out = []
    for c in compounds(fn) if FOCUS[0] else [fn.body]:
        out += nodes_of(c, cls)
    return list({id(x): x for x in out}.values())


def is_decl(x):
    return isinstance(x, c_ast.Decl)


def _statement_effects(stmt):
    """Return conservative scalar writes, identifier reads and call presence.

    This is intentionally narrower than a C alias analysis.  It exists to
    prevent the search from improving byte scores by swapping dependent or
    externally observable operations.  Unknown memory writes are not eligible.
    """
    if not isinstance(stmt, c_ast.Assignment):
        return None
    if nodes_of(stmt, c_ast.FuncCall):
        return None
    if not isinstance(stmt.lvalue, c_ast.ID):
        return None
    write = stmt.lvalue.name
    reads = {node.name for node in nodes_of(stmt.rvalue, c_ast.ID)}
    if stmt.op != "=":
        reads.add(write)
    return {write}, reads


def statements_can_swap(first, second):
    a = _statement_effects(first)
    b = _statement_effects(second)
    if a is None or b is None:
        return False
    writes_a, reads_a = a
    writes_b, reads_b = b
    return not (writes_a & (writes_b | reads_b) or
                writes_b & (writes_a | reads_a))


def m_swap_stmts(fn, rng):
    cs = [c for c in compounds(fn) if sum(not is_decl(x) for x in c.block_items) >= 2]
    if not cs:
        return False
    c = rng.choice(cs)
    idx = [i for i, x in enumerate(c.block_items) if not is_decl(x) and not isinstance(x, (c_ast.Label, c_ast.Case, c_ast.Default))]
    pairs = [(a, b) for a, b in zip(idx, idx[1:])
             if b == a + 1 and statements_can_swap(c.block_items[a], c.block_items[b])]
    if not pairs:
        return False
    a, b = rng.choice(pairs)
    c.block_items[a], c.block_items[b] = c.block_items[b], c.block_items[a]
    return True


def m_swap_decls(fn, rng):
    cs = [c for c in compounds(fn) if sum(is_decl(x) and x.init is None for x in c.block_items) >= 2]
    if not cs:
        return False
    c = rng.choice(cs)
    idx = [i for i, x in enumerate(c.block_items) if is_decl(x) and x.init is None]
    a, b = rng.sample(idx, 2)
    c.block_items[a], c.block_items[b] = c.block_items[b], c.block_items[a]
    return True


def m_commute(fn, rng):
    ops = [b for b in exprs_in_focus(fn, c_ast.BinaryOp) if b.op in COMMUT or b.op in FLIP]
    if not ops:
        return False
    b = rng.choice(ops)
    b.left, b.right = b.right, b.left
    if b.op in FLIP:
        b.op = FLIP[b.op]
    return True


def m_invert_if(fn, rng):
    ifs = [i for i in exprs_in_focus(fn, c_ast.If) if i.iffalse is not None]
    if not ifs:
        return False
    i = rng.choice(ifs)
    i.cond = c_ast.UnaryOp("!", i.cond)
    i.iftrue, i.iffalse = i.iffalse, i.iftrue
    return True


def m_incr_form(fn, rng):
    """x++ / ++x / x += 1 / x = x + 1 (statement level only)."""
    cands = []
    for c in compounds(fn):
        for k, s in enumerate(c.block_items):
            if isinstance(s, c_ast.UnaryOp) and s.op in ("p++", "++", "p--", "--"):
                cands.append((c, k))
            elif isinstance(s, c_ast.Assignment) and s.op in ("+=", "-=") and isinstance(s.rvalue, c_ast.Constant) and s.rvalue.value == "1":
                cands.append((c, k))
    if not cands:
        return False
    c, k = rng.choice(cands)
    s = c.block_items[k]
    if isinstance(s, c_ast.UnaryOp):
        op = "+=" if "+" in s.op else "-="
        c.block_items[k] = c_ast.Assignment(op, s.expr, c_ast.Constant("int", "1"))
    else:
        c.block_items[k] = c_ast.UnaryOp("p++" if s.op == "+=" else "p--", s.lvalue)
    return True


_tmpn = [0]


def m_temp(fn, rng):
    """Hoist a sub-expression of an expression statement into a new block-local temporary
    declared with the type `int` only when the expression is a comparison/arith on ints is
    unknowable here, so the temp takes the type of a same-named existing declaration when the
    expression is a plain identifier/struct ref; otherwise skipped."""
    # find expression statements (assignments / calls) with a StructRef or ArrayRef operand
    cands = []
    for c in compounds(fn):
        for k, s in enumerate(c.block_items):
            if isinstance(s, (c_ast.Assignment, c_ast.FuncCall)):
                for r in nodes_of(s, (c_ast.StructRef,)):
                    if r is not getattr(s, "lvalue", None):
                        cands.append((c, k, s, r))
    if not cands:
        return False
    c, k, s, r = rng.choice(cands)
    _tmpn[0] += 1
    name = "pt%d" % _tmpn[0]
    # typeof via GCC extension keeps the exact type without knowing it
    decl = c_ast.Decl(name, [], [], [], [], c_ast.TypeDecl(name, [], None, c_ast.IdentifierType(["__typeof__(%s)" % c_generator.CGenerator().visit(r)])), copy.deepcopy(r), None)

    class Rep(c_ast.NodeVisitor):
        def generic_visit(self, n):
            for attr in [a for a in n.__slots__ if a not in ("coord", "__weakref__")]:
                v = getattr(n, attr, None)
                if v is r:
                    setattr(n, attr, c_ast.ID(name))
                elif isinstance(v, c_ast.Node):
                    self.visit(v)
                elif isinstance(v, list):
                    for i, e in enumerate(v):
                        if e is r:
                            v[i] = c_ast.ID(name)
                        elif isinstance(e, c_ast.Node):
                            self.visit(e)
    Rep().visit(s)
    c.block_items[k] = c_ast.Compound([decl, s])
    return True


def m_address_temp(fn, rng):
    """Route a struct-ref call argument through a block-local pointer.

    This changes pseudo birth/lifetime like a value temp, but leaves the final
    argument as a memory dereference.  It is useful when retail uses a direct
    integer-word argument load and a value temp would force lwc1/mfc1.
    """
    candidates = []
    for c in compounds(fn):
        for k, statement in enumerate(c.block_items):
            if not isinstance(statement, c_ast.FuncCall):
                continue
            for ref in nodes_of(statement.args, c_ast.StructRef):
                candidates.append((c, k, statement, ref))
    if not candidates:
        return False
    c, k, statement, ref = rng.choice(candidates)
    _tmpn[0] += 1
    name = "pa%d" % _tmpn[0]
    rendered = c_generator.CGenerator().visit(ref)
    decl = c_ast.Decl(
        name, [], [], [], [],
        c_ast.TypeDecl(name, [], None,
                       c_ast.IdentifierType(["__typeof__(&%s)" % rendered])),
        c_ast.UnaryOp("&", copy.deepcopy(ref)), None,
    )

    class Rep(c_ast.NodeVisitor):
        def generic_visit(self, node):
            for attr in [a for a in node.__slots__ if a not in ("coord", "__weakref__")]:
                value = getattr(node, attr, None)
                if value is ref:
                    setattr(node, attr, c_ast.UnaryOp("*", c_ast.ID(name)))
                elif isinstance(value, c_ast.Node):
                    self.visit(value)
                elif isinstance(value, list):
                    for index, child in enumerate(value):
                        if child is ref:
                            value[index] = c_ast.UnaryOp("*", c_ast.ID(name))
                        elif isinstance(child, c_ast.Node):
                            self.visit(child)
    Rep().visit(statement)
    c.block_items[k] = c_ast.Compound([decl, statement])
    return True


def m_inline_address_alias(fn, rng):
    """Replace a stable local `p = &object` alias with direct `&object` uses."""
    candidates = []
    for compound in compounds(fn):
        items = compound.block_items or []
        declarations = {item.name: index for index, item in enumerate(items)
                        if is_decl(item) and item.init is None and
                        isinstance(item.type, c_ast.PtrDecl)}
        for index, statement in enumerate(items):
            if not (isinstance(statement, c_ast.Assignment) and statement.op == "=" and
                    isinstance(statement.lvalue, c_ast.ID) and
                    statement.lvalue.name in declarations and
                    isinstance(statement.rvalue, c_ast.UnaryOp) and
                    statement.rvalue.op == "&"):
                continue
            name = statement.lvalue.name
            writes = 0
            uses = []
            for later_index, later in enumerate(items[index + 1:], index + 1):
                for assignment in nodes_of(later, c_ast.Assignment):
                    if isinstance(assignment.lvalue, c_ast.ID) and \
                            assignment.lvalue.name == name:
                        writes += 1
                for ident in nodes_of(later, c_ast.ID):
                    if ident.name == name:
                        uses.append((later_index, ident))
            if writes == 0 and len(uses) >= 2:
                candidates.append((compound, declarations[name], index, name,
                                   statement.rvalue, uses))
    if not candidates:
        return False
    compound, decl_index, assignment_index, name, address, uses = rng.choice(candidates)
    for statement_index, ident in uses:
        statement = compound.block_items[statement_index]

        class Rep(c_ast.NodeVisitor):
            def generic_visit(self, node):
                for attr in [a for a in node.__slots__ if a not in ("coord", "__weakref__")]:
                    value = getattr(node, attr, None)
                    if value is ident:
                        setattr(node, attr, copy.deepcopy(address))
                    elif isinstance(value, c_ast.Node):
                        self.visit(value)
                    elif isinstance(value, list):
                        for child_index, child in enumerate(value):
                            if child is ident:
                                value[child_index] = copy.deepcopy(address)
                            elif isinstance(child, c_ast.Node):
                                self.visit(child)
        Rep().visit(statement)
    for remove_index in sorted((decl_index, assignment_index), reverse=True):
        del compound.block_items[remove_index]
    return True


def m_sink_address_assignment(fn, rng):
    """Move `p = &local` immediately before its first later use."""
    candidates = []
    for compound in compounds(fn):
        items = compound.block_items or []
        for index, statement in enumerate(items):
            if not (isinstance(statement, c_ast.Assignment) and statement.op == "=" and
                    isinstance(statement.lvalue, c_ast.ID) and
                    isinstance(statement.rvalue, c_ast.UnaryOp) and
                    statement.rvalue.op == "&" and
                    isinstance(statement.rvalue.expr, c_ast.ID)):
                continue
            name = statement.lvalue.name
            referent = statement.rvalue.expr.name
            first_use = None
            safe = True
            for later_index, later in enumerate(items[index + 1:], index + 1):
                if any(ident.name == name for ident in nodes_of(later, c_ast.ID)):
                    first_use = later_index
                    break
                for assignment in nodes_of(later, c_ast.Assignment):
                    if isinstance(assignment.lvalue, c_ast.ID) and \
                            assignment.lvalue.name in (name, referent):
                        safe = False
                if nodes_of(later, c_ast.FuncCall) and any(
                        ident.name == referent for ident in nodes_of(later, c_ast.ID)):
                    safe = False
            if safe and first_use is not None and first_use > index + 1:
                candidates.append((compound, index, first_use))
    if not candidates:
        return False
    compound, index, first_use = rng.choice(candidates)
    statement = compound.block_items.pop(index)
    # Removing the earlier item shifts the original first-use index by one.
    compound.block_items.insert(first_use - 1, statement)
    return True


def m_repeat_address_assignment(fn, rng):
    """Repeat a stable `p = &local` immediately before a later use."""
    candidates = []
    generator = c_generator.CGenerator()
    for compound in compounds(fn):
        items = compound.block_items or []
        for assignment in items:
            if not (isinstance(assignment, c_ast.Assignment) and assignment.op == "=" and
                    isinstance(assignment.lvalue, c_ast.ID) and
                    isinstance(assignment.rvalue, c_ast.UnaryOp) and
                    assignment.rvalue.op == "&" and
                    isinstance(assignment.rvalue.expr, c_ast.ID)):
                continue
            name = assignment.lvalue.name
            spelling = generator.visit(assignment)
            start = items.index(assignment)
            for use_index in range(start + 1, len(items)):
                statement = items[use_index]
                if not any(ident.name == name for ident in nodes_of(statement, c_ast.ID)):
                    continue
                if use_index and generator.visit(items[use_index - 1]) == spelling:
                    continue
                candidates.append((compound, use_index, assignment))
    if not candidates:
        return False
    compound, use_index, assignment = rng.choice(candidates)
    compound.block_items.insert(use_index, copy.deepcopy(assignment))
    return True


def m_move_decl(fn, rng):
    """Move an uninitialised declaration from a block into one of its directly nested compounds
    that uses it exclusively, or one level outward."""
    cs = compounds(fn)
    moves = []
    for c in cs:
        for k, d in enumerate(c.block_items):
            if not (is_decl(d) and d.init is None and isinstance(d.type, (c_ast.TypeDecl, c_ast.ArrayDecl, c_ast.PtrDecl))):
                continue
            users = [s for s in c.block_items if s is not d and any(isinstance(i, c_ast.ID) and i.name == d.name for i in nodes_of(s, c_ast.ID))]
            if len(users) == 1:
                total = sum(1 for i in nodes_of(users[0], c_ast.ID) if i.name == d.name)
                for inner in nodes_of(users[0], c_ast.Compound):
                    # every use of the name must be inside the target compound (no shadowing of a
                    # for/while header or an if condition outside it)
                    if inner.block_items and sum(1 for i in nodes_of(inner, c_ast.ID) if i.name == d.name) == total:
                        moves.append(("in", c, k, inner))
    if not moves:
        return False
    kind, c, k, target = rng.choice(moves)
    d = c.block_items.pop(k)
    target.block_items = [d] + (target.block_items or [])
    return True


def m_split_assign(fn, rng):
    """x op= e  <->  x = x op e (statement level)."""
    cands = []
    for c in compounds(fn):
        for k, s in enumerate(c.block_items):
            if isinstance(s, c_ast.Assignment):
                if s.op in ("|=", "&=", "^=", "+=", "-=", "<<=", ">>=", "*="):
                    cands.append((c, k, "split"))
                elif s.op == "=" and isinstance(s.rvalue, c_ast.BinaryOp) and \
                        c_generator.CGenerator().visit(s.rvalue.left) == c_generator.CGenerator().visit(s.lvalue) and \
                        s.rvalue.op in ("|", "&", "^", "+", "-", "<<", ">>", "*"):
                    cands.append((c, k, "join"))
    if not cands:
        return False
    c, k, how = rng.choice(cands)
    s = c.block_items[k]
    if how == "split":
        c.block_items[k] = c_ast.Assignment("=", s.lvalue, c_ast.BinaryOp(s.op[:-1], copy.deepcopy(s.lvalue), s.rvalue))
    else:
        c.block_items[k] = c_ast.Assignment(s.rvalue.op + "=", s.lvalue, s.rvalue.right)
    return True


def m_decl_init(fn, rng):
    """T a; a = e;  <->  T a = e;  (first assignment right after the declarations)."""
    cands = []
    for c in compounds(fn):
        items = c.block_items
        for k, d in enumerate(items):
            if is_decl(d) and isinstance(d.type, c_ast.TypeDecl):
                if d.init is not None:
                    cands.append((c, k, "split"))
                else:
                    for j in range(k + 1, len(items)):
                        s = items[j]
                        if is_decl(s):
                            continue
                        if isinstance(s, c_ast.Assignment) and s.op == "=" and isinstance(s.lvalue, c_ast.ID) and s.lvalue.name == d.name:
                            cands.append((c, k, ("join", j)))
                        break
    if not cands:
        return False
    c, k, how = rng.choice(cands)
    d = c.block_items[k]
    if how == "split":
        e = d.init; d.init = None
        last = max(i for i, x in enumerate(c.block_items) if is_decl(x))
        c.block_items.insert(last + 1, c_ast.Assignment("=", c_ast.ID(d.name), e))
    else:
        j = how[1]
        d.init = c.block_items[j].rvalue
        del c.block_items[j]
    return True


def m_copy_temp(fn, rng):
    """Replace one use of a local/param variable inside an expression statement by a fresh
    block-local copy `__typeof__(v) t = v;` declared right before it."""
    cands = []
    for c in compounds(fn):
        for k, s in enumerate(c.block_items):
            if isinstance(s, (c_ast.Assignment, c_ast.FuncCall, c_ast.If, c_ast.Return)):
                # for an if, only the condition is evaluated before the body could change the variable
                scope = s.cond if isinstance(s, c_ast.If) else s
                for i in nodes_of(scope, c_ast.ID):
                    if i is not getattr(s, "lvalue", None) and re.match(r"^[a-z]\w*$", i.name) and not i.name.startswith("func_"):
                        cands.append((c, k, s, i))
    if not cands:
        return False
    c, k, s, ident = rng.choice(cands)
    _tmpn[0] += 1
    name = "ct%d" % _tmpn[0]
    decl = c_ast.Decl(name, [], [], [], [], c_ast.TypeDecl(name, [], None, c_ast.IdentifierType(["__typeof__(%s)" % ident.name])), c_ast.ID(ident.name), None)
    ident.name = name
    c.block_items[k] = c_ast.Compound([decl, s])
    return True


def m_move_decl_out(fn, rng):
    """Move an uninitialised declaration from a nested compound to its parent compound's
    declaration list (widening the scope)."""
    moves = []
    for parent in compounds(fn):
        for k, st in enumerate(parent.block_items):
            for inner in nodes_of(st, c_ast.Compound):
                for j, d in enumerate(inner.block_items or []):
                    if is_decl(d) and d.init is None and isinstance(d.type, (c_ast.TypeDecl, c_ast.ArrayDecl, c_ast.PtrDecl)):
                        if not any(is_decl(x) and x.name == d.name for x in parent.block_items):
                            moves.append((parent, inner, j))
    if not moves:
        return False
    parent, inner, j = rng.choice(moves)
    d = inner.block_items.pop(j)
    n = 0
    while n < len(parent.block_items) and is_decl(parent.block_items[n]):
        n += 1
    parent.block_items.insert(n, d)
    return True


INTEGER_TYPES = (
    ("signed", "char"), ("unsigned", "char"),
    ("signed", "short"), ("unsigned", "short"),
    ("signed", "int"), ("unsigned", "int"),
    ("int",), ("unsigned",),
)


def integer_decl_candidates(fn, parameters=False):
    """Return scalar integer declarations, excluding pointers/arrays/structs.

    These mutations are exploratory because changing an inferred width can
    change behavior.  A zero-diff result still needs type/semantic review and
    the existing whole-unit gate before integration.
    """
    if parameters:
        args = getattr(getattr(fn.decl, "type", None), "args", None)
        decls = list(args.params or []) if args else []
    else:
        decls = nodes_of(fn.body, c_ast.Decl)
    out = []
    for decl in decls:
        typ = decl.type
        if not isinstance(typ, c_ast.TypeDecl):
            continue
        ident = typ.type
        if not isinstance(ident, c_ast.IdentifierType):
            continue
        names = tuple(ident.names)
        joined = " ".join(names)
        if any(token in joined for token in ("float", "double", "void")):
            continue
        # Struct/union/enum declarations are represented differently; the
        # remaining IdentifierType nodes are typedefs or builtin scalars.
        out.append((decl, ident))
    return out


def mutate_integer_type(fn, rng, parameters=False):
    candidates = integer_decl_candidates(fn, parameters)
    if not candidates:
        return False
    _, ident = rng.choice(candidates)
    choices = [list(names) for names in INTEGER_TYPES if tuple(ident.names) != names]
    if not choices:
        return False
    ident.names = rng.choice(choices)
    return True


def m_int_type(fn, rng):
    """Vary one block-local scalar integer declaration's width/signedness."""
    return mutate_integer_type(fn, rng, parameters=False)


def m_param_type(fn, rng):
    """Vary one scalar parameter's integer width/signedness."""
    return mutate_integer_type(fn, rng, parameters=True)


def m_alias_uses(fn, rng):
    """Create a block-local alias and move a subset of later uses to it.

    This targets GCC 2.7.2 pseudo birth order and live-range priority.  It is
    normally semantics-preserving for immutable scalar and pointer locals;
    generated exact candidates still require review because this lightweight
    AST pass does not prove that the selected value is never reassigned.
    """
    candidates = []
    for compound in compounds(fn):
        items = compound.block_items or []
        declared = []
        for index, item in enumerate(items):
            if is_decl(item) and item.name and item.init is not None and not isinstance(
                    item.type, (c_ast.ArrayDecl, c_ast.FuncDecl)):
                declared.append((item.name, index))
        for name, decl_index in declared:
            reassigned = False
            for statement in items[decl_index + 1:]:
                for assignment in nodes_of(statement, c_ast.Assignment):
                    if isinstance(assignment.lvalue, c_ast.ID) and \
                            assignment.lvalue.name == name:
                        reassigned = True
                for unary in nodes_of(statement, c_ast.UnaryOp):
                    if unary.op in ("p++", "++", "p--", "--") and \
                            isinstance(unary.expr, c_ast.ID) and unary.expr.name == name:
                        reassigned = True
            if reassigned:
                continue
            uses = []
            for statement_index in range(decl_index + 1, len(items)):
                statement = items[statement_index]
                # Avoid declarations that shadow the same spelling.
                if is_decl(statement) and statement.name == name:
                    break
                for ident in nodes_of(statement, c_ast.ID):
                    if ident.name == name:
                        # Replacing the left side of a direct assignment would
                        # give the alias different values rather than merely a
                        # different lifetime.
                        if isinstance(statement, c_ast.Assignment) and \
                                isinstance(statement.lvalue, c_ast.ID) and \
                                statement.lvalue is ident:
                            continue
                        uses.append((statement_index, ident))
            if len(uses) >= 2:
                candidates.append((compound, name, decl_index, uses))
    if not candidates:
        return False
    compound, name, decl_index, uses = rng.choice(candidates)
    _tmpn[0] += 1
    alias = "au%d" % _tmpn[0]
    decl = c_ast.Decl(
        alias, [], [], [], [],
        c_ast.TypeDecl(alias, [], None,
                       c_ast.IdentifierType(["__typeof__(%s)" % name])),
        c_ast.ID(name), None,
    )
    # Prefer contiguous suffixes (the source idiom most often seen in matched
    # units), but sample arbitrary partitions as well.
    if rng.random() < 0.7:
        first = rng.randrange(1, len(uses))
        selected = uses[first:]
    else:
        selected = [use for use in uses if rng.random() < 0.5]
        if not selected or len(selected) == len(uses):
            selected = uses[len(uses) // 2:]
    for _, ident in selected:
        ident.name = alias
    insert_at = decl_index + 1
    while insert_at < len(compound.block_items) and is_decl(compound.block_items[insert_at]):
        insert_at += 1
    compound.block_items.insert(insert_at, decl)
    return True


MUTATIONS = {
    "swap_stmts": m_swap_stmts, "swap_decls": m_swap_decls, "commute": m_commute,
    "invert_if": m_invert_if, "incr_form": m_incr_form, "temp": m_temp, "move_decl": m_move_decl,
    "split_assign": m_split_assign, "decl_init": m_decl_init, "copy_temp": m_copy_temp,
    "move_decl_out": m_move_decl_out, "int_type": m_int_type,
    "param_type": m_param_type, "alias_uses": m_alias_uses,
    "address_temp": m_address_temp,
    "inline_address_alias": m_inline_address_alias,
    "sink_address_assignment": m_sink_address_assignment,
    "repeat_address_assignment": m_repeat_address_assignment,
}


# ----------------------------------------------------------------------------- evaluation
def evaluate(job):
    src, text, vram, func, pipeline = job
    try:
        b = kmclib.build(src, vram, focus=func, text=text, pipeline=pipeline)
        r = mclass.classify(b, func)
        h = hashlib.sha1(b["text"]).hexdigest()[:16] if isinstance(b.get("text"), (bytes, bytearray)) else b["hash"]
        return dict(ok=True, words=r["words"], size=r["built_size"], rom=r["rom_size"], hash=h)
    except Exception as e:  # build errors are expected for some mutations
        # Preserve the complete diagnostic.  Truncating this used to hide the
        # normalizer's actual failure after the command prefix, making a
        # toolchain/context failure look like an invalid source mutation.
        return dict(ok=False, err=str(e))


def score(r):
    if not r["ok"]:
        return None
    return (r["words"] + 4 * abs(r["size"] - r["rom"]) // 4, abs(r["size"] - r["rom"]))


def unit_gate(path, unit_vram, pipeline="production"):
    try:
        built = kmclib.build(path, unit_vram, pipeline=pipeline)
        end = built["span"]
        if end is None:
            return False, "source has no SPAN marker"
        expected_size = end - unit_vram
        text_ok = (built["tsz"] == expected_size and
                   built["text"] == kmclib.rom_bytes(unit_vram, expected_size))
        rodata_ok = True
        if built["rodata"] is not None:
            if built["rodata_vram"] is None:
                rodata_ok = False
            else:
                rodata_ok = built["rodata"] == kmclib.rom_bytes(
                    built["rodata_vram"], len(built["rodata"]))
        return text_ok and rodata_ok, (
            "text=%s size=0x%X/0x%X rodata=%s" %
            ("MATCH" if text_ok else "DIFF", built["tsz"], expected_size,
             "MATCH" if rodata_ok else "DIFF"))
    except Exception as exc:
        return False, str(exc)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src"); ap.add_argument("func"); ap.add_argument("vram")
    ap.add_argument("--unit-vram"); ap.add_argument("--iters", type=int, default=400)
    ap.add_argument("--jobs", type=int, default=8); ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--name"); ap.add_argument("--max-mut", type=int, default=2)
    ap.add_argument("--temp", type=float, default=0.3); ap.add_argument("--only")
    ap.add_argument("--stop-at-zero", action="store_true")
    ap.add_argument("--focus", help="only mutate compounds whose code contains this text")
    ap.add_argument("--focus-max", type=int, default=2500)
    ap.add_argument("--pipeline", choices=("production", "raw-kmc", "asn64"),
                    default="production")
    a = ap.parse_args()
    FOCUS[0] = a.focus; FOCUS_MAX[0] = a.focus_max
    vram = int(a.vram, 16); uvram = int(a.unit_vram, 16) if a.unit_vram else vram
    name = a.name or "%s_%s" % (os.path.splitext(os.path.basename(a.src))[0], a.seed)
    outd = os.path.join(ROOT, "build", "decomp_search", name)
    os.makedirs(outd, exist_ok=True)
    rng = random.Random(a.seed)
    mk = markers(a.src)
    base_ast = parse(preprocess(a.src))
    gen = c_generator.CGenerator()
    kinds = [k for k in MUTATIONS if not a.only or k in a.only.split(",")]

    if a.focus and not compounds(find_func(base_ast, a.func)):
        raise SystemExit(
            "--focus text does not occur in a mutable compound inside %s: %r"
            % (a.func, a.focus)
        )

    def render(ast):
        t = mk + restore_typeof(gen.visit(ast))
        if FORBID.search(re.sub(r"__typeof__", "", t)):
            return None
        return t

    base_text = render(base_ast)
    r0 = evaluate((a.src, base_text, vram, a.func, a.pipeline))
    if not r0["ok"]:
        try:
            relaxed_ast = parse(preprocess(a.src, relax_prototypes=True))
            relaxed_text = mk + restore_typeof(gen.visit(relaxed_ast))
            relaxed = evaluate((a.src, relaxed_text, vram, a.func, a.pipeline))
        except Exception:
            relaxed = {"ok": False}
        if relaxed.get("ok"):
            print("baseline required relaxed m2c extern prototypes", flush=True)
            base_ast, base_text, r0 = relaxed_ast, relaxed_text, relaxed
        else:
            raise SystemExit("baseline does not build after regeneration: " + r0["err"])
    cur_ast, cur_score = base_ast, score(r0)
    best_ast, best_score = base_ast, cur_score
    seen = {r0["hash"]: cur_score}
    source_seen = {hashlib.sha1(base_text.encode()).hexdigest()}
    led = open(os.path.join(outd, "ledger.tsv"), "a")
    led.write("# %s seed=%d func=%s vram=%X pipeline=%s baseline=%s\n" %
              (time.strftime("%F %T"), a.seed, a.func, vram, a.pipeline, cur_score))
    print("baseline", cur_score, "kinds", kinds, flush=True)
    best_path = os.path.join(outd, "best.c")
    open(best_path, "w").write(base_text)
    exact = []
    if r0["words"] == 0 and r0["size"] == r0["rom"]:
        ok, report = unit_gate(best_path, uvram, a.pipeline)
        exact.append((best_path, ok))
        print("  zero-word baseline -> %s (%s)" %
              ("UNIT MATCH" if ok else "unit DIFF", report), flush=True)
        if ok and a.stop_at_zero:
            with open(os.path.join(outd, "summary.tsv"), "a") as fh:
                fh.write("\t".join([a.func, best_path, a.pipeline, "-", "0",
                                    "UNIT MATCH", "-", "baseline unit match"]) + "\n")
            print("done: baseline is an exact whole-unit match")
            return
    t0 = time.time(); done = 0; generated = 0; nfail = 0; batch = a.jobs * 2
    max_generated = max(a.iters * 20, 1000)
    empty_batches = 0
    with concurrent.futures.ProcessPoolExecutor(a.jobs) as ex:
        while done < a.iters and generated < max_generated:
            jobs, asts, descs = [], [], []
            for _ in range(batch):
                generated += 1
                ast = copy.deepcopy(cur_ast)
                fn = find_func(ast, a.func)
                applied = []
                for _ in range(rng.randint(1, a.max_mut)):
                    k = rng.choice(kinds)
                    try:
                        if MUTATIONS[k](fn, rng):
                            applied.append(k)
                    except Exception:
                        pass
                if not applied:
                    continue
                t = render(ast)
                if t is None:
                    continue
                source_hash = hashlib.sha1(t.encode()).hexdigest()
                if source_hash in source_seen:
                    continue
                source_seen.add(source_hash)
                jobs.append((a.src, t, vram, a.func, a.pipeline)); asts.append(ast); descs.append("+".join(applied))
            if not jobs:
                empty_batches += 1
                if empty_batches >= 50:
                    raise SystemExit(
                        "no distinct source variants generated in fifty batches; "
                        "broaden --focus or --only"
                    )
                continue
            empty_batches = 0
            if done and done % 400 < batch:
                print("[%5d %5.0fs] sources %d outputs %d fails %d current %s best %s" %
                      (done, time.time() - t0, len(source_seen), len(seen), nfail,
                       cur_score, best_score), flush=True)
            for j, ast, d, r in zip(jobs, asts, descs, ex.map(evaluate, jobs)):
                done += 1
                s = score(r)
                if s is None:
                    nfail += 1
                    if nfail <= 3:
                        open(os.path.join(outd, "fail_%d.c" % nfail), "w").write(j[1] + "\n/* " + r.get("err", "").replace("*/", "") + " */\n")
                    continue
                if r["hash"] in seen:
                    continue
                seen[r["hash"]] = s
                led.write("%s\t%s\t%d\t0x%X\t%s\n" % (d, r["hash"], r["words"], r["size"], s)); led.flush()
                if s < cur_score or (s == cur_score and rng.random() < a.temp):
                    cur_ast, cur_score = ast, s
                if s < best_score:
                    best_ast, best_score = ast, s
                    open(os.path.join(outd, "best.c"), "w").write(j[1])
                    print("[%5d %5.0fs] best %s via %s" % (done, time.time() - t0, s, d), flush=True)
                if r["words"] == 0 and r["size"] == r["rom"]:
                    p = os.path.join(outd, "exact_%d.c" % len(exact))
                    open(p, "w").write(j[1])
                    ok, out = unit_gate(p, uvram, a.pipeline)
                    exact.append((p, ok))
                    print("  zero-word variant %s -> %s" % (p, "UNIT MATCH" if ok else "unit DIFF"), flush=True)
                    if ok and a.stop_at_zero:
                        done = a.iters
                        break
    led.close()
    exp = os.path.join(outd, "summary.tsv")
    with open(exp, "a") as fh:
        fh.write("\t".join([a.func, os.path.join(outd, "best.c"), a.pipeline, "-", str(best_score[0]),
                            "UNIT MATCH" if any(ok for _, ok in exact) else "DIFF", "-",
                            "permute.py seed=%d iters=%d kinds=%s distinct=%d" % (a.seed, done, ",".join(kinds), len(seen))]) + "\n")
    print("done: %d compiled / %d generated, %d distinct sources, %d distinct outputs, best %s, unit-exact %d" %
          (done, generated, len(source_seen), len(seen), best_score,
           sum(ok for _, ok in exact)))


if __name__ == "__main__":
    main()
