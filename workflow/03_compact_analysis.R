suppressPackageStartupMessages({
  library(yaml)
  library(Seurat)
  library(dplyr)
  library(readr)
  library(ggplot2)
  library(Matrix)
  library(patchwork)
})

source("src/R/utils.R")

args <- commandArgs(trailingOnly = TRUE)
get_arg <- function(flag, default = NULL) {
  i <- match(flag, args)
  if (is.na(i) || i == length(args)) default else args[[i + 1]]
}

set.seed(20260524)
cfg <- yaml::read_yaml(get_arg("--config", "config/project.yaml"))
manifest_path <- file.path(cfg$paths$metadata_dir, "gse136103_sample_manifest.csv")
if (!file.exists(manifest_path)) stop("Run workflow/02_curate_metadata.R first.")
manifest <- read_csv(manifest_path, show_col_types = FALSE) |> filter(include_primary)

extract_dir <- file.path(cfg$paths$processed_dir, "extracted_gse136103")
objects <- vector("list", nrow(manifest))
for (i in seq_len(nrow(manifest))) {
  row <- manifest[i, ]
  message("Reading ", row$sample_token)
  mat <- read_10x_from_tar(cfg$datasets$primary$archive, row, extract_dir)
  obj <- CreateSeuratObject(
    counts = mat,
    project = "GSE136103",
    min.cells = cfg$analysis$min_cells_per_gene,
    min.features = cfg$analysis$min_genes_per_cell
  )
  obj$sample_id <- row$sample_token
  obj$gsm <- row$gsm
  obj$donor <- row$donor
  obj$disease_state <- row$disease_state
  obj$fraction <- row$fraction
  obj$tissue <- row$tissue
  obj$species <- row$species
  obj[["percent.mt"]] <- PercentageFeatureSet(obj, pattern = "^MT-")
  objects[[i]] <- obj
}

combined <- merge(objects[[1]], y = objects[-1], add.cell.ids = manifest$sample_token, project = "GSE136103")
combined <- JoinLayers(combined)

qc_raw <- combined@meta.data |>
  tibble::rownames_to_column("cell") |>
  group_by(disease_state, donor, sample_id, fraction) |>
  summarise(
    cells = n(),
    median_genes = median(nFeature_RNA),
    median_umis = median(nCount_RNA),
    median_percent_mt = median(percent.mt),
    .groups = "drop"
  )
safe_write(qc_raw, file.path(cfg$paths$tables_dir, "qc_by_library.csv"))

max_mt <- cfg$analysis$max_mito_percent_default
combined <- subset(combined, subset = nFeature_RNA >= 200 & percent.mt <= max_mt)

combined <- NormalizeData(combined, verbose = FALSE)
combined <- FindVariableFeatures(combined, nfeatures = cfg$analysis$top_variable_genes, verbose = FALSE)
combined <- ScaleData(combined, features = VariableFeatures(combined), verbose = FALSE)
combined <- RunPCA(combined, features = VariableFeatures(combined), npcs = 30, verbose = FALSE)
combined <- FindNeighbors(combined, dims = 1:20, verbose = FALSE)
combined <- FindClusters(combined, resolution = 0.5, verbose = FALSE)
combined <- RunUMAP(combined, dims = 1:20, verbose = FALSE)

markers <- cfg$analysis$key_compartments
combined$score_mesenchymal <- marker_score(combined, markers$mesenchymal$markers)
combined$score_macrophage <- marker_score(combined, markers$macrophage$markers)
combined$score_endothelial <- marker_score(combined, markers$endothelial$markers)

score_df <- combined@meta.data |>
  tibble::rownames_to_column("cell") |>
  mutate(
    compartment_call = case_when(
      score_mesenchymal >= pmax(score_macrophage, score_endothelial, na.rm = TRUE) & score_mesenchymal > 0.25 ~ "mesenchymal_HSC_myofibroblast",
      score_macrophage >= pmax(score_mesenchymal, score_endothelial, na.rm = TRUE) & score_macrophage > 0.25 ~ "macrophage_monocyte",
      score_endothelial >= pmax(score_mesenchymal, score_macrophage, na.rm = TRUE) & score_endothelial > 0.25 ~ "endothelial",
      TRUE ~ "other_or_unresolved"
    )
  )
