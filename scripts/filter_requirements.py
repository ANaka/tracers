#!/usr/bin/env python3
"""Utility script to filter out packages from a requirements.txt file.

This helps us reuse upstream requirement lists while handling special cases
(such as CUDA-enabled wheels) separately in the Docker image.
"""
from __future__ import annotations

import argparse
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True, help="Path to the upstream requirements file")
    parser.add_argument("--exclude", nargs="*", default=[], help="Package names (case-insensitive) to remove")
    return parser.parse_args()


def normalize(name: str) -> str:
    return name.split("[")[0].strip().lower()


def should_exclude(line: str, exclusions: set[str]) -> bool:
    line = line.strip()
    if not line or line.startswith("#"):
        return False
    pkg = normalize(line.split("==")[0].split("@")[0])
    return pkg in exclusions


def main() -> None:
    args = parse_args()
    if not args.input.is_file():
        raise FileNotFoundError(f"Could not locate requirements file: {args.input}")

    exclusions = {normalize(name) for name in args.exclude}
    content = args.input.read_text().splitlines()

    filtered_lines = [line for line in content if not should_exclude(line, exclusions)]

    for line in filtered_lines:
        print(line)


if __name__ == "__main__":
    main()
