#!/usr/bin/env python3
"""Lightweight repository integrity checks for reviewer-facing navigation."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

REQUIRED = [
    "README.md",
    "Makefile",
    "Dockerfile",
    "renv.lock",
    "config/project.yaml",
    "docs/interviewer_guide.md",
    "docs/architecture.md",
    "docs/io_contract.md",
    "docs/reproducibility.md",
    "reports/executive_summary/README.md",
    "reports/screening_responses/README.md",
    "reports/tables/ranked_biomarker_target_candidates_enriched.csv",
    "reports/figures/required_compartment_marker_dotplot.png",
    "dashboard/app.R",
    "nextflow/main.nf",
    "nextflow/nextflow.config",
    "data/demo/gse136103_demo_10x/matrix.mtx",
]

FORBIDDEN_TRACKED_PATTERNS = [
    "karyon_ceo_convo.txt",
    "Karyon_Bio_Candidate_Assignment.pdf",
    "data/raw/",
    "data/processed/",
    "data/validation/",
    "docs/rendered/",
]


def git_ls_files() -> list[str]:
    result = subprocess.run(
        ["git", "ls-files"],
        cwd=ROOT,
        check=True,
        text=True,
        capture_output=True,
    )
    return result.stdout.splitlines()


def main() -> int:
    missing = [path for path in REQUIRED if not (ROOT / path).exists()]
    tracked = git_ls_files()
    forbidden = [
        path
        for path in tracked
        for pattern in FORBIDDEN_TRACKED_PATTERNS
        if path == pattern or path.startswith(pattern)
    ]

    if missing:
        print("Missing required files:")
        for path in missing:
            print(f"  - {path}")
    if forbidden:
        print("Forbidden tracked files:")
        for path in forbidden:
            print(f"  - {path}")

    if missing or forbidden:
        return 1

    print("repo_structure_ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
