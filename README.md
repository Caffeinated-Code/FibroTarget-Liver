# FibroTarget-Liver

**FibroTarget-Liver** is a reproducible single-cell target-discovery workflow for human liver fibrosis, MASH, and cirrhosis. It starts from public count matrices, runs a Seurat-based analysis, validates candidate targets against external liver disease datasets, enriches targets with public evidence, and packages the results for review in tables, figures, reports, and a Shiny dashboard.

The primary analysis uses **GSE136103**, the Ramachandran et al. human cirrhosis single-cell RNA-seq dataset. Validation support uses **GSE244832** for MASH/HSC target evidence and **GSE207310** for bulk NAFLD/NASH biomarker directionality.

## Start Here

For a fast review:

1. [Interviewer guide](docs/interviewer_guide.md)
2. [Executive summary](reports/executive_summary/README.md)
3. [Translational ranked candidates](reports/tables/ranked_biomarker_target_candidates_translational.csv)
4. [Marker validation figure](reports/figures/required_compartment_marker_dotplot.png)
5. [Interactive dashboard](dashboard/README.md)

For implementation details:

- [Architecture](docs/architecture.md)
- [Input and output contract](docs/io_contract.md)
- [Reproducibility](docs/reproducibility.md)
- [Nextflow and AWS scaffold](nextflow/README.md)
- [Open-source pipeline roadmap](docs/open_source_pipeline_roadmap.md)

## What The Repository Is

This is a **reference workflow and target-prioritization framework**, not a manuscript supplement dump.

It separates:

- analysis code in `workflow/`, `src/`, and `scripts/`
- reproducible execution in `Makefile`, `renv.lock`, `Dockerfile`, and `nextflow/`
- data contracts and metadata in `config/` and `data/metadata/`
- review artifacts in `reports/`, `dashboard/`, and `docs/`

## Main Scientific Question

Which cell-type-linked genes in human liver fibrosis are plausible as:

- diagnostic biomarkers
- pharmacodynamic biomarkers
- therapeutic targets
- mechanistic markers for follow-up validation

The analysis focuses on three fibrosis-relevant compartments:

- activated mesenchymal, HSC, and myofibroblast-like cells
- macrophage and monocyte populations
- endothelial cells

## Key Findings

The compact Seurat analysis recovered all required compartments across healthy and cirrhotic donors. Marker validation supports broad mesenchymal/HSC/myofibroblast-like, macrophage/monocyte, and endothelial calls.

Top candidates include:

- endothelial remodeling: **ACKR1**, **PLVAP**, **VWF**
- stromal and matrix remodeling: **TIMP1**, **COL3A1**, **COL1A1**, **MMP2**, **PDGFRA**, **THY1**, **DCN**, **LUM**
- macrophage-associated biology: **SPP1**, **CD9**, **TREM2**, **GPNMB**
- translational validation candidates: **SMOC2**, **LOXL2**, **SERPINE1**, **PDGFRB**

The main interpretation is deliberately conservative: a strong fibrosis marker is not automatically a good therapeutic target. Matrix genes are useful biomarkers and pharmacodynamic markers, while receptor, surface, secreted, or enzyme candidates require additional validation for specificity, safety, conservation, and perturbation response.

## Reproduce Locally

Requirements:

- R 4.6.0
- Seurat 5.5.0
- `renv`
- internet access for public GEO downloads if raw data are not already present

Run the full local workflow:

```bash
make all
```

Run individual stages:

```bash
make check
make fetch-data
make curate
make analyze
make refine-labels
make pseudobulk
make prioritize
make validation
make hsc-validation
make evidence
make translational-evidence
make dashboard
make report
```

Validate repository structure:

```bash
make validate-repo
```

Launch the dashboard:

```bash
Rscript -e "shiny::runApp('dashboard')"
```

## Demo Dataset

A tiny GSE136103-derived demo dataset is tracked under `data/demo/` so pipeline wiring can be tested without downloading the full primary archive.

The demo uses a 10x-style Matrix Market layout:

```text
data/demo/gse136103_demo_10x/
  matrix.mtx
  features.tsv
  barcodes.tsv
data/demo/gse136103_demo_metadata.csv
```

## Repository Map

```text
config/                 Config-driven paths, datasets, markers, scoring
workflow/               Ordered Seurat workflow stages
src/R/                  Shared R functions
scripts/                Utility scripts for validation, evidence, demo data
nextflow/               Local/AWS Nextflow scaffold
dashboard/              Shiny dashboard and dashboard-ready data
reports/                Executive summary, figures, tables, written responses
docs/                   Architecture, IO contract, reproducibility, primer
data/metadata/          Curated manifests
data/demo/              Tiny tracked demo dataset
```

## Reproducibility And Data Policy

Tracked:

- code
- config
- demo data
- metadata manifests
- compact figures and tables
- dashboard-ready CSVs
- documentation

Not tracked:

- raw GEO archives
- extracted validation matrices
- large Seurat objects
- logs
- private notes

Large data are expected to live in local ignored directories for this repo and in S3 or EFS for AWS execution.

## Current Limitations

- Cell-level differential expression is retained for exploration; donor-level pseudobulk outputs are now the main inferential tables.
- GSE244832 is prepared and summarized for candidate validation, including a focused HSC-like cluster module; full object-level reanalysis is a future module.
- GSE207310 is staged, but symbol-level computed validation needs an Ensembl-to-symbol annotation module.
- The Nextflow layer is a scaffold. It was not executed locally because Java was unavailable on this machine.

## References

- Ramachandran et al. Resolving the fibrotic niche of human liver cirrhosis at single-cell level. Nature, 2019.
- Rinella et al. A multisociety Delphi consensus statement on new fatty liver disease nomenclature. Hepatology, 2023.
- GSE244832 and GSE207310 GEO records for validation datasets.
