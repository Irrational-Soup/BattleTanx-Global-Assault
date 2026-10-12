#!/usr/bin/env python3
"""Structured mismatch classifier for one function of a KMC GCC candidate.

usage: mclass.py SRC.c UNIT_VRAM FUNC [--json OUT.json] [--quiet]
       (as a library: classify(build_result, func) -> dict)

The function is linked at its own catalogue address (FOCUS) so that earlier
size differences in the unit do not shift it. Built and ROM instructions are
aligned by opcode (difflib on mnemonics, autojunk off), then every difference is
put in exactly one class:

  regname      same opcode and operand shape, only register names differ
  stack        sp-relative offset / frame size differs (local-slot layout)
  literal      immediate of a %hi/%lo or literal-pool access differs (rodata placement)
  call_disp    jal to the same named function whose address differs (callee size/placement)
  call         jal to a different function
  branch_tgt   same branch, different target (consequence of an earlier insert/delete)
  branch_inv   branch replaced by its inverse (beq<->bne, beqz<->bnez, ...): control-flow shape
  imm          other immediate differences
  schedule     instruction present in both but at a different position (moved)
  insert       instruction only in built output
  delete       instruction only in ROM
  replace      different opcode in the same slot, not explained above

It also derives the built->ROM register map over aligned pairs (consistency tells
whether a pure renaming would fix the function), frame sizes and saved-register
sets, and basic-block counts. 'pure_regname' is true when opcodes and CFG are
identical and every difference is a consistent register renaming.
"""
import argparse, collections, difflib, json, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import decomp_compile as kmclib

INV = {("beq", "bne"), ("bne", "beq"), ("beqz", "bnez"), ("bnez", "beqz"), ("blez", "bgtz"), ("bgtz", "blez"),
       ("bltz", "bgez"), ("bgez", "bltz"), ("bc1t", "bc1f"), ("bc1f", "bc1t"), ("beql", "bnel"), ("bnel", "beql"),
       ("beqzl", "bnezl"), ("bnezl", "beqzl")}
BRANCH = re.compile(r"^(b|bc1[tf]l?|beq|bne|beqz|bnez|blez|bgtz|bltz|bgez|beql|bnel|beqzl|bnezl|blezl|bgtzl|bltzl|bgezl|bal|bltzal|bgezal)$")
REG = re.compile(r"^\$?(zero|at|v[01]|a[0-3]|t[0-9]|s[0-8]|k[01]|gp|sp|fp|ra|f\d+|fcc\d)$")
MEM = re.compile(r"^(-?(?:0x)?[0-9a-f]+)\((\w+)\)$")


def _shape(ins):
    m, ops = ins[2], ins[3]
    out = []
    for o in ops:
        if REG.match(o):
            out.append("R")
        elif MEM.match(o):
            out.append("M")
        else:
            out.append("I")
    return m + ":" + ",".join(out)


def _regs(ops):
    rs = []
    for o in ops:
        if REG.match(o):
            rs.append(o)
        else:
            mm = MEM.match(o)
            if mm:
                rs.append(mm.group(2))
    return rs


def _imms(ops):
    rs = []
    for o in ops:
        mm = MEM.match(o)
        if mm:
            rs.append(mm.group(1))
        elif not REG.match(o):
            rs.append(o)
    return rs


def frame(ins):
    size = 0
    saved = []
    for a, w, m, ops in ins[:24]:
        if m == "addiu" and ops[:2] == ["sp", "sp"] and ops[2].startswith("-"):
            size = int(ops[2], 0) * -1
        mm = MEM.match(ops[1]) if m in ("sw", "sd", "swc1", "sdc1") and len(ops) == 2 else None
        if mm and mm.group(2) == "sp" and ops[0] in ("ra", "fp") + tuple("s%d" % i for i in range(9)) + tuple("f%d" % i for i in range(20, 32)):
            saved.append(ops[0])
    return dict(size=size, saved=sorted(set(saved)))


def blocks(ins):
    n = 1
    for i, x in enumerate(ins):
        if BRANCH.match(x[2]) or x[2] in ("j", "jr"):
            n += 1
    return n


