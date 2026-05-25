# Data Layout

Tracked data are intentionally small.

## Tracked

- `metadata/`: curated manifests and validation data manifests
- `demo/`: tiny GSE136103-derived demo dataset for pipeline testing

## Not Tracked

- `raw/`: GEO archives
- `processed/`: large Seurat objects and extracted matrices
- `validation/`: large external validation matrices

Large data should live in object storage for production use. The AWS convention is documented in `docs/aws_production_notes.md`.
