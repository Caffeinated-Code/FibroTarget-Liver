# Configuration

`project.yaml` is the main configuration file for local and cloud-ready runs.

It defines:

- project metadata
- local output paths
- AWS placeholders
- primary and validation datasets
- QC defaults
- required liver fibrosis compartments
- marker panels
- target prioritization score components

Pipeline scripts should read from this config rather than hard-coding paths or thresholds.
