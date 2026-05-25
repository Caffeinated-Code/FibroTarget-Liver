# Liver Disease Single-Cell Target Discovery Nextflow Pipeline

This is a production-oriented scaffold for running liver fibrosis, MASH, and cirrhosis target-discovery analyses on proprietary or public single-cell data.

The local repository workflow remains the source of truth for the compact take-home analysis. The Nextflow layer defines how the same logic can be moved toward AWS Batch, S3-backed storage, and repeatable execution across datasets.

## Use Cases

- Run a small public demo dataset from GSE136103.
- Run proprietary 10x-style liver scRNA-seq or snRNA-seq inputs.
- Compare discovered candidates against prepared validation datasets.
- Add public target evidence from Open Targets, ClinicalTrials.gov, ClinVar, UniProt, PubMed, and mouse orthology.

## Demo Run

From the repository root:

```bash
nextflow run nextflow/main.nf -profile local
```

If Nextflow is not installed:

```bash
curl -s https://get.nextflow.io | bash
```

## AWS Run Pattern

Expected AWS components:

- S3 bucket for raw, work, validation, and results
- ECR image built from the repository Dockerfile
- AWS Batch queue and job definition
- CloudWatch logs
- Optional Step Functions wrapper for scheduled or multi-study runs

Example:

```bash
export AWS_REGION=us-west-2
export AWS_BATCH_QUEUE=<queue-name>
export NXF_WORK=s3://<bucket>/liver-fibrosis-single-cell/work
export PIPELINE_IMAGE=<account>.dkr.ecr.us-west-2.amazonaws.com/liver-fibrosis-single-cell:latest

nextflow run nextflow/main.nf -profile aws \
  --input s3://<bucket>/inputs/samplesheet.csv \
  --outdir s3://<bucket>/results/run-001
```

## Input Samplesheet

The pipeline expects a CSV with one row per dataset or sample group:

```text
sample_id,condition,matrix,features,barcodes,metadata
gse136103_demo,mixed,data/demo/gse136103_demo_10x/matrix.mtx,data/demo/gse136103_demo_10x/features.tsv,data/demo/gse136103_demo_10x/barcodes.tsv,data/demo/gse136103_demo_metadata.csv
```

For proprietary data, use Matrix Market or 10x-style count outputs plus sample metadata. Future versions should add direct support for Cell Ranger `filtered_feature_bc_matrix`, H5, h5Seurat, and h5ad inputs.

## Validation Datasets

Prepared local validation data:

- `data/validation/GSE244832`: Matrix Market counts plus genes, cells, and metadata CSV. This is the priority therapeutic-target validation dataset.
- `data/validation/GSE207310`: per-sample bulk count files. This is useful for biomarker directionality after Ensembl-to-symbol annotation.

Tracked compact validation outputs:

- `reports/tables/validation_gse244832_candidate_expression_by_condition.csv`
- `reports/tables/validation_gse244832_candidate_expression_by_cluster.csv`
- `reports/tables/validation_gse244832_candidate_expression_by_sample.csv`
- `reports/tables/gse244832_hsc_like_cluster_scores.csv`
- `reports/tables/gse244832_hsc_candidate_validation.csv`
- `reports/tables/validation_gse207310_readiness.csv`

Tracked target evidence outputs:

- `reports/tables/target_public_evidence.csv`
- `reports/tables/target_translational_evidence.csv`
- `reports/tables/target_mouse_orthology.csv`
- `reports/tables/ranked_biomarker_target_candidates_translational.csv`

## Current Status

The Nextflow layer is an AWS-oriented scaffold. The next engineering step is to turn each R/Python workflow into isolated containerized processes with explicit inputs and outputs, replacing local `make` orchestration inside each process.

Local validation note: this machine does not currently have a usable Java runtime, so Nextflow itself was not executed here. The repository includes the scaffold and configuration, but a Java runtime is required before running `nextflow`.
