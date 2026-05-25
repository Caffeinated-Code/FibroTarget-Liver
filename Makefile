CONFIG ?= config/project.yaml
R ?= Rscript

.PHONY: help setup check fetch-data curate analyze prioritize validation evidence demo dashboard report validate-repo all clean

help:
	@echo "Targets:"
	@echo "  make check        Validate local runtime and expected inputs"
	@echo "  make fetch-data   Download public input data declared in $(CONFIG)"
	@echo "  make curate       Build dataset/sample metadata tables"
	@echo "  make analyze      Run compact local analysis"
	@echo "  make prioritize   Build ranked target and biomarker evidence tables"
	@echo "  make validation   Prepare compact validation summaries"
	@echo "  make evidence     Enrich targets with public target/trial evidence"
	@echo "  make demo         Create a small GSE136103 demo dataset"
	@echo "  make dashboard    Prepare dashboard-ready data"
	@echo "  make report       Render text report artifacts"
	@echo "  make validate-repo Check reviewer-facing repo structure"
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

prioritize:
	$(R) workflow/04_prioritize_targets.R --config $(CONFIG)

validation:
	python3 scripts/prepare_validation_datasets.py

evidence:
	python3 scripts/enrich_target_evidence.py
	$(R) -e "library(readr); library(dplyr); c <- read_csv('reports/tables/ranked_biomarker_target_candidates.csv', show_col_types=FALSE); e <- read_csv('reports/tables/target_public_evidence.csv', show_col_types=FALSE); write_csv(left_join(c, e, by='gene'), 'reports/tables/ranked_biomarker_target_candidates_enriched.csv')"

demo:
	$(R) scripts/create_demo_dataset.R

dashboard:
	$(R) workflow/05_prepare_dashboard_data.R --config $(CONFIG)

report:
	$(R) workflow/06_write_reports.R --config $(CONFIG)

validate-repo:
	python3 scripts/validate_repo_structure.py

all: check fetch-data curate analyze prioritize validation evidence dashboard report

clean:
	rm -rf data/processed reports/tables reports/figures reports/qc dashboard/data logs
