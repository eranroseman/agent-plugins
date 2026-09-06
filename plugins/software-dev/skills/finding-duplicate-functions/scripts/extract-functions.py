#!/usr/bin/env python3
# ABOUTME: Extracts function/method definitions from a Python codebase.
# Emits the same catalog schema as the skill's TypeScript extractor, so phases
# 2-5 (categorize, split, detect, report) consume it unchanged.

from __future__ import annotations

import argparse
import ast
import json
import sys
from pathlib import Path

TEST_MARKERS = ("test_", "_test", "conftest")


def is_test(path: Path) -> bool:
    if any(part in {"tests", "test", "__tests__"} for part in path.parts):
        return True
    return any(m in path.name for m in TEST_MARKERS)


def export_type(node: ast.AST, is_method: bool) -> str:
    """Python has no export keyword; the underscore convention is the analogue."""
    if is_method:
        return "method"
    return "internal" if node.name.startswith("_") else "named"


def context_of(node: ast.AST, source: str, limit: int) -> str:
    segment = ast.get_source_segment(source, node) or ""
    lines = segment.splitlines()
    return "\n".join(lines[:limit])


def extract_file(path: Path, root: Path, limit: int) -> list[dict]:
    try:
        source = path.read_text(encoding="utf-8")
        tree = ast.parse(source)
    except (SyntaxError, UnicodeDecodeError) as exc:
        print(f"skipped {path}: {type(exc).__name__}", file=sys.stderr)
        return []

    methods = {
        child
        for node in ast.walk(tree)
        if isinstance(node, ast.ClassDef)
        for child in node.body
        if isinstance(child, (ast.FunctionDef, ast.AsyncFunctionDef))
    }

    entries = []
    for node in ast.walk(tree):
        if not isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            continue
        entries.append(
            {
                "file": str(path.resolve().relative_to(root.resolve())),
                "name": node.name,
                "line": node.lineno,
                "exportType": export_type(node, node in methods),
                "context": context_of(node, source, limit),
                "body_lines": (node.end_lineno or node.lineno) - node.lineno + 1,
                "args": [a.arg for a in node.args.args],
            }
        )
    return entries


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("-o", "--output", type=Path)
    parser.add_argument("-c", "--context", type=int, default=15)
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--include-tests", action="store_true")
    args = parser.parse_args()

    entries: list[dict] = []
    for path in sorted(args.source.rglob("*.py")):
        if not args.include_tests and is_test(path):
            continue
        entries.extend(extract_file(path, args.root, args.context))

    entries.sort(key=lambda e: (e["file"], e["line"]))
    text = json.dumps(entries, indent=1)
    if args.output:
        args.output.write_text(text + "\n")
        print(f"Extracted {len(entries)} function definitions to {args.output}", file=sys.stderr)
    else:
        print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
