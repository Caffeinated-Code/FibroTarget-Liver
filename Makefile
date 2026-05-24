CONFIG ?= config/project.yaml
R ?= Rscript

.PHONY: help setup check fetch-data curate analyze prioritize dashboard report all clean

help:
	@echo "Targets:"
	@echo "  make check        Validate local runtime and expected inputs"
	@echo "  make fetch-data   Download public input data declared in $(CONFIG)"
	@echo "  make curate       Build dataset/sample metadata tables"
	@echo "  make analyze      Run compact local analysis"
	@echo "  make prioritize   Build ranked target and biomarker evidence tables"
	@echo "  make dashboard    Prepare dashboard-ready data"
	@echo "  make report       Render text report artifacts"
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

dashboard:
	$(R) workflow/05_prepare_dashboard_data.R --config $(CONFIG)

report:
	$(R) workflow/06_write_reports.R --config $(CONFIG)

all: check fetch-data curate analyze prioritize dashboard report

clean:
	rm -rf data/processed reports/tables reports/figures reports/qc dashboard/data logs
