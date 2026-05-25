suppressPackageStartupMessages({
  library(yaml)
})

args <- commandArgs(trailingOnly = TRUE)
get_arg <- function(flag, default = NULL) {
  i <- match(flag, args)
  if (is.na(i) || i == length(args)) default else args[[i + 1]]
}

cfg <- yaml::read_yaml(get_arg("--config", "config/project.yaml"))
required <- c(
  file.path(cfg$paths$results_dir, "executive_submission_summary.md"),
  file.path(cfg$paths$results_dir, "executive_submission_summary.Rmd"),
  file.path(cfg$paths$results_dir, "executive_submission_summary.html"),
  file.path(cfg$paths$results_dir, "requirement_traceability.md"),
  file.path(cfg$paths$results_dir, "executive_summary", "README.md"),
  file.path(cfg$paths$results_dir, "screening_responses", "README.md"),
  file.path(cfg$paths$results_dir, "run_notes.md"),
  file.path(cfg$paths$tables_dir, "ranked_biomarker_target_candidates_translational.csv"),
  file.path(cfg$paths$tables_dir, "hallmark_pathway_enrichment.csv"),
  file.path(cfg$paths$tables_dir, "pseudobulk_priority_gene_de.csv"),
  file.path(cfg$paths$tables_dir, "gse244832_hsc_candidate_validation.csv"),
  file.path(cfg$paths$tables_dir, "gse244832_focused_object_candidate_summary.csv"),
  file.path(cfg$paths$tables_dir, "validation_gse207310_candidate_lm_results.csv"),
  file.path(cfg$paths$tables_dir, "gse136103_blood_candidate_marker_summary.csv"),
  file.path(cfg$paths$tables_dir, "gse136103_mouse_candidate_ortholog_summary.csv")
)
missing <- required[!file.exists(required)]
if (length(missing) > 0) stop("Missing report inputs: ", paste(missing, collapse = ", "))
message("Report artifacts are present.")
