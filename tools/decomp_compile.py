#!/usr/bin/env python3
"""Shared KMC GCC 2.7.2 build/disassembly library for the matching tools.

build(src, vram, ...) compiles a candidate with the production gameplay pipeline
(kmc gcc -S -O2 -G0 -mips3 -mgp32 -mfp32 -> tools/normalize_kmc_gcc_asm.py ->
kmc as -> trim .text -> mips ld at the real VRAM with build/us/symbols.ld) in its
own work directory, so parallel builds never share files and GCC's -da dumps
(written to the cwd) stay inside the output tree. Every relocation is resolved by
the linker; nothing is masked. Markers in the source are the same as kmc_cmp.py
(SPAN, RODATA_VRAM, DATA_VRAM, LDSYM, CFLAGS, MODE).

kmc_cmp.py remains the reporting gate; this library exists so classifiers,
stage collectors and searches share one implementation.
"""
import hashlib, os, re, shutil, struct, subprocess, tempfile, tomllib

R = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A = os.path.join(R, "build", "decomp_search")
B = R + "/.toolchain/mips-binutils/usr/bin/mips-linux-gnu-"
KMC = R + "/.toolchain/kmc-gcc-2.7.2/"
ENV = dict(os.environ, LD_LIBRARY_PATH=R + "/.toolchain/mips-binutils/usr/lib/x86_64-linux-gnu")
ROM_PATH = R + "/baseroms/us/baserom.z64"
ROM_BASE = 0x80070000  # code segment: ROM offset == VRAM - 0x80070000 (as used by kmc_cmp.py)
_rom = None


def rom():
    global _rom
    if _rom is None:
        with open(ROM_PATH, "rb") as fh:
            _rom = fh.read()
    return _rom


def rom_bytes(addr, n):
    return rom()[addr - ROM_BASE: addr - ROM_BASE + n]


def catalogue():
    """Return the authoritative production name -> (address, size) catalogue."""
    with open(R + "/config/us/recomp_function_boundaries.toml", "rb") as fh:
        document = tomllib.load(fh)
    result = {}
    for section in document.get("section", []):
        for function in section.get("functions", []):
            result[function["name"]] = (function["vram"], function["size"])
    return result


def markers(text):
    def mk(k):
        m = re.search(r"(?<![A-Z_])%s (\S.*?)\s*(\*/|$)" % k, text, re.M)
        return m.group(1) if m else None
    return dict(cflags=(mk("CFLAGS") or "-O2 -G0 -mips3 -mgp32 -mfp32").split(),
                mode=mk("MODE") or "norm", span=mk("SPAN"), rodata=mk("RODATA_VRAM"),
                data=mk("DATA_VRAM"), ldsyms=re.findall(r"LDSYM (\w+)=(0x[0-9A-Fa-f]+)", text))


def parse_span(value):
    """Accept either a legacy byte count or the canonical START..END marker."""
    if not value:
        return None
    match = re.fullmatch(r"(0x[0-9A-Fa-f]+)\.\.(0x[0-9A-Fa-f]+)", value)
    if match:
        start, end = (int(item, 16) for item in match.groups())
        if end < start:
            raise ValueError("SPAN end precedes start: %s" % value)
        return end - start
    return int(value, 16)


class BuildError(Exception):
    pass


def _run(cmd, cwd, log):
    log.append("$ (cd %s) %s" % (cwd, " ".join(cmd)))
    p = subprocess.run(cmd, cwd=cwd, env=ENV, capture_output=True, text=True)
    if p.returncode:
        raise BuildError("\n".join(log[-1:]) + "\n" + p.stdout + p.stderr)
    return p.stdout


def sections(path, log):
    d = {}
    for l in _run([B + "readelf", "-SW", path], R, log).splitlines():
        m = re.match(r"\s*\[\s*\d+\]\s+(\S+)\s+\S+\s+([0-9a-f]+)\s+([0-9a-f]+)\s+([0-9a-f]+)", l)
        if m:
            d[m[1]] = (int(m[2], 16), int(m[3], 16), int(m[4], 16))
    return d


