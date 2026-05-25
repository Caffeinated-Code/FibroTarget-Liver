suppressPackageStartupMessages({
  library(yaml)
  library(Seurat)
  library(Matrix)
  library(dplyr)
  library(readr)
  library(tidyr)
  library(limma)
  library(ggplot2)
})

source("src/R/utils.R")

args <- commandArgs(trailingOnly = TRUE)
get_arg <- function(flag, default = NULL) {
  i <- match(flag, args)
  if (is.na(i) || i == length(args)) default else args[[i + 1]]
}

cfg <- yaml::read_yaml(get_arg("--config", "config/project.yaml"))
obj_path <- file.path(cfg$paths$processed_dir, "gse136103_refined_seurat.rds")
if (!file.exists(obj_path)) obj_path <- file.path(cfg$paths$processed_dir, "gse136103_compact_seurat.rds")
if (!file.exists(obj_path)) stop("Run make analyze and make refine-labels first.")

obj <- readRDS(obj_path)
if (!"refined_cell_state" %in% colnames(obj@meta.data)) obj$refined_cell_state <- obj$compartment_call

counts <- GetAssayData(obj, assay = "RNA", layer = "counts")
meta <- obj@meta.data |>
  tibble::rownames_to_column("cell") |>
  mutate(
    refined_cell_state = coalesce(refined_cell_state, compartment_call),
    disease_state = factor(disease_state, levels = c(cfg$analysis$disease_contrast$reference, cfg$analysis$disease_contrast$case))
  )

sample_state_counts <- meta |>
  count(refined_cell_state, donor, disease_state, sample_id, name = "cells") |>
  arrange(refined_cell_state, donor, sample_id)
safe_write(sample_state_counts, file.path(cfg$paths$tables_dir, "pseudobulk_sample_state_cell_counts.csv"))

states <- sample_state_counts |>
  filter(cells >= 20, !is.na(disease_state)) |>
  group_by(refined_cell_state, disease_state) |>
  summarise(donors = n_distinct(donor), .groups = "drop") |>
  tidyr::pivot_wider(names_from = disease_state, values_from = donors, values_fill = 0) |>
  filter(.data[[cfg$analysis$disease_contrast$reference]] >= 3, .data[[cfg$analysis$disease_contrast$case]] >= 3) |>
  pull(refined_cell_state)

run_state <- function(state) {
  state_meta <- meta |>
    filter(refined_cell_state == state, !is.na(disease_state)) |>
    group_by(donor, disease_state) |>
    mutate(pseudobulk_id = paste(state, donor, as.character(disease_state), sep = "|")) |>
    ungroup()
  keep_groups <- state_meta |>
    count(pseudobulk_id, donor, disease_state, name = "cells") |>
    filter(cells >= 20)
  state_meta <- state_meta |> semi_join(keep_groups, by = c("pseudobulk_id", "donor", "disease_state"))
  if (n_distinct(state_meta$disease_state) < 2 || n_distinct(state_meta$donor) < 6) return(NULL)

  groups <- split(match(state_meta$cell, colnames(counts)), state_meta$pseudobulk_id)
  pb <- do.call(cbind, lapply(groups, function(idx) Matrix::rowSums(counts[, idx, drop = FALSE])))
  colnames(pb) <- names(groups)
  pb_meta <- tibble(pseudobulk_id = colnames(pb)) |>
    separate(pseudobulk_id, into = c("refined_cell_state", "donor", "disease_state"), sep = "\\|", remove = FALSE)
  pb_meta$disease_state <- factor(pb_meta$disease_state, levels = c(cfg$analysis$disease_contrast$reference, cfg$analysis$disease_contrast$case))

  lib_size <- Matrix::colSums(pb)
  expressed <- Matrix::rowSums(pb >= 5) >= max(3, ceiling(0.25 * ncol(pb)))
  pb <- pb[expressed, , drop = FALSE]
  if (nrow(pb) < 100) return(NULL)

  log_cpm <- log2(t(t(pb + 0.5) / (lib_size + 1)) * 1e6)
  design <- model.matrix(~ disease_state, data = pb_meta)
  fit <- limma::eBayes(limma::lmFit(log_cpm, design), trend = TRUE)
  res <- limma::topTable(fit, coef = "disease_statecirrhotic", number = Inf, sort.by = "P") |>
    tibble::rownames_to_column("gene") |>
    mutate(
      refined_cell_state = state,
      contrast = "cirrhotic_vs_healthy_donor_level_pseudobulk",
      n_pseudobulk_samples = ncol(pb),
      n_healthy_donors = n_distinct(pb_meta$donor[pb_meta$disease_state == cfg$analysis$disease_contrast$reference]),
      n_cirrhotic_donors = n_distinct(pb_meta$donor[pb_meta$disease_state == cfg$analysis$disease_contrast$case]),
      .before = 1
    ) |>
    rename(log2FC = logFC, p_value = P.Value, p_adj = adj.P.Val)
  res
}

de <- bind_rows(lapply(states, run_state))
if (nrow(de) == 0) {
  warning("No refined cell state had enough donor-level replication for pseudobulk DE.")
  de <- tibble()
}
safe_write(de, file.path(cfg$paths$tables_dir, "pseudobulk_de_by_refined_state.csv"))

priority_genes <- c("SMOC2", "TIMP1", "PLVAP", "ACKR1", "COL1A1", "COL3A1", "PDGFRA", "PDGFRB", "TREM2", "CD9", "SPP1", "GPNMB")
priority <- de |>
  filter(gene %in% priority_genes) |>
  arrange(refined_cell_state, p_adj, desc(log2FC))
safe_write(priority, file.path(cfg$paths$tables_dir, "pseudobulk_priority_gene_de.csv"))

if (nrow(priority) > 0) {
  p <- priority |>
    mutate(gene = factor(gene, levels = priority_genes)) |>
    ggplot(aes(gene, log2FC, fill = -log10(pmax(p_adj, 1e-300)))) +
    geom_col() +
    facet_wrap(~ refined_cell_state, scales = "free_y") +
    coord_flip() +
    labs(
      title = "Donor-level pseudobulk support for priority candidates",
      x = NULL,
      y = "log2 fold change, cirrhotic vs healthy",
      fill = "-log10 FDR"
    ) +
    theme_project()
  save_plot(p, file.path(cfg$paths$figures_dir, "pseudobulk_priority_gene_de.png"), 10, 6)
}

message("Donor-level pseudobulk DE complete.")