combined$compartment_call <- score_df$compartment_call[match(colnames(combined), score_df$cell)]

qc_filtered <- combined@meta.data |>
  tibble::rownames_to_column("cell") |>
  group_by(disease_state, donor, sample_id, fraction, compartment_call) |>
  summarise(cells = n(), median_genes = median(nFeature_RNA), median_percent_mt = median(percent.mt), .groups = "drop")
safe_write(qc_filtered, file.path(cfg$paths$tables_dir, "qc_filtered_by_library_compartment.csv"))

p_umap_disease <- DimPlot(combined, reduction = "umap", group.by = "disease_state", raster = TRUE) +
  ggtitle("GSE136103 human liver cells by disease state") + theme_project()
p_umap_compartment <- DimPlot(combined, reduction = "umap", group.by = "compartment_call", raster = TRUE) +
  ggtitle("Marker-supported required compartments") + theme_project()
save_plot(p_umap_disease, file.path(cfg$paths$figures_dir, "umap_disease_state.png"), 7, 5)
save_plot(p_umap_compartment, file.path(cfg$paths$figures_dir, "umap_required_compartments.png"), 8, 5)

marker_panel <- unique(unlist(lapply(markers, `[[`, "markers")))
marker_panel <- intersect(marker_panel, rownames(combined))
dot <- DotPlot(combined, features = marker_panel, group.by = "compartment_call") +
  RotatedAxis() +
  ggtitle("Marker validation for required compartments") +
  theme_project() +
  theme(axis.text.x = element_text(size = 8, angle = 45, hjust = 1))
save_plot(dot, file.path(cfg$paths$figures_dir, "required_compartment_marker_dotplot.png"), 13, 5.5)

Idents(combined) <- "compartment_call"
de_results <- list()
for (compartment in c("mesenchymal_HSC_myofibroblast", "macrophage_monocyte", "endothelial")) {
  cells <- WhichCells(combined, idents = compartment)
  if (length(cells) < 50) next
  sub <- subset(combined, cells = cells)
  if (length(unique(sub$disease_state)) < 2) next
  Idents(sub) <- "disease_state"
  res <- FindMarkers(
    sub,
    ident.1 = cfg$analysis$disease_contrast$case,
    ident.2 = cfg$analysis$disease_contrast$reference,
    test.use = "wilcox",
    logfc.threshold = 0.1,
    min.pct = 0.1
  ) |>
    tibble::rownames_to_column("gene") |>
    mutate(compartment = compartment, contrast = "cirrhotic_vs_healthy_cell_level")
  de_results[[compartment]] <- res
}
de_tbl <- bind_rows(de_results)
safe_write(de_tbl, file.path(cfg$paths$tables_dir, "compartment_de_cell_level_exploratory.csv"))

avg <- AverageExpression(combined, group.by = c("disease_state", "compartment_call"), assays = "RNA", layer = "data")$RNA
avg_tbl <- as.data.frame(as.matrix(avg)) |> tibble::rownames_to_column("gene")
safe_write(avg_tbl, file.path(cfg$paths$tables_dir, "average_expression_by_disease_compartment.csv"))

emb <- Embeddings(combined, "umap") |>
  as.data.frame() |>
  tibble::rownames_to_column("cell") |>
  left_join(combined@meta.data |> tibble::rownames_to_column("cell"), by = "cell")
safe_write(emb, file.path(cfg$paths$dashboard_data_dir, "umap_metadata.csv"))

saveRDS(combined, file.path(cfg$paths$processed_dir, "gse136103_compact_seurat.rds"))
message("Seurat compact analysis complete.")