def build(src, vram, focus=None, workdir=None, dumps=False, text=None, keep=False,
          pipeline="production"):
    """Compile+link one candidate. Returns a dict (see keys below).

    src     path of the candidate (used for markers, -I and naming)
    text    optional source text overriding the file content (variants)
    vram    unit start address (int)
    focus   function name: relink so it lands at its catalogue address
    workdir directory to use (created); default a fresh temp dir under build/
    dumps   add -da and collect RTL dumps (dict stage -> text)
    """
    src = os.path.abspath(src)
    if text is not None:
        S = text
    else:
        with open(src) as fh:
            S = fh.read()
    M = markers(S)
    own = workdir is None
    os.makedirs(A, exist_ok=True)
    t = workdir or tempfile.mkdtemp(dir=A, prefix="candidate_")
    os.makedirs(t, exist_ok=True)
    log = []
    try:
        with open(t + "/u.c", "w") as fh:
            fh.write(S)
        cf = M["cflags"] + (["-da"] if dumps else [])
        _run([KMC + "gcc", "-B" + KMC, "-S"] + cf + ["-I" + R + "/include", "-I" + os.path.dirname(src),
              "-I" + os.path.dirname(src), "-o", "r.s", "u.c"], t, log)
        if pipeline == "production" and M["mode"] == "norm":
            _run(["python3", R + "/tools/normalize_kmc_gcc_asm.py",
                  t + "/r.s", t + "/n.s"], R, log)
        else:
            shutil.copy(t + "/r.s", t + "/n.s")
        if pipeline == "asn64":
            _run(["python3", R + "/tools/modern_asn64.py", B + "as",
                  "-march=vr4300", "-mabi=32", "-EB", "-G0",
                  "--no-pad-sections", "n.s", "-o", "o.o"], t, log)
            _run([B + "objcopy", "--rename-section",
                  ".rdata=.rodata,alloc,load,readonly,data,contents", "o.o"], t, log)
        elif pipeline in ("production", "raw-kmc"):
            _run([KMC + "as", "-mips3", "-G0", "-o", "o.o", "n.s"], t, log)
        else:
            raise BuildError("unknown pipeline: %s" % pipeline)
        so = sections(t + "/o.o", log)
        tsz = so[".text"][2]
        fsyms = {}
        for f in (l.split() for l in _run([B + "readelf", "-sW", t + "/o.o"], R, log).splitlines()):
            if len(f) >= 8 and f[3] == "FUNC":
                fsyms[f[7]] = (int(f[1], 16), int(f[2], 0))
        if fsyms:
            tsz = max(a + s for a, s in fsyms.values())
        _run(["python3", R + "/tools/trim_elf32_section.py", t + "/o.o", ".text", hex(tsz), "--alignment", "4"], R, log)
        if so.get(".rodata", (0, 0, 0))[2] and re.search(r"\]\s+\.rodata\s+PROGBITS\s+\S+\s+\S+\s+\S+\s+\S+\s+W\s", _run([B + "readelf", "-SW", t + "/o.o"], R, log)):
            _run([B + "objcopy", "--set-section-flags", ".rodata=alloc,load,readonly,data", t + "/o.o"], R, log)
        cat = catalogue()
        span = M["span"]
        link_vram = vram
        if focus:
            if focus not in fsyms or focus not in cat:
                raise BuildError("focus %s not emitted or not in catalogue" % focus)
            link_vram = cat[focus][0] - fsyms[focus][0]
        ldx = []
        if M["rodata"]:
            ldx.append("--section-start=.rodata=" + M["rodata"])
        if M["data"]:
            ldx.append("--section-start=.data=" + M["data"])
        ldx += ["--defsym=%s=%s" % x for x in M["ldsyms"]]
        ld = [B + "ld", "-EB", "--no-check-sections"] + ldx + ["-Ttext=0x%X" % link_vram, "-T",
              R + "/build/us/symbols.ld", "-o", t + "/l.elf", t + "/o.o", "--noinhibit-exec", "-e", "0"]
        p = subprocess.run(ld, cwd=R, env=ENV, capture_output=True, text=True)
        undef = sorted(set(re.findall(r"undefined reference to `([^']+)'", p.stderr)))
        if undef:
            raise BuildError("UNDEFINED SYMBOLS (add LDSYM name=addr): " + " ".join(undef))
        _run(ld, R, log)
        _run([B + "objcopy", "-O", "binary", "-j", ".text", t + "/l.elf", t + "/t.bin"], R, log)
        with open(t + "/t.bin", "rb") as fh:
            tb = fh.read()[:tsz]
        ro = None
        if ".rodata" in so and so[".rodata"][2]:
            _run([B + "objcopy", "-O", "binary", "-j", ".rodata", t + "/l.elf", t + "/ro.bin"], R, log)
            with open(t + "/ro.bin", "rb") as fh:
                ro = fh.read()[:so[".rodata"][2]]
        syms = {}
        for l in _run([B + "nm", "-n", t + "/l.elf"], R, log).splitlines():
            f = l.split()
            if len(f) == 3:
                syms.setdefault(f[2], int(f[0], 16))
        funcs = {n: (link_vram + a, s) for n, (a, s) in fsyms.items()}
        with open(t + "/r.s") as fh:
            raw_s = fh.read()
        with open(t + "/n.s") as fh:
            norm_s = fh.read()
        res = dict(src=src, vram=vram, link_vram=link_vram, focus=focus, span=parse_span(span),
                   text=tb, tsz=tsz, rodata=ro, rodata_vram=int(M["rodata"], 16) if M["rodata"] else None,
                   funcs=funcs, syms=syms, raw_s=raw_s, norm_s=norm_s,
                   relocs=_run([B + "readelf", "-rW", t + "/o.o"], R, log), log=log, workdir=t)
        if dumps:
            res["dumps"] = {}
            for fn in sorted(os.listdir(t)):
                if fn.startswith("u.c."):
                    with open(t + "/" + fn) as fh:
                        res["dumps"][fn[4:]] = fh.read()
        res["pipeline"] = pipeline
        res["hash"] = hashlib.sha1((res["norm_s"] + "|%s|%x|%s|%s" %
                                   (pipeline, link_vram, M["rodata"], M["ldsyms"])).encode()
                                   + tb + (ro or b"")).hexdigest()[:16]
        return res
    finally:
        if own and not keep:
            shutil.rmtree(t, ignore_errors=True)


