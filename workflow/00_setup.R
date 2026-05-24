suppressPackageStartupMessages({
  library(yaml)
})

args <- commandArgs(trailingOnly = TRUE)
get_arg <- function(flag, default = NULL) {
  i <- match(flag, args)
  if (is.na(i) || i == length(args)) default else args[[i + 1]]
}
has_flag <- function(flag) flag %in% args

config_path <- get_arg("--config", "config/project.yaml")
cfg <- yaml::read_yaml(config_path)

dir.create(cfg$paths$raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(cfg$paths$metadata_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(cfg$paths$processed_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(cfg$paths$results_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(cfg$paths$figures_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(cfg$paths$tables_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(cfg$paths$logs_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(cfg$paths$dashboard_data_dir, recursive = TRUE, showWarnings = FALSE)

required <- c("yaml", "Matrix", "dplyr", "ggplot2", "readr", "Seurat", "SeuratObject", "shiny", "DT", "plotly")
optional <- c("clusterProfiler", "org.Hs.eg.db", "limma", "msigdbr", "patchwork", "ggrepel")

pkg_status <- data.frame(
  package = c(required, optional),
  required = c(rep(TRUE, length(required)), rep(FALSE, length(optional))),
  installed = vapply(c(required, optional), requireNamespace, logical(1), quietly = TRUE)
)

readr::write_csv(pkg_status, file.path(cfg$paths$logs_dir, "package_status.csv"))

missing_required <- pkg_status$package[pkg_status$required & !pkg_status$installed]
if (length(missing_required) > 0) {
  stop("Missing required packages: ", paste(missing_required, collapse = ", "))
}

message("Runtime check complete.")
message("R: ", R.version.string)
message("Config: ", normalizePath(config_path))
if (has_flag("--check-only")) {
  message("Check-only mode complete.")
}
