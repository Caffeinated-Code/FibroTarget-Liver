#!/usr/bin/env python3
"""Lightweight repository integrity checks for required project files."""

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
    "docs/analysis_walkthrough.md",
    "docs/technical_appendix.md",
    "reports/executive_submission_summary.md",
    "reports/executive_submission_summary.Rmd",
    "reports/executive_submission_summary.html",
    "reports/requirement_traceability.md",
    "reports/screening_responses/README.md",
    "reports/tables/qc_decision_log.csv",
    "reports/tables/qc_filter_summary.csv",
    "reports/tables/qc_metric_summary.csv",
    "reports/tables/ranked_biomarker_target_candidates_translational.csv",
    "reports/tables/target_prioritization_scoring_components.csv",
    "reports/tables/target_prioritization_scoring_method.csv",
    "reports/tables/pseudobulk_priority_gene_de.csv",
    "reports/tables/pathfindr_pseudobulk_reactome_enrichment.csv",
    "reports/tables/pathfindr_pseudobulk_run_summary.csv",
    "reports/tables/gse244832_hsc_candidate_validation.csv",
    "reports/tables/gse244832_focused_object_candidate_summary.csv",
    "reports/tables/validation_gse207310_candidate_lm_results.csv",
    "reports/tables/gse136103_blood_candidate_marker_role_summary.csv",
    "reports/tables/gse136103_mouse_candidate_ortholog_summary.csv",
    "reports/figures/required_compartment_marker_dotplot.png",
    "reports/figures/umap_refined_cell_states.png",
    "reports/figures/gse244832_focused_object_validation_heatmap.png",
    "reports/figures/gse207310_candidate_validation_heatmap.png",
    "reports/figures/gse136103_blood_candidate_marker_heatmap.png",
    "reports/figures/gse136103_mouse_candidate_ortholog_heatmap.png",
    "reports/figures/qc_metric_distributions.png",
    "reports/figures/pathway_enrichment_barplot.png",
    "reports/figures/pathway_enrichment_dotplot.png",
    "reports/figures/pathfindr_pseudobulk_reactome_barplot.png",
    "reports/figures/pathfindr_pseudobulk_reactome_dotplot.png",
    "reports/figures/gse244832_hsc_candidate_trend.png",
    "reports/figures/gse207310_candidate_directionality_barplot.png",
    "reports/figures/gse136103_blood_candidate_detectability_barplot.png",
    "reports/figures/gse136103_mouse_ortholog_directionality_barplot.png",
    "dashboard/app.R",
    "nextflow/main.nf",
    "nextflow/nextflow.config",
    "nextflow/fibrotarget_demo/main.nf",
    "reports/nextflow_demo/demo_qc_summary.csv",
    "data/demo/gse136103_demo_10x/matrix.mtx",
]

FORBIDDEN_TRACKED_PATTERNS = [
    "ceo_conversation_private.txt",
    "assignment_prompt_private.pdf",
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
