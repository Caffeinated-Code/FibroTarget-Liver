suppressPackageStartupMessages({
  library(yaml)
  library(Seurat)
  library(Matrix)
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
query_path <- file.path(cfg$paths$processed_dir, "gse136103_compact_seurat.rds")
reference_path <- file.path("data", "reference", "tissue.rdata")
if (!file.exists(query_path)) stop("Run make analyze first.")
if (!file.exists(reference_path)) stop("Missing published reference object at data/reference/tissue.rdata.")

query <- readRDS(query_path)

ref_env <- new.env(parent = emptyenv())
load(reference_path, envir = ref_env)
if (!"tissue" %in% ls(ref_env)) stop("Reference RData did not contain object named 'tissue'.")
reference <- ref_env[["tissue"]]
ref_meta <- reference@meta.data
ref_data <- attr(reference, "data")
if (is.null(ref_data) || !"annotation_indepth" %in% colnames(ref_meta)) {
  stop("Published reference object lacks normalized data or annotation_indepth metadata.")
}

reference_summary <- ref_meta |>
  tibble::rownames_to_column("cell") |>
  count(annotation_lineage, annotation_indepth, condition, name = "cells") |>
  arrange(annotation_lineage, annotation_indepth, condition)
safe_write(reference_summary, file.path(cfg$paths$tables_dir, "published_reference_annotation_summary.csv"))

query_clusters <- query@meta.data |>
  tibble::rownames_to_column("cell") |>
  count(seurat_clusters, disease_state, compartment_call, name = "cells") |>
  group_by(seurat_clusters) |>
  mutate(cluster_cells = sum(cells), frac = cells / cluster_cells) |>
  ungroup()

counts <- GetAssayData(query, assay = "RNA", layer = "data")
common_genes <- intersect(rownames(counts), rownames(ref_data))
marker_genes <- unique(c(
  cfg$analysis$key_compartments$mesenchymal$markers,
  cfg$analysis$key_compartments$macrophage$markers,
  cfg$analysis$key_compartments$endothelial$markers,
  "KRT7", "KRT19", "ALB", "APOA1", "MS4A1", "CD3D", "NKG7", "LILRA4", "TPSAB1"
))
variable_common <- intersect(VariableFeatures(query), common_genes)
signature_genes <- unique(c(intersect(marker_genes, common_genes), head(variable_common, 1200)))
if (length(signature_genes) < 50) stop("Too few common genes for reference-informed annotation.")

cluster_ids <- sort(unique(as.character(query$seurat_clusters)))
query_avg <- sapply(cluster_ids, function(cluster_id) {
  cells <- colnames(query)[as.character(query$seurat_clusters) == cluster_id]
  Matrix::rowMeans(counts[signature_genes, cells, drop = FALSE])
})
if (is.null(dim(query_avg))) query_avg <- matrix(query_avg, ncol = 1, dimnames = list(signature_genes, cluster_ids))

reference_labels <- names(which(table(ref_meta$annotation_indepth) >= 50))
reference_avg <- sapply(reference_labels, function(label) {
  cells <- rownames(ref_meta)[ref_meta$annotation_indepth == label]
  Matrix::rowMeans(ref_data[signature_genes, cells, drop = FALSE])
})

cor_mat <- suppressWarnings(cor(query_avg, reference_avg, method = "spearman", use = "pairwise.complete.obs"))
best <- apply(cor_mat, 1, function(x) {
  tibble(reference_label = names(x), correlation = as.numeric(x)) |>
    arrange(desc(correlation)) |>
    slice_head(n = 3)
})
best_tbl <- bind_rows(lapply(names(best), function(cluster_id) {
  best[[cluster_id]] |> mutate(seurat_cluster = cluster_id, rank = row_number(), .before = 1)
}))

lineage_lookup <- ref_meta |>
  distinct(annotation_indepth, annotation_lineage) |>
  group_by(annotation_indepth) |>
  slice_head(n = 1) |>
  ungroup()

canonical_override <- query_clusters |>
  group_by(seurat_clusters, compartment_call) |>
  summarise(cells = sum(cells), .groups = "drop") |>
  group_by(seurat_clusters) |>
  slice_max(cells, n = 1, with_ties = FALSE) |>
  ungroup() |>
  rename(seurat_cluster = seurat_clusters) |>
  mutate(
    canonical_state = case_when(
      compartment_call == "mesenchymal_HSC_myofibroblast" ~ "Mesenchyme / myofibroblast program",
      compartment_call == "macrophage_monocyte" ~ "MPs / scar-associated macrophage program",
      compartment_call == "endothelial" ~ "Endothelia / scar-associated endothelial program",
      TRUE ~ "Reference-supported non-priority lineage"
    )
  )

annotation_tbl <- best_tbl |>
  filter(rank == 1) |>
  left_join(lineage_lookup, by = c("reference_label" = "annotation_indepth")) |>
  left_join(canonical_override, by = "seurat_cluster") |>
  mutate(
    refined_cell_state = case_when(
      compartment_call == "mesenchymal_HSC_myofibroblast" & grepl("Myofibroblasts|Mesenchyme", reference_label) ~ "HSC_myofibroblast_reference_supported",
      compartment_call == "mesenchymal_HSC_myofibroblast" ~ "HSC_myofibroblast_marker_supported",
      compartment_call == "macrophage_monocyte" & grepl("^MPs", reference_label) ~ "macrophage_reference_supported",
      compartment_call == "macrophage_monocyte" ~ "macrophage_marker_supported",
      compartment_call == "endothelial" & grepl("^Endothelia", reference_label) ~ "endothelial_reference_supported",
      compartment_call == "endothelial" ~ "endothelial_marker_supported",
      TRUE ~ paste0("reference_", gsub("[^A-Za-z0-9]+", "_", annotation_lineage))
    ),
    reference_confidence = case_when(
      correlation >= 0.55 ~ "high",
      correlation >= 0.35 ~ "moderate",
      TRUE ~ "low"
    )
  ) |>
  select(
    seurat_cluster, refined_cell_state, reference_label, annotation_lineage,
    compartment_call, canonical_state, correlation, reference_confidence
  ) |>
  arrange(as.numeric(seurat_cluster))

safe_write(best_tbl, file.path(cfg$paths$tables_dir, "reference_cluster_label_transfer_top_hits.csv"))
safe_write(annotation_tbl, file.path(cfg$paths$tables_dir, "refined_cluster_annotations.csv"))

query$refined_cell_state <- annotation_tbl$refined_cell_state[match(as.character(query$seurat_clusters), annotation_tbl$seurat_cluster)]
query$reference_label <- annotation_tbl$reference_label[match(as.character(query$seurat_clusters), annotation_tbl$seurat_cluster)]
saveRDS(query, file.path(cfg$paths$processed_dir, "gse136103_refined_seurat.rds"))

emb <- Embeddings(query, "umap") |>
  as.data.frame() |>
  tibble::rownames_to_column("cell") |>
  left_join(query@meta.data |> tibble::rownames_to_column("cell"), by = "cell")
safe_write(emb, file.path(cfg$paths$dashboard_data_dir, "umap_metadata.csv"))

p <- DimPlot(query, reduction = "umap", group.by = "refined_cell_state", raster = TRUE, label = FALSE) +
  ggtitle("Reference-informed refined cell states") +
  theme_project()
save_plot(p, file.path(cfg$paths$figures_dir, "umap_refined_cell_states.png"), 9, 5.5)

message("Reference-informed annotation refinement complete.")
