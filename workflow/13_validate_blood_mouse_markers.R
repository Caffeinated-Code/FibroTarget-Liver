suppressPackageStartupMessages({
  library(yaml)
  library(readr)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(Seurat)
  library(Matrix)
  library(babelgene)
})

source("src/R/utils.R")

args <- commandArgs(trailingOnly = TRUE)
get_arg <- function(flag, default = NULL) {
  i <- match(flag, args)
  if (is.na(i) || i == length(args)) default else args[[i + 1]]
}

cfg <- yaml::read_yaml(get_arg("--config", "config/project.yaml"))
archive <- cfg$datasets$primary$archive
manifest_path <- file.path(cfg$paths$metadata_dir, "gse136103_sample_manifest.csv")
extract_dir <- file.path("data", "processed", "secondary_validation_extract")
if (!file.exists(archive)) stop("Missing primary GEO archive: ", archive)
if (!file.exists(manifest_path)) stop("Missing sample manifest: ", manifest_path)

manifest <- read_csv(manifest_path, show_col_types = FALSE)

candidate_panel <- tibble(
  human_gene = c(
    "SMOC2", "TIMP1", "COL1A1", "COL3A1", "PDGFRA", "PDGFRB",
    "PLVAP", "ACKR1", "TREM2", "CD9", "SPP1", "GPNMB",
    "LST1", "C1QA", "C1QB", "C1QC"
  ),
  validation_role = c(
    "secreted_stromal_biomarker", "secreted_matrix_remodeling",
    "fibrosis_burden", "fibrosis_burden", "stromal_receptor_target",
    "stromal_receptor_target", "scar_endothelial_marker",
    "scar_endothelial_marker", "macrophage_state_marker",
    "macrophage_state_marker", "macrophage_state_marker",
    "macrophage_state_marker", "circulating_myeloid_context",
    "macrophage_complement_context", "macrophage_complement_context",
    "macrophage_complement_context"
  )
)

make_object <- function(sample_rows, project) {
  objects <- lapply(seq_len(nrow(sample_rows)), function(i) {
    row <- sample_rows[i, ]
    mat <- read_10x_from_tar(archive, row, extract_dir)
    obj <- CreateSeuratObject(
      counts = mat,
      project = project,
      min.cells = 0,
      min.features = 0
    )
    obj$gsm <- row$gsm
    obj$sample_id <- row$sample_token
    obj$species <- row$species
    obj$tissue <- row$tissue
    obj$disease_state <- row$disease_state
    obj$donor <- row$donor
    obj$fraction <- row$fraction
    obj[["percent.mt"]] <- PercentageFeatureSet(obj, pattern = "^(MT-|mt-)")
    obj
  })
  if (length(objects) == 1) {
    merged <- objects[[1]]
  } else {
    merged <- merge(objects[[1]], y = objects[-1], project = project)
  }
  merged <- NormalizeData(merged, verbose = FALSE)
  if (exists("JoinLayers", where = asNamespace("SeuratObject"), mode = "function")) {
    merged <- SeuratObject::JoinLayers(merged)
  }
  merged
}

summarize_marker_expression <- function(object, genes, gene_label = "gene") {
  data <- GetAssayData(object, assay = "RNA", layer = "data")
  present <- intersect(genes, rownames(data))
  if (length(present) == 0) {
    return(tibble())
  }
  meta <- object@meta.data |>
    tibble::rownames_to_column("cell_id") |>
    select(cell_id, sample_id, disease_state, tissue, species)

  expr <- as.matrix(data[present, , drop = FALSE])
  out <- lapply(present, function(gene) {
    values <- expr[gene, ]
    tibble(cell_id = colnames(expr), expression = as.numeric(values)) |>
      left_join(meta, by = "cell_id") |>
      group_by(sample_id, disease_state, tissue, species) |>
      summarise(
        cells = n(),
        mean_log_normalized_expression = mean(expression),
        pct_detected = mean(expression > 0) * 100,
        .groups = "drop"
      ) |>
      mutate("{gene_label}" := gene, .before = sample_id)
  })
  bind_rows(out)
}

blood_rows <- manifest |>
  filter(species == "Homo sapiens", tissue == "blood")
mouse_rows <- manifest |>
  filter(species == "Mus musculus", tissue == "mouse_liver")

blood_obj <- make_object(blood_rows, "GSE136103_blood_validation")
blood_qc <- blood_obj@meta.data |>
  tibble::rownames_to_column("cell_id") |>
  group_by(sample_id, tissue, disease_state) |>
  summarise(
    cells = n(),
    median_detected_genes = median(nFeature_RNA),
    median_umis = median(nCount_RNA),
    median_percent_mito = median(percent.mt),
    .groups = "drop"
  )
safe_write(blood_qc, file.path(cfg$paths$tables_dir, "gse136103_blood_qc_summary.csv"))

blood_expr <- summarize_marker_expression(blood_obj, candidate_panel$human_gene, "gene") |>
  left_join(candidate_panel, by = c("gene" = "human_gene")) |>
  arrange(validation_role, gene, sample_id)
safe_write(blood_expr, file.path(cfg$paths$tables_dir, "gse136103_blood_candidate_marker_summary.csv"))

blood_role_summary <- blood_expr |>
  group_by(validation_role, gene) |>
  summarise(
    samples = n_distinct(sample_id),
    mean_log_normalized_expression = mean(mean_log_normalized_expression),
    mean_pct_detected = mean(pct_detected),
    .groups = "drop"
  ) |>
  arrange(desc(mean_log_normalized_expression))
