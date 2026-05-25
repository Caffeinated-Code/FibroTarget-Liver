CONFIG ?= config/project.yaml
R ?= Rscript

.PHONY: help setup check fetch-data curate analyze refine-labels pseudobulk prioritize validation hsc-validation gse244832-focused gse207310-validation secondary-validation evidence translational-evidence demo dashboard report render-summary validate-repo nextflow-demo all clean

help:
	@echo "Targets:"
	@echo "  make check        Validate local runtime and expected inputs"
	@echo "  make fetch-data   Download public input data declared in $(CONFIG)"
	@echo "  make curate       Build dataset/sample metadata tables"
	@echo "  make analyze      Run compact local analysis"
	@echo "  make refine-labels Refine labels using the published Seurat reference"
	@echo "  make pseudobulk   Run donor-level pseudobulk DE by refined state"
	@echo "  make prioritize   Build ranked target and biomarker evidence tables"
	@echo "  make validation   Prepare compact validation summaries"
	@echo "  make hsc-validation Run focused GSE244832 HSC/myofibroblast validation"
	@echo "  make gse244832-focused Run focused GSE244832 Seurat object validation"
	@echo "  make gse207310-validation Run symbol-level GSE207310 validation"
	@echo "  make secondary-validation Run GSE136103 blood and mouse marker validation"
	@echo "  make evidence     Enrich targets with public target/trial evidence"
	@echo "  make translational-evidence Add localization, conservation, safety, perturbation evidence"
	@echo "  make demo         Create a small GSE136103 demo dataset"
	@echo "  make dashboard    Prepare dashboard-ready data"
	@echo "  make report       Render text report artifacts"
	@echo "  make render-summary Render executive HTML summary"
	@echo "  make nextflow-demo Run the standalone Nextflow demo subproject"
	@echo "  make validate-repo Check required repo structure"
	@echo "  make all          Run the local compact workflow"

setup:
	$(R) workflow/00_setup.R --config $(CONFIG)

check:
	$(R) workflow/00_setup.R --config $(CONFIG) --check-only

fetch-data:
	$(R) workflow/01_fetch_data.R --config $(CONFIG)

curate:
	$(R) workflow/02_curate_metadata.R --config $(CONFIG)

analyze:
	$(R) workflow/03_compact_analysis.R --config $(CONFIG)

refine-labels:
	$(R) workflow/07_refine_annotations.R --config $(CONFIG)

pseudobulk:
	$(R) workflow/08_pseudobulk_de.R --config $(CONFIG)

prioritize:
	$(R) workflow/04_prioritize_targets.R --config $(CONFIG)

validation:
	python3 scripts/prepare_validation_datasets.py

hsc-validation:
	$(R) workflow/09_gse244832_hsc_validation.R --config $(CONFIG)

gse244832-focused:
	python3 scripts/extract_gse244832_focused_matrix.py
	$(R) workflow/12_reanalyze_gse244832_focused.R --config $(CONFIG)

gse207310-validation:
	$(R) workflow/11_validate_gse207310.R --config $(CONFIG)

secondary-validation:
	$(R) workflow/13_validate_blood_mouse_markers.R --config $(CONFIG)

evidence:
	python3 scripts/enrich_target_evidence.py
	$(R) -e "library(readr); library(dplyr); c <- read_csv('reports/tables/ranked_biomarker_target_candidates.csv', show_col_types=FALSE); e <- read_csv('reports/tables/target_public_evidence.csv', show_col_types=FALSE); write_csv(left_join(c, e, by='gene'), 'reports/tables/ranked_biomarker_target_candidates_enriched.csv')"

translational-evidence:
	python3 scripts/enrich_translational_evidence.py
	$(R) workflow/10_merge_translational_evidence.R --config $(CONFIG)

demo:
	$(R) scripts/create_demo_dataset.R

dashboard:
	$(R) workflow/05_prepare_dashboard_data.R --config $(CONFIG)

report:
	$(R) workflow/06_write_reports.R --config $(CONFIG)

render-summary:
	$(R) -e "rmarkdown::render('reports/executive_submission_summary.Rmd', output_file='executive_submission_summary.html', quiet=FALSE)"

nextflow-demo:
	PATH="/opt/homebrew/opt/openjdk/bin:$$PATH" nextflow run nextflow/fibrotarget_demo -profile local --outdir reports/nextflow_demo

validate-repo:
	python3 scripts/validate_repo_structure.py

all: check fetch-data curate analyze refine-labels pseudobulk prioritize validation hsc-validation gse244832-focused gse207310-validation secondary-validation evidence translational-evidence dashboard report render-summary

clean:
	rm -rf data/processed reports/tables reports/figures reports/qc dashboard/data logs
