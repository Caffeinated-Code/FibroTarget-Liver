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
  file.path(cfg$paths$results_dir, "executive_summary", "README.md"),
  file.path(cfg$paths$results_dir, "screening_responses", "README.md"),
  file.path(cfg$paths$results_dir, "run_notes.md"),
  file.path(cfg$paths$tables_dir, "ranked_biomarker_target_candidates.csv"),
  file.path(cfg$paths$tables_dir, "hallmark_pathway_enrichment.csv")
)
missing <- required[!file.exists(required)]
if (length(missing) > 0) stop("Missing report inputs: ", paste(missing, collapse = ", "))
message("Report artifacts are present.")
