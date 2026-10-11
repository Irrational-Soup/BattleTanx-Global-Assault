#!/usr/bin/env python3
"""Deterministic batched beam search for matching-decomp candidates.

Each round expands every surviving source with every enabled mutation family,
compiles the entire generation concurrently, deduplicates identical machine
output, and keeps the best diverse outputs for the next round.
"""
import argparse
import concurrent.futures
import copy
import csv
import hashlib
import json
import math
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import decomp_permuter as perm  # noqa: E402


def source_hash(text):
    return hashlib.sha1(text.encode()).hexdigest()


def bounded_samples(requested, max_evals, parent_count, kind_count):
    """Cap mutations per family before expensive AST copies are created."""
    if not max_evals or not parent_count or not kind_count:
        return requested
    return min(requested, max(1, math.ceil(max_evals / (parent_count * kind_count))))


def update_family_stat(stats, kind, baseline, result):
    row = stats.setdefault(kind, {
        "generated": 0, "build_errors": 0, "compiled": 0,
        "distinct_outputs": set(), "best": None, "improvements": 0,
    })
    row["generated"] += 1
    if not result.get("ok"):
        row["build_errors"] += 1
        return
    row["compiled"] += 1
    row["distinct_outputs"].add(result["hash"])
    value = perm.score(result)
    if row["best"] is None or value < row["best"]:
        row["best"] = value
    if value < baseline:
        row["improvements"] += 1


def render(ast, markers, generator):
    text = markers + perm.restore_typeof(generator.visit(ast))
    if perm.FORBID.search(text.replace("__typeof__", "")):
        return None
    return text


