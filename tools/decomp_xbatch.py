#!/usr/bin/env python3
"""Evaluate an explicit matrix of source hypotheses with the repository gate.

The JSON manifest names a base source, target function/address, pipelines, and
variants containing exact text replacements. Generated sources and structured
results stay under build/decomp_search; production sources are never changed.
"""
import argparse
import concurrent.futures
import hashlib
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import decomp_context  # noqa: E402

FORBIDDEN = re.compile(r"\b(register|volatile|__asm__|asm)\b")


def digest(data):
    return hashlib.sha256(data).hexdigest()


def apply_variant(base, variant):
    source = base
    for edit in variant.get("edits", []):
        old, new = edit[:2]
        count = source.count(old)
        replace_all = len(edit) > 2 and edit[2] == "all"
        if count == 0 or (count != 1 and not replace_all):
            raise ValueError("edit applies %d times: %r" % (count, old[:60]))
        source = source.replace(old, new, -1 if replace_all else 1)
    for pattern, replacement in variant.get("regex", []):
        source, count = re.subn(pattern, replacement, source)
        if count == 0:
            raise ValueError("regex did not match: %r" % pattern[:60])
    body = re.sub(r"/\*.*?\*/", "", source, flags=re.S)
    match = FORBIDDEN.search(body)
    if match:
        raise ValueError("forbidden construct: " + match.group(0))
    return source


def evaluate(job):
    manifest, variant, source_path, pipeline, outdir = job
    name = variant["name"]
    record = {"variant": name, "pipeline": pipeline}
    try:
        result = decomp_context.evaluate(
            source_path, manifest["function"], int(manifest["vram"], 16),
            int(manifest.get("unit_vram", manifest["vram"]), 16), pipeline,
            artifact_dir=os.path.join(outdir, name + "." + pipeline + ".artifacts"))
        record.update({
            "status": result["status"],
            "exact": result["exact"],
            "aligned": result["comparison"]["aligned_diffs"],
            "positional": result["comparison"]["words"],
            "size": result["actual"]["size"],
            "diagnosis": result["diagnosis"],
            "text_sha256": result["actual"]["sha256"],
            "context_id": result["context"]["context_id"],
        })
        with open(os.path.join(outdir, name + "." + pipeline + ".json"), "w") as fh:
            json.dump(result, fh, indent=2, sort_keys=True)
    except Exception as exc:
        record.update(status="ERROR", error=str(exc))
    return record


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("manifest")
    parser.add_argument("--jobs", type=int, default=8)
    parser.add_argument("--output")
    args = parser.parse_args()
    with open(args.manifest) as fh:
        manifest = json.load(fh)
    base_path = manifest["base"]
    if not os.path.isabs(base_path):
        base_path = os.path.join(ROOT, base_path)
    with open(base_path) as fh:
        base = fh.read()
    name = os.path.splitext(os.path.basename(args.manifest))[0]
    outdir = args.output or os.path.join(ROOT, "build", "decomp_search", "xbatch", name)
    os.makedirs(outdir, exist_ok=True)

    variants = [{"name": "base", "edits": []}] + manifest.get("variants", [])
    valid = []
    records = []
    for variant in variants:
        try:
            source = apply_variant(base, variant)
            path = os.path.join(outdir, variant["name"] + ".c")
            with open(path, "w") as fh:
                fh.write(source)
            valid.append((variant, path))
        except Exception as exc:
            records.append({"variant": variant["name"], "status": "REJECTED", "error": str(exc)})

    jobs = [(manifest, variant, path, pipeline, outdir)
            for variant, path in valid
            for pipeline in manifest.get("pipelines", ["production"])]
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.jobs) as pool:
        records.extend(pool.map(evaluate, jobs))

    seen = {}
    for record in records:
        key = (record.get("pipeline"), record.get("text_sha256"))
        if key[1]:
            record["duplicate_of"] = seen.get(key)
            seen.setdefault(key, record["variant"])
    records.sort(key=lambda r: (not r.get("exact", False),
                                r.get("aligned", 1 << 30), r.get("variant", "")))
    with open(os.path.join(outdir, "results.json"), "w") as fh:
        json.dump({"manifest_sha256": digest(json.dumps(manifest, sort_keys=True).encode()),
                   "base_sha256": digest(base.encode()), "results": records}, fh,
                  indent=2, sort_keys=True)
    for record in records:
        print("%-30s %-10s %-8s aligned=%-5s pos=%-5s size=%s%s" % (
            record.get("variant", "-"), record.get("pipeline", "-"),
            record["status"], record.get("aligned", "-"),
            record.get("positional", "-"), record.get("size", "-"),
            (" dup:" + record["duplicate_of"]) if record.get("duplicate_of") else ""))
    if any(record.get("exact") for record in records):
        return
    raise SystemExit(1)


if __name__ == "__main__":
    main()
