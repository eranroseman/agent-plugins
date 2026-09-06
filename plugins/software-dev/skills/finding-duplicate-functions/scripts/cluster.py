#!/usr/bin/env python3
# ABOUTME: Structural pre-filter. Groups catalog functions by normalized AST
# shape so different-named functions with equivalent bodies surface together.
# It feeds the semantic pass; it does not replace it. Two functions sharing an
# intent but not an implementation are invisible here by construction.

import argparse
import ast
import json
import sys
from collections import defaultdict
from pathlib import Path


class Normalize(ast.NodeTransformer):
    """Mask identifier *choices*; keep structure and attribute names.

    Argument and local names become positional aliases, so two functions
    differing only in naming collapse to one shape. Attribute names are
    deliberately left alone -- `.hexdigest()` and `.as_posix()` are the
    evidence that two bodies do the same thing. Do not "fix" that.
    """

    def __init__(self):
        self.names = {}

    def _alias(self, name):
        return self.names.setdefault(name, f"v{len(self.names)}")

    def visit_FunctionDef(self, node):
        node.name = "F"
        self.generic_visit(node)
        return node

    visit_AsyncFunctionDef = visit_FunctionDef

    def visit_arg(self, node):
        node.arg = self._alias(node.arg)
        node.annotation = None
        return node

    def visit_Name(self, node):
        node.id = self._alias(node.id)
        return node


def shape(context):
    try:
        tree = ast.parse(context)
    except SyntaxError:
        return None
    fn = tree.body[0] if tree.body else None
    if not isinstance(fn, (ast.FunctionDef, ast.AsyncFunctionDef)):
        return None
    fn = Normalize().visit(fn)
    return ast.dump(fn, annotate_fields=False)


def main():
    parser = argparse.ArgumentParser(description="Group catalog entries by normalized AST shape.")
    parser.add_argument("catalog", type=Path, help="catalog.json from extract-functions.py")
    parser.add_argument("-o", "--output", type=Path, help="write groups as JSON")
    parser.add_argument(
        "-m",
        "--max-lines",
        type=int,
        default=12,
        help="skip functions longer than this; long bodies rarely duplicate verbatim",
    )
    args = parser.parse_args()

    entries = json.loads(args.catalog.read_text())
    max_lines = args.max_lines

    groups = defaultdict(list)
    for e in entries:
        if e["exportType"] == "method" or e["body_lines"] > max_lines:
            continue
        s = shape(e["context"])
        if s:
            groups[s].append(e)

    out = []
    for members in groups.values():
        if len(members) < 2:
            continue
        names = {m["name"] for m in members}
        files = {m["file"] for m in members}
        if len(files) < 2:
            continue  # same file: overloads and local helpers, not cross-file drift
        out.append(
            {
                "distinct_names": sorted(names),
                "cross_name": len(names) > 1,
                "count": len(members),
                "members": [f"{m['file']}:{m['line']} {m['name']}" for m in members],
                "sample": members[0]["context"],
            }
        )

    out.sort(key=lambda g: (not g["cross_name"], -g["count"]))
    if args.output:
        args.output.write_text(json.dumps(out, indent=1) + "\n")

    cross = [g for g in out if g["cross_name"]]
    print(f"cross-file groups: {len(out)}   of which different-name: {len(cross)}", file=sys.stderr)
    for g in cross:
        print(f"\n{g['distinct_names']}")
        for m in g["members"]:
            print(f"   {m}")


if __name__ == "__main__":
    main()
