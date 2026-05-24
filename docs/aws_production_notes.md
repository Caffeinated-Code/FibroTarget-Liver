# AWS Production Notes

This project is developed locally first, with conventions that can map cleanly to AWS.

## Execution Model

The local `make` targets are intentionally close to cloud job boundaries:

1. `fetch-data`: download public inputs into object storage or local raw storage.
2. `curate`: create metadata tables and input manifests.
3. `analyze`: run the compact discovery workflow.
4. `prioritize`: generate evidence-weighted target rankings.
5. `dashboard`: prepare small dashboard-ready files.
6. `report`: generate final narrative outputs.

In production, these can become AWS Batch jobs or Step Functions tasks using the same container image and config file.

## Storage Layout

Expected S3 prefix structure:

```text
s3://<bucket>/liver-fibrosis-single-cell/
  raw/
  metadata/
  processed/
  reports/
  logs/
  dashboard/data/
```

Large single-cell objects should stay in S3 or EFS and should not be committed to Git. Reports, small tables, and dashboard summaries can be versioned or published as release artifacts.

## Compute

The primary dataset is small enough for a local compact run from processed MTX files. Larger validation datasets, especially GSE244832, should run as separate jobs with explicit memory and disk requests.

Recommended future AWS components:

- ECR for the Docker image
- S3 for raw and processed data
- AWS Batch or ECS for execution
- Step Functions for orchestration
- CloudWatch logs for run monitoring
- Parameter Store or Secrets Manager for protected configuration
- Optional EFS for shared large intermediate objects

## Design Principles

- Keep data paths config-driven.
- Keep workflow steps restartable.
- Write small, reviewable tables for interpretation.
- Treat single-cell objects as derived artifacts, not source code.
- Separate scientific outputs from operational logs.
- Make validation datasets modular so a failed optional validation does not block the primary analysis.
