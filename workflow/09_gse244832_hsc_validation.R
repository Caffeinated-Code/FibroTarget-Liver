suppressPackageStartupMessages({
  library(yaml)
  library(dplyr)
  library(readr)
  library(tidyr)
  library(ggplot2)
})

source("src/R/utils.R")

args <- commandArgs(trailingOnly = TRUE)
get_arg <- function(flag, default = NULL) {
  i <- match(flag, args)
  if (is.na(i) || i == length(args)) default else args[[i + 1]]
}

cfg <- yaml::read_yaml(get_arg("--config", "config/project.yaml"))
cluster_path <- file.path(cfg$paths$tables_dir, "validation_gse244832_candidate_expression_by_cluster.csv")
condition_path <- file.path(cfg$paths$tables_dir, "validation_gse244832_candidate_expression_by_condition.csv")
if (!file.exists(cluster_path) || !file.exists(condition_path)) stop("Run make validation first.")

cluster_expr <- read_csv(cluster_path, show_col_types = FALSE)
condition_expr <- read_csv(condition_path, show_col_types = FALSE)

hsc_markers <- c("COL1A1", "COL3A1", "ACTA2", "TAGLN", "PDGFRA", "PDGFRB", "LUM", "DCN", "RGS5", "THY1")
priority <- c("SMOC2", "TIMP1", "COL1A1", "COL3A1", "PDGFRA", "PDGFRB")

hsc_scores <- cluster_expr |>
  filter(gene %in% hsc_markers) |>
  group_by(condition, cluster) |>
  summarise(
    hsc_marker_genes_detected = n_distinct(gene[pct_detected > 0]),
    mean_hsc_norm = mean(mean_norm_per_cell, na.rm = TRUE),
    mean_hsc_pct_detected = mean(pct_detected, na.rm = TRUE),
    cells = max(cells),
    .groups = "drop"
  ) |>
  group_by(condition) |>
  mutate(hsc_like_rank_within_condition = dense_rank(desc(mean_hsc_norm))) |>
  ungroup() |>
  mutate(hsc_like_cluster = hsc_like_rank_within_condition <= 5 & hsc_marker_genes_detected >= 4) |>
  arrange(condition, hsc_like_rank_within_condition)

safe_write(hsc_scores, file.path(cfg$paths$tables_dir, "gse244832_hsc_like_cluster_scores.csv"))

hsc_clusters <- hsc_scores |> filter(hsc_like_cluster) |> select(condition, cluster)
candidate_hsc <- cluster_expr |>
  semi_join(hsc_clusters, by = c("condition", "cluster")) |>
  filter(gene %in% unique(c(priority, "SMOC2", "TIMP1"))) |>
  group_by(gene, condition) |>
  summarise(
    hsc_like_clusters = n_distinct(cluster),
    weighted_pct_detected = weighted.mean(pct_detected, cells, na.rm = TRUE),
    weighted_mean_norm = weighted.mean(mean_norm_per_cell, cells, na.rm = TRUE),
    cells = sum(cells),
    .groups = "drop"
  ) |>
  group_by(gene) |>
  mutate(
    normal_mean_norm = weighted_mean_norm[match("NORMAL", condition)],
    steatohepatitis_mean_norm = weighted_mean_norm[match(if_else("NASH" %in% condition, "NASH", "MASH"), condition)],
    steatohepatitis_vs_normal_delta = steatohepatitis_mean_norm - normal_mean_norm
  ) |>
  ungroup() |>
  select(-normal_mean_norm, -steatohepatitis_mean_norm)

condition_direction <- condition_expr |>
  filter(gene %in% unique(c(priority, "SMOC2", "TIMP1"))) |>
  select(gene, condition, whole_liver_mean_norm = mean_norm_per_cell, whole_liver_pct_detected = pct_detected)

validation_tbl <- candidate_hsc |>
  left_join(condition_direction, by = c("gene", "condition")) |>
  arrange(gene, condition)

safe_write(validation_tbl, file.path(cfg$paths$tables_dir, "gse244832_hsc_candidate_validation.csv"))

p <- validation_tbl |>
  mutate(condition = factor(condition, levels = c("NORMAL", "NAFL", "NASH", "MASH"))) |>
  ggplot(aes(condition, gene, fill = weighted_mean_norm)) +
  geom_tile(color = "white", linewidth = 0.3) +
  geom_text(aes(label = sprintf("%.2f", weighted_mean_norm)), size = 3) +
  scale_fill_gradient(low = "#F7FBFF", high = "#2166AC") +
  labs(
    title = "GSE244832 HSC-like validation signal",
    x = NULL,
    y = NULL,
    fill = "mean normalized expression"
  ) +
  theme_project()
save_plot(p, file.path(cfg$paths$figures_dir, "gse244832_hsc_validation_heatmap.png"), 7.5, 4.5)

message("GSE244832 HSC validation module complete.")