def classify(b, func, names=None):
    built_b, rom_b, ra, rn, ba = kmclib.func_words(b, func)
    bi = kmclib.disasm(built_b, ba)
    ri = kmclib.disasm(rom_b, ra)
    cat = kmclib.catalogue()
    rev = {v[0]: k for k, v in cat.items()}
    brev = {}
    for k, v in b["syms"].items():
        brev.setdefault(v, k)
    ev = []
    cnt = collections.Counter()
    regmap = collections.defaultdict(collections.Counter)
    sm = difflib.SequenceMatcher(None, [x[2] for x in bi], [x[2] for x in ri], autojunk=False)
    only_b, only_r = [], []

    def pair(x, y):
        if x[1] == y[1]:
            return None
        if _shape(x) != _shape(y):
            return "replace"
        rx, ry = _regs(x[3]), _regs(y[3])
        ix, iy = _imms(x[3]), _imms(y[3])
        for p, q in zip(rx, ry):
            regmap[p][q] += 1
        if x[2] == "jal":
            tx, ty = int(ix[0], 16), int(iy[0], 16)
            nx, ny = brev.get(tx), rev.get(ty)
            return "call_disp" if nx and nx == ny else "call"
        if BRANCH.match(x[2]) or x[2] == "j":
            if rx != ry:
                return "regname" if (int(ix[-1], 16) - x[0]) == (int(iy[-1], 16) - y[0]) else "branch_tgt"
            return "branch_tgt"
        if ix != iy:
            if "sp" in rx or "sp" in ry:
                return "stack"
            if x[2] in ("lui",) or any(o in ("lwc1", "ldc1", "swc1", "sdc1", "lw", "lh", "lhu", "lb", "lbu", "sw", "sh", "sb", "addiu") for o in (x[2],)):
                return "literal"
            return "imm"
        return "regname"

    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal":
            for x, y in zip(bi[i1:i2], ri[j1:j2]):
                c = pair(x, y)
                if c:
                    cnt[c] += 1
                    ev.append(dict(cls=c, built="%08x %s %s" % (x[0], x[2], ",".join(x[3])),
                                   rom="%08x %s %s" % (y[0], y[2], ",".join(y[3]))))
        elif tag == "replace" and i2 - i1 == j2 - j1:
            for x, y in zip(bi[i1:i2], ri[j1:j2]):
                c = "branch_inv" if (x[2], y[2]) in INV else None
                if c:
                    cnt[c] += 1
                    ev.append(dict(cls=c, built="%08x %s %s" % (x[0], x[2], ",".join(x[3])),
                                   rom="%08x %s %s" % (y[0], y[2], ",".join(y[3]))))
                else:
                    only_b.append(x)
                    only_r.append(y)
        else:
            only_b += bi[i1:i2]
            only_r += ri[j1:j2]
    # moved instructions: same opcode shape on both sides, different position
    pool = collections.defaultdict(list)
    for y in only_r:
        pool[_shape(y)].append(y)
    left_b = []
    for x in only_b:
        if pool[_shape(x)]:
            y = pool[_shape(x)].pop(0)
            for p, q in zip(_regs(x[3]), _regs(y[3])):
                regmap[p][q] += 1
            cnt["schedule"] += 1
            ev.append(dict(cls="schedule", built="%08x %s %s" % (x[0], x[2], ",".join(x[3])),
                           rom="%08x %s %s" % (y[0], y[2], ",".join(y[3]))))
        else:
            left_b.append(x)
    left_r = [y for v in pool.values() for y in v]
    for x in left_b:
        cnt["insert"] += 1
        ev.append(dict(cls="insert", built="%08x %s %s" % (x[0], x[2], ",".join(x[3])), rom=""))
    for y in sorted(left_r):
        cnt["delete"] += 1
        ev.append(dict(cls="delete", built="", rom="%08x %s %s" % (y[0], y[2], ",".join(y[3]))))
    # register map consistency
    rm = {}
    conflicts = []
    for p, c in regmap.items():
        q, n = c.most_common(1)[0]
        rm[p] = q
        if len(c) > 1:
            conflicts.append("%s->%s" % (p, "/".join("%s:%d" % kv for kv in c.most_common())))
    inj = collections.Counter(v for v in rm.values())
    conflicts += ["many->%s" % k for k, v in inj.items() if v > 1]
    renames = {p: q for p, q in rm.items() if p != q}
    words = sum(1 for i in range(0, max(len(built_b), len(rom_b)), 4) if built_b[i:i + 4] != rom_b[i:i + 4])
    fb, fr = frame(bi), frame(ri)
    structural = sum(cnt[k] for k in ("insert", "delete", "replace", "branch_inv", "call"))
    res = dict(func=func, rom_addr="%08X" % ra, built_size=len(built_b), rom_size=rn, words=words,
               classes=dict(cnt), aligned_diffs=sum(cnt.values()), structural=structural,
               opcode_identical=[x[2] for x in bi] == [x[2] for x in ri],
               blocks=dict(built=blocks(bi), rom=blocks(ri)), frame=dict(built=fb, rom=fr),
               renames=renames, reg_conflicts=conflicts,
               pure_regname=([x[2] for x in bi] == [x[2] for x in ri]) and set(cnt) <= {"regname"} and not conflicts,
               events=ev)
    return res