def expand(parent, function, kinds, samples, seed, markers, generator):
    """Return stable, distinct one-mutation children of one parent."""
    children = []
    seen = set()
    for kind_index, kind in enumerate(kinds):
        for sample in range(samples):
            ast = copy.deepcopy(parent)
            fn = perm.find_func(ast, function)
            rng = random.Random(seed + kind_index * 1000003 + sample * 9176)
            try:
                changed = perm.MUTATIONS[kind](fn, rng)
            except Exception:
                changed = False
            if not changed:
                continue
            text = render(ast, markers, generator)
            if text is None:
                continue
            digest = source_hash(text)
            if digest in seen:
                continue
            seen.add(digest)
            children.append((ast, text, kind, sample, digest))
    return children


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src"); ap.add_argument("func"); ap.add_argument("vram")
    ap.add_argument("--unit-vram"); ap.add_argument("--name")
    ap.add_argument("--pipeline", choices=("production", "raw-kmc", "asn64"),
                    default="production")
    ap.add_argument("--rounds", type=int, default=4)
    ap.add_argument("--beam", type=int, default=12)
    ap.add_argument("--samples", type=int, default=32)
    ap.add_argument("--max-evals", type=int, default=2000,
                    help="maximum distinct sources compiled per generation (0 disables)")
    ap.add_argument("--plateau-rounds", type=int, default=2,
                    help="stop after this many consecutive rounds without a better score (0 disables)")
    ap.add_argument("--jobs", type=int, default=16)
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--only"); ap.add_argument("--focus")
    ap.add_argument(
        "--allow-type-mutations", action="store_true",
        help=("include int_type and param_type mutations; these can change "
              "program semantics and require explicit review"),
    )
    ap.add_argument("--focus-max", type=int, default=2500)
    ap.add_argument("--stop-at-zero", action="store_true")
    ap.add_argument("--save-survivors", action="store_true",
                    help="retain each distinct compiled output for diagnosis")
    args = ap.parse_args()

    vram = int(args.vram, 16)
    unit_vram = int(args.unit_vram, 16) if args.unit_vram else vram
    name = args.name or "%s_beam" % args.func
    outdir = os.path.join(ROOT, "build", "decomp_search", name)
    os.makedirs(outdir, exist_ok=True)
    perm.FOCUS[0] = args.focus; perm.FOCUS_MAX[0] = args.focus_max
    markers = perm.markers(args.src)
    base = perm.parse(perm.preprocess(args.src))
    generator = perm.c_generator.CGenerator()
    kinds = list(perm.MUTATIONS)
    if not args.allow_type_mutations:
        kinds = [kind for kind in kinds if kind not in {"int_type", "param_type"}]
    if args.only:
        requested = [x for x in args.only.split(",") if x]
        unknown = set(requested) - set(kinds)
        if unknown:
            ap.error("unknown mutation family: " + ", ".join(sorted(unknown)))
        kinds = requested

    base_text = render(base, markers, generator)
    base_result = perm.evaluate((args.src, base_text, vram, args.func, args.pipeline))
    if not base_result.get("ok"):
        raise SystemExit("baseline does not build: " + base_result.get("err", "unknown"))
    beam = [(perm.score(base_result), base, base_text, base_result["hash"],
             "baseline", ())]
    best = beam[0]
    seen_sources = {source_hash(base_text)}
    seen_outputs = {base_result["hash"]: perm.score(base_result)}
    ledger_path = os.path.join(outdir, "ledger.tsv")
    errors_path = os.path.join(outdir, "errors.tsv")
    fields = ("round", "parent", "mutation", "sample", "words", "size_delta",
              "source_hash", "output_hash", "accepted")
    plateau = 0
    family_stats = {}
    with open(ledger_path, "w", newline="") as ledger, \
            open(errors_path, "w", newline="") as errors:
        writer = csv.DictWriter(ledger, fields, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        error_writer = csv.DictWriter(
            errors, ("round", "parent", "mutation", "sample", "source_hash", "error"),
            delimiter="\t", lineterminator="\n")
        error_writer.writeheader()
        ledger.flush(); errors.flush()
        for round_no in range(1, args.rounds + 1):
            score_before = best[0]
            candidates = []
            # Respect the compile budget while generating mutations.  The old
            # implementation deep-copied every AST for beam*kinds*samples and
            # discarded the excess afterward; on a large TU that spent minutes
            # producing candidates which could never be compiled.
            effective_samples = bounded_samples(
                args.samples, args.max_evals, len(beam), len(kinds))
            for parent_index, (_, ast, _, _, _, _) in enumerate(beam):
                edges = expand(ast, args.func, kinds, effective_samples,
                    args.seed + round_no * 10000019 + parent_index * 20000003,
                    markers, generator)
                for child_ast, text, kind, sample, digest in edges:
                    if digest in seen_sources:
                        continue
                    seen_sources.add(digest)
                    candidates.append((parent_index, child_ast, text, kind, sample, digest))
            generated = len(candidates)
            if args.max_evals and len(candidates) > args.max_evals:
                # Avoid bias toward the first parent or mutation family while
                # keeping identical campaigns reproducible.
                chooser = random.Random(args.seed + round_no * 30000011)
                chooser.shuffle(candidates)
                candidates = candidates[:args.max_evals]
            jobs = [(args.src, row[2], vram, args.func, args.pipeline) for row in candidates]
            survivors = list(beam)
            compiled = 0
            with concurrent.futures.ProcessPoolExecutor(args.jobs) as pool:
                for row, result in zip(candidates, pool.map(perm.evaluate, jobs)):
                    parent_index, ast, text, kind, sample, digest = row
                    update_family_stat(family_stats, kind, score_before, result)
                    if not result.get("ok"):
                        error_writer.writerow({"round": round_no, "parent": parent_index,
                            "mutation": kind, "sample": sample,
                            "source_hash": digest[:16],
                            "error": result.get("err", "unknown")})
                        continue
                    compiled += 1
                    value = perm.score(result)
                    duplicate = result["hash"] in seen_outputs
                    if not duplicate:
                        seen_outputs[result["hash"]] = value
                        provenance = "r%d:p%d:%s:%d" % (round_no, parent_index, kind, sample)
                        history = beam[parent_index][5] + (kind,)
                        survivors.append((value, ast, text, result["hash"], provenance,
                                          history))
                        if args.save_survivors:
                            frontier = os.path.join(outdir, "survivors")
                            os.makedirs(frontier, exist_ok=True)
                            filename = "r%d_%s_%s.c" % (
                                round_no, result["words"], result["hash"][:12])
                            with open(os.path.join(frontier, filename), "w") as fh:
                                fh.write(text)
                        if value < best[0]:
                            best = survivors[-1]
                            open(os.path.join(outdir, "best.c"), "w").write(text)
                            print("round %d best %s via %s" % (round_no, value, provenance), flush=True)
                    writer.writerow({"round": round_no, "parent": parent_index,
                        "mutation": kind, "sample": sample, "words": result["words"],
                        "size_delta": result["size"] - result["rom"],
                        "source_hash": digest[:16], "output_hash": result["hash"],
                        "accepted": int(not duplicate)})
            # Make a running campaign auditable instead of keeping its evidence
            # buffered until the process exits.
            ledger.flush(); errors.flush()
            survivors.sort(key=lambda x: (x[0], x[4]))
            beam = []
            output_hashes = set()
            for item in survivors:
                if item[3] in output_hashes:
                    continue
                output_hashes.add(item[3]); beam.append(item)
                if len(beam) == args.beam:
                    break
            print("round %d: generated=%d sampled=%d compiled=%d outputs=%d beam_best=%s samples_per_family=%d" %
                  (round_no, generated, len(candidates), compiled,
                   len(seen_outputs), beam[0][0], effective_samples), flush=True)
            if best[0] == (0, 0):
                exact_path = os.path.join(outdir, "exact.c")
                open(exact_path, "w").write(best[2])
                ok, report = perm.unit_gate(exact_path, unit_vram, args.pipeline)
                print("zero-word candidate: %s (%s)" %
                      ("UNIT MATCH" if ok else "unit DIFF", report), flush=True)
                if ok and args.stop_at_zero:
                    break
            if best[0] < score_before:
                plateau = 0
            else:
                plateau += 1
            if args.plateau_rounds and plateau >= args.plateau_rounds:
                print("stopping after %d plateau rounds" % plateau, flush=True)
                break
    if not os.path.isfile(os.path.join(outdir, "best.c")):
        open(os.path.join(outdir, "best.c"), "w").write(best[2])
    review_families = {"temp", "int_type", "param_type", "alias_uses", "commute"}
    with open(os.path.join(outdir, "candidate.json"), "w") as fh:
        json.dump({"function": args.func, "score": best[0][0],
                   "size_delta": best[0][1], "pipeline": args.pipeline,
                   "mutation_history": list(best[5]),
                   "semantic_review_required": bool(review_families & set(best[5]))},
                  fh, indent=2, sort_keys=True)
    with open(os.path.join(outdir, "summary.tsv"), "w") as fh:
        fh.write("\t".join([args.func, os.path.join(outdir, "best.c"), args.pipeline,
            "-", str(best[0][0]), "MATCH" if best[0] == (0, 0) else "DIFF", "-",
            "beam rounds=%d width=%d samples=%d max_evals=%d outputs=%d" %
            (args.rounds, args.beam, args.samples, args.max_evals,
             len(seen_outputs))]) + "\n")
    with open(os.path.join(outdir, "family_results.tsv"), "w", newline="") as fh:
        fields = ("mutation", "generated", "compiled", "build_errors",
                  "distinct_outputs", "best_words", "best_size_delta",
                  "improvements")
        writer = csv.DictWriter(fh, fields, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        for kind in sorted(family_stats):
            row = family_stats[kind]
            best_score = row["best"]
            writer.writerow({"mutation": kind, "generated": row["generated"],
                "compiled": row["compiled"], "build_errors": row["build_errors"],
                "distinct_outputs": len(row["distinct_outputs"]),
                "best_words": "" if best_score is None else best_score[0],
                "best_size_delta": "" if best_score is None else best_score[1],
                "improvements": row["improvements"]})
    print("done: best=%s distinct_sources=%d distinct_outputs=%d" %
          (best[0], len(seen_sources), len(seen_outputs)))


if __name__ == "__main__":
    main()
