# FibroTarget-Liver Nextflow Demo

This standalone Nextflow subproject tests the pipeline contract with a small GSE136103-derived 10x-style demo dataset. It runs locally on a laptop and uses the same input/output pattern that can be extended to AWS Batch.

## What This Demo Proves

The demo does not reanalyze the full liver atlas. It proves the contract a production workflow needs:

- a sample sheet points to 10x-style input data
- metadata are read in a consistent format
- candidate genes are checked
- compartment and QC summaries are written
- outputs land in a predictable report directory

That is the same pattern a larger workflow would use for proprietary or full public datasets.

## Inputs

Tracked demo inputs:

```text
data/demo/gse136103_demo_10x/
  matrix.mtx
  features.tsv
  barcodes.tsv
data/demo/gse136103_demo_metadata.csv
nextflow/fibrotarget_demo/demo_samplesheet.csv
```

Expected sample sheet columns:

| Column | Meaning |
|---|---|
| sample_id | Stable sample name |
| matrix_dir | Local path or S3 URI to the 10x-style matrix directory |
| metadata | Local path or S3 URI to sample metadata |

## Local Run

From the repository root:

```bash
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
nextflow run nextflow/fibrotarget_demo -profile local --outdir reports/nextflow_demo
```

Equivalent Make target:

```bash
make nextflow-demo
```

Expected local outputs:

```text
reports/nextflow_demo/
  demo_qc_summary.csv
  demo_compartment_summary.csv
  demo_candidate_gene_presence.csv
  demo_run_summary.md
```

Quick check:

```bash
ls reports/nextflow_demo
cat reports/nextflow_demo/demo_run_summary.md
```

## AWS Pattern

The AWS profile is a production template. Before running it, create:

- an S3 bucket for inputs, work, and results
- an ECR image with the R runtime and required packages
- an AWS Batch queue and job definition
- AWS credentials through the usual profile or environment

```bash
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
export NXF_WORK=s3://<bucket>/fibrotarget-liver/work
export PIPELINE_IMAGE=<account>.dkr.ecr.us-west-2.amazonaws.com/fibrotarget-liver:latest

nextflow run nextflow/fibrotarget_demo -profile aws \
  --input s3://<bucket>/demo/demo_samplesheet.csv \
  --outdir s3://<bucket>/results/fibrotarget-demo
```

Suggested S3 layout:

```text
s3://<bucket>/fibrotarget-liver/
  demo/
    demo_samplesheet.csv
    gse136103_demo_10x/
    gse136103_demo_metadata.csv
  work/
  results/
```

## Outputs

- `demo_qc_summary.csv`
- `demo_compartment_summary.csv`
- `demo_candidate_gene_presence.csv`
- `demo_run_summary.md`

The tracked outputs in `reports/nextflow_demo/` show the expected result shape.

## Troubleshooting

- `nextflow: command not found`: install Nextflow or run through the project Make target after installing Java.
- `Cannot find Java`: add OpenJDK to `PATH`, for example `export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"`.
- Missing input paths: run from the repository root or use absolute paths in the sample sheet.
- AWS run fails before submitting jobs: check AWS credentials, S3 bucket access, Batch queue name, and container image URI.