safe_write(blood_role_summary, file.path(cfg$paths$tables_dir, "gse136103_blood_candidate_marker_role_summary.csv"))

blood_plot <- blood_role_summary |>
  mutate(gene = factor(gene, levels = rev(unique(gene)))) |>
  ggplot(aes("blood", gene, fill = mean_log_normalized_expression)) +
  geom_tile(color = "white", linewidth = 0.3) +
  geom_text(aes(label = sprintf("%.2f", mean_log_normalized_expression)), size = 3) +
  scale_fill_gradient(low = "#F7FCF0", high = "#238B45") +
  labs(
    title = "Human blood specificity check",
    subtitle = "Mean expression across four GSE136103 blood libraries",
    x = NULL,
    y = NULL,
    fill = "mean log-normalized expression"
  ) +
  theme_project() +
  theme(axis.text.x = element_text(face = "bold"))
save_plot(blood_plot, file.path(cfg$paths$figures_dir, "gse136103_blood_candidate_marker_heatmap.png"), 6, 6.5)

mouse_obj <- make_object(mouse_rows, "GSE136103_mouse_validation")
mouse_qc <- mouse_obj@meta.data |>
  tibble::rownames_to_column("cell_id") |>
  group_by(sample_id, tissue, disease_state) |>
  summarise(
    cells = n(),
    median_detected_genes = median(nFeature_RNA),
    median_umis = median(nCount_RNA),
    median_percent_mito = median(percent.mt),
    .groups = "drop"
  )
safe_write(mouse_qc, file.path(cfg$paths$tables_dir, "gse136103_mouse_qc_summary.csv"))

ortholog_map <- babelgene::orthologs(candidate_panel$human_gene, species = "mouse") |>
  as_tibble() |>
  select(human_gene = human_symbol, mouse_gene = symbol, mouse_ensembl = ensembl, support_n) |>
  arrange(human_gene, desc(support_n)) |>
  group_by(human_gene) |>
  slice_head(n = 1) |>
  ungroup() |>
  left_join(candidate_panel, by = "human_gene")
safe_write(ortholog_map, file.path(cfg$paths$tables_dir, "gse136103_mouse_candidate_ortholog_map.csv"))

mouse_expr <- summarize_marker_expression(mouse_obj, ortholog_map$mouse_gene, "mouse_gene") |>
  left_join(ortholog_map, by = "mouse_gene") |>
  arrange(validation_role, human_gene, disease_state)
safe_write(mouse_expr, file.path(cfg$paths$tables_dir, "gse136103_mouse_candidate_ortholog_expression.csv"))

mouse_summary <- mouse_expr |>
  select(human_gene, mouse_gene, validation_role, disease_state, mean_log_normalized_expression, pct_detected) |>
  pivot_wider(
    names_from = disease_state,
    values_from = c(mean_log_normalized_expression, pct_detected),
    values_fill = 0
  ) |>
  mutate(
    fibrotic_vs_healthy_delta = mean_log_normalized_expression_fibrotic - mean_log_normalized_expression_healthy,
    pct_detected_delta = pct_detected_fibrotic - pct_detected_healthy,
    interpretation = case_when(
      fibrotic_vs_healthy_delta > 0.25 ~ "higher in fibrotic mouse liver",
      fibrotic_vs_healthy_delta < -0.25 ~ "lower in fibrotic mouse liver",
      TRUE ~ "similar between mouse liver samples"
    )
  ) |>
  arrange(desc(fibrotic_vs_healthy_delta))
safe_write(mouse_summary, file.path(cfg$paths$tables_dir, "gse136103_mouse_candidate_ortholog_summary.csv"))

mouse_plot <- mouse_expr |>
  mutate(
    human_gene = factor(human_gene, levels = rev(unique(mouse_summary$human_gene))),
    disease_state = factor(disease_state, levels = c("healthy", "fibrotic"))
  ) |>
  ggplot(aes(disease_state, human_gene, fill = mean_log_normalized_expression)) +
  geom_tile(color = "white", linewidth = 0.3) +
  geom_text(aes(label = sprintf("%.2f", mean_log_normalized_expression)), size = 3) +
  scale_fill_gradient(low = "#F7FBFF", high = "#2166AC") +
  labs(
    title = "Mouse liver ortholog check",
    subtitle = "Directionality only: one healthy and one fibrotic mouse sample",
    x = NULL,
    y = NULL,
    fill = "mean log-normalized expression"
  ) +
  theme_project()
save_plot(mouse_plot, file.path(cfg$paths$figures_dir, "gse136103_mouse_candidate_ortholog_heatmap.png"), 7, 6.5)

secondary_summary <- bind_rows(
  tibble(
    validation_layer = "human_blood",
    samples = n_distinct(blood_rows$sample_token),
    cells = ncol(blood_obj),
    role = "Checks whether candidate markers also appear in circulating immune cells or remain liver-niche biased.",
    main_caveat = "Blood libraries do not define liver fibrosis state and are not used in the primary disease contrast."
  ),
  tibble(
    validation_layer = "mouse_liver",
    samples = n_distinct(mouse_rows$sample_token),
    cells = ncol(mouse_obj),
    role = "Checks ortholog presence and fibrotic versus healthy directionality for preclinical model relevance.",
    main_caveat = "Only one healthy and one fibrotic mouse sample are available, so this is a conservation screen, not inferential DE."
  )
)
safe_write(secondary_summary, file.path(cfg$paths$tables_dir, "gse136103_secondary_validation_summary.csv"))

message("Blood and mouse marker validation complete.")
