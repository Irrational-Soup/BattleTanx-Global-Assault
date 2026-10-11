#!/usr/bin/env python3
"""Extract one splat function and make its local labels acceptable to Asmlift."""
import argparse
import re


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("asm")
    parser.add_argument("function")
    parser.add_argument("output")
    args = parser.parse_args()

    text = open(args.asm).read()
    match = re.search(
        r"(?ms)^glabel " + re.escape(args.function) + r"\n(.*?)^endlabel "
        + re.escape(args.function) + r"\s*$", text)
    if not match:
        raise SystemExit("function span not found")
    body = "glabel %s\n%s" % (args.function, match.group(1))

    # splat's `alabel NAME` is an address label, but Asmlift expects ordinary
    # assembler labels. Rename references too, so jumps retain their targets.
    labels = re.findall(r"(?m)^\s*alabel\s+(\w+)\s*$", body)
    for label in labels:
        local = ".Llift_" + label
        body = re.sub(r"\b" + re.escape(label) + r"\b", local, body)
    body = re.sub(r"(?m)^\s*alabel\s+", "", body)
    body = re.sub(r"(?m)^(\.Llift_\w+)\s*$", r"\1:", body)

    with open(args.output, "w") as out:
        out.write(body)


if __name__ == "__main__":
    main()
