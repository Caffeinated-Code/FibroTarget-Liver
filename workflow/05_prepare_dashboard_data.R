suppressPackageStartupMessages({
  library(yaml)
  library(readr)
  library(dplyr)
})

args <- commandArgs(trailingOnly = TRUE)
get_arg <- function(flag, default = NULL) {
  i <- match(flag, args)
  if (is.na(i) || i == length(args)) default else args[[i + 1]]
}
cfg <- yaml::read_yaml(get_arg("--config", "config/project.yaml"))
dir.create(cfg$paths$dashboard_data_dir, recursive = TRUE, showWarnings = FALSE)

copy_if_exists <- function(src, dest) {
  if (file.exists(src)) file.copy(src, dest, overwrite = TRUE)
}

if (file.exists(file.path(cfg$paths$tables_dir, "ranked_biomarker_target_candidates_translational.csv"))) {
  copy_if_exists(file.path(cfg$paths$tables_dir, "ranked_biomarker_target_candidates_translational.csv"), file.path(cfg$paths$dashboard_data_dir, "ranked_candidates.csv"))
} else if (file.exists(file.path(cfg$paths$tables_dir, "ranked_biomarker_target_candidates_enriched.csv"))) {
  copy_if_exists(file.path(cfg$paths$tables_dir, "ranked_biomarker_target_candidates_enriched.csv"), file.path(cfg$paths$dashboard_data_dir, "ranked_candidates.csv"))
} else {
  copy_if_exists(file.path(cfg$paths$tables_dir, "ranked_biomarker_target_candidates.csv"), file.path(cfg$paths$dashboard_data_dir, "ranked_candidates.csv"))
}
copy_if_exists(file.path(cfg$paths$tables_dir, "compartment_de_cell_level_exploratory.csv"), file.path(cfg$paths$dashboard_data_dir, "de_results.csv"))
copy_if_exists(file.path(cfg$paths$tables_dir, "pseudobulk_priority_gene_de.csv"), file.path(cfg$paths$dashboard_data_dir, "pseudobulk_priority_gene_de.csv"))
copy_if_exists(file.path(cfg$paths$tables_dir, "gse244832_hsc_candidate_validation.csv"), file.path(cfg$paths$dashboard_data_dir, "gse244832_hsc_candidate_validation.csv"))
copy_if_exists(file.path(cfg$paths$tables_dir, "refined_cluster_annotations.csv"), file.path(cfg$paths$dashboard_data_dir, "refined_cluster_annotations.csv"))
copy_if_exists(file.path(cfg$paths$tables_dir, "hallmark_pathway_enrichment.csv"), file.path(cfg$paths$dashboard_data_dir, "pathway_enrichment.csv"))
copy_if_exists(file.path(cfg$paths$tables_dir, "qc_filtered_by_library_compartment.csv"), file.path(cfg$paths$dashboard_data_dir, "qc_summary.csv"))
message("Dashboard data prepared.")
