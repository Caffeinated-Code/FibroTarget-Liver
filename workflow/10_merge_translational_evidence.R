suppressPackageStartupMessages({
  library(yaml)
  library(dplyr)
  library(readr)
  library(tidyr)
})

source("src/R/utils.R")

args <- commandArgs(trailingOnly = TRUE)
get_arg <- function(flag, default = NULL) {
  i <- match(flag, args)
  if (is.na(i) || i == length(args)) default else args[[i + 1]]
}

cfg <- yaml::read_yaml(get_arg("--config", "config/project.yaml"))
candidate_path <- file.path(cfg$paths$tables_dir, "ranked_biomarker_target_candidates_enriched.csv")
if (!file.exists(candidate_path)) candidate_path <- file.path(cfg$paths$tables_dir, "ranked_biomarker_target_candidates.csv")
trans_path <- file.path(cfg$paths$tables_dir, "target_translational_evidence.csv")
if (!file.exists(candidate_path) || !file.exists(trans_path)) stop("Run make prioritize, make evidence, and make translational-evidence first.")

candidates <- read_csv(candidate_path, show_col_types = FALSE)
trans <- read_csv(trans_path, show_col_types = FALSE)

orthology <- NULL
if (requireNamespace("babelgene", quietly = TRUE)) {
  genes <- unique(trans$gene)
  orthology <- babelgene::orthologs(genes, species = "mouse") |>
    as_tibble() |>
    transmute(
      gene = human_symbol,
      mouse_ortholog_symbol = symbol,
      mouse_entrez_id = entrez,
      mouse_orthology_support = support,
      mouse_orthology_support_n = support_n
    ) |>
    group_by(gene) |>
    summarise(
      mouse_ortholog_symbol = paste(unique(mouse_ortholog_symbol), collapse = ";"),
      mouse_entrez_id = paste(unique(mouse_entrez_id), collapse = ";"),
      mouse_orthology_support = paste(unique(mouse_orthology_support), collapse = "|"),
      mouse_orthology_support_n = max(mouse_orthology_support_n, na.rm = TRUE),
      .groups = "drop"
    )
} else {
  orthology <- tibble(gene = unique(trans$gene), mouse_ortholog_symbol = NA_character_, mouse_entrez_id = NA_character_, mouse_orthology_support = "babelgene unavailable", mouse_orthology_support_n = NA_real_)
}
safe_write(orthology, file.path(cfg$paths$tables_dir, "target_mouse_orthology.csv"))

merged <- candidates |>
  left_join(trans, by = "gene") |>
  left_join(orthology, by = "gene") |>
  mutate(
    translational_nomination = case_when(
      gene %in% c("SMOC2", "TIMP1") ~ "near-term biomarker program",
      gene %in% c("PDGFRA", "PDGFRB") ~ "therapeutic hypothesis requiring safety-window validation",
      gene %in% c("TREM2", "SPP1", "GPNMB", "CD9") ~ "macrophage-state biology and pharmacodynamic validation",
      gene %in% c("PLVAP", "ACKR1") ~ "vascular niche marker and spatial validation",
      gene %in% c("COL1A1", "COL3A1") ~ "fibrosis burden endpoint",
      TRUE ~ "secondary evidence candidate"
    ),
    nomination_caution = case_when(
      grepl("broad|vascular|pleiotropic|pericyte|wound", clinical_caution, ignore.case = TRUE) ~ "requires tissue-specificity and safety review",
      TRUE ~ "standard orthogonal validation required"
    )
  )

safe_write(merged, file.path(cfg$paths$tables_dir, "ranked_biomarker_target_candidates_translational.csv"))

message("Translational evidence merged.")