# ---------------------------------------------------------------- disassembly
_DIS_RE = re.compile(r"^\s*([0-9a-f]+):\s+([0-9a-f]{8})\s+(\S+)\s*(.*)$")


def disasm(data, addr):
    """[(addr, word, mnemonic, [operands])] for big-endian MIPS words."""
    os.makedirs(A, exist_ok=True)
    fd, path = tempfile.mkstemp(dir=A, suffix=".bin")
    try:
        os.write(fd, data)
        os.close(fd)
        out = subprocess.run([B + "objdump", "-D", "-b", "binary", "-m", "mips:4300", "-EB",
                              "--adjust-vma=0x%x" % addr, path], env=ENV, capture_output=True, text=True).stdout
    finally:
        os.unlink(path)
    res = []
    for l in out.splitlines():
        m = _DIS_RE.match(l)
        if m:
            ops = [o.strip() for o in m.group(4).split("#")[0].split(",")] if m.group(4).strip() else []
            res.append((int(m.group(1), 16), int(m.group(2), 16), m.group(3), ops))
    return res


def func_words(b, name):
    """(built bytes, rom bytes, rom addr, rom size) for one function in a FOCUS build."""
    cat = catalogue()
    a, n = b["funcs"][name]
    ra, rn = cat[name]
    off = a - b["link_vram"]
    return b["text"][off:off + n], rom_bytes(ra, rn), ra, rn, a
