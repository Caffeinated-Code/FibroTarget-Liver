# Architecture

FibroTarget-Liver is organized to keep analysis code, pipeline orchestration, exploratory assets, and review artifacts separate.

## Layer 1: Analysis Code

Core logic lives outside notebooks:

- `workflow/`: ordered R workflow stages
- `src/R/`: shared R utilities
- `scripts/`: supporting Python and R utilities

The workflow stages are intentionally short and parameterized through `config/project.yaml`.

## Layer 2: Reproducible Execution

Local execution:

- `Makefile`
- `renv.lock`
- `.Rprofile`
- `Dockerfile`

Cloud-oriented execution:

- `nextflow/main.nf`
- `nextflow/nextflow.config`
- `docs/aws_production_notes.md`

The local `make` targets map to future Nextflow/AWS Batch process boundaries.

## Layer 3: Data Products

Tracked:

- curated metadata manifests
- small demo dataset
- compact figures and tables
- validation summaries
- dashboard-ready CSVs

Not tracked:

- raw GEO archives
- extracted validation datasets
- large Seurat objects
- logs and runtime caches

## Layer 4: Review Artifacts

Reviewer-facing outputs live under:

- `reports/executive_summary/`
- `reports/screening_responses/`
- `reports/figures/`
- `reports/tables/`
- `dashboard/`
- `docs/`

This keeps publication-style artifacts separate from source code and pipeline infrastructure.

## Workflow Map

```text
GEO archives
  -> metadata curation
  -> Seurat QC and clustering
  -> marker-supported compartment calls
  -> exploratory DE and pathway analysis
  -> candidate prioritization
  -> validation summaries
  -> public target evidence
  -> dashboard and reports
```
