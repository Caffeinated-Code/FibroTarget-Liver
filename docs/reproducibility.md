# Reproducibility

The repository is designed so a reviewer can inspect outputs immediately and rerun the analysis when the required public data are available.

## Environment

- R 4.6.0
- Seurat 5.5.0
- `renv.lock` for package versions
- Dockerfile for containerized execution
- Nextflow scaffold for AWS Batch migration

Restore the R environment:

```bash
Rscript -e "renv::restore()"
```

## One-Command Local Workflow

```bash
make all
```

Individual stages:

```bash
make check
make fetch-data
make curate
make analyze
make prioritize
make validation
make evidence
make dashboard
make report
```

## Demo Dataset

A small GSE136103-derived demo dataset is tracked under:

```text
data/demo/
```

Use it to test pipeline wiring and future Nextflow modules without downloading the full GEO archive.

## Validation

Run the lightweight repository validation:

```bash
make validate-repo
```

This checks that required reviewer-facing files are present and that private or large local data are not tracked by Git.

## Data Provenance

Public source data:

- GSE136103 primary discovery dataset
- GSE244832 MASH/HSC validation dataset
- GSE207310 NAFLD/NASH bulk validation dataset

Tracked manifests describe local validation data preparation:

- `data/metadata/gse244832_validation_manifest.json`
- `data/metadata/gse207310_validation_manifest.json`

## Known Reproducibility Gaps

- Nextflow was not executed locally because Java was unavailable.
- GSE207310 needs an Ensembl-to-symbol annotation module before symbol-level computed validation.
- Donor-aware pseudobulk DE should replace exploratory cell-level DE for formal inference.