def summary(r, limit=40):
    out = ["%s @%s  built 0x%X / rom 0x%X  words %d  aligned-diffs %d  structural %d  opcode-identical %s  pure-regname %s"
           % (r["func"], r["rom_addr"], r["built_size"], r["rom_size"], r["words"], r["aligned_diffs"], r["structural"],
              r["opcode_identical"], r["pure_regname"])]
    out.append("  classes: " + ", ".join("%s=%d" % kv for kv in sorted(r["classes"].items())))
    out.append("  frame built %(size)#x %(saved)s" % r["frame"]["built"] + " | rom %(size)#x %(saved)s" % r["frame"]["rom"])
    out.append("  blocks built %(built)d rom %(rom)d" % r["blocks"])
    if r["renames"]:
        out.append("  reg map (built->rom): " + " ".join("%s->%s" % kv for kv in sorted(r["renames"].items())))
    if r["reg_conflicts"]:
        out.append("  reg conflicts: " + " ".join(r["reg_conflicts"]))
    for e in r["events"][:limit]:
        out.append("  %-10s %-38s | %s" % (e["cls"], e["built"], e["rom"]))
    if len(r["events"]) > limit:
        out.append("  ... %d more" % (len(r["events"]) - limit))
    return "\n".join(out)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("src")
    parser.add_argument("vram", type=lambda value: int(value, 16))
    parser.add_argument("func")
    parser.add_argument("--pipeline", choices=("production", "raw-kmc", "asn64"),
                        default="production")
    parser.add_argument("--json")
    parser.add_argument("--built-instructions",
                        help="write portable decompkit instruction JSON for the candidate")
    parser.add_argument("--reference-instructions",
                        help="write portable decompkit instruction JSON for the retail function")
    parser.add_argument("--quiet", action="store_true")
    parser.add_argument("--all", action="store_true")
    args = parser.parse_args()
    b = kmclib.build(args.src, args.vram, focus=args.func, pipeline=args.pipeline)
    r = classify(b, args.func)
    if args.built_instructions or args.reference_instructions:
        built_bytes, retail_bytes, retail_addr, retail_size, built_addr = kmclib.func_words(
            b, args.func
        )
        streams = (
            (args.built_instructions, kmclib.disasm(built_bytes, built_addr)),
            (args.reference_instructions, kmclib.disasm(retail_bytes, retail_addr)),
        )
        for destination, instructions in streams:
            if destination:
                rows = [
                    {
                        "address": f"0x{instruction[0]:08X}",
                        "opcode": instruction[2],
                        "operands": instruction[3],
                    }
                    for instruction in instructions
                ]
                with open(destination, "w") as output:
                    json.dump(rows, output, indent=2)
                    output.write("\n")
    if args.json:
        with open(args.json, "w") as output:
            json.dump(r, output, indent=1)
    if not args.quiet:
        print(summary(r, 400 if args.all else 40))
