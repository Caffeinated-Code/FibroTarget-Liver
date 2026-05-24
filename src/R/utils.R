suppressPackageStartupMessages({
  library(Matrix)
  library(Seurat)
  library(dplyr)
  library(readr)
  library(ggplot2)
})

theme_project <- function() {
  theme_minimal(base_size = 11) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold", color = "#1F2933"),
      plot.subtitle = element_text(color = "#52606D"),
      axis.title = element_text(color = "#1F2933"),
      legend.title = element_text(face = "bold")
    )
}

read_10x_from_tar <- function(archive, sample_row, extract_dir) {
  sample_id <- sample_row$sample_token
  target_dir <- file.path(extract_dir, sample_id)
  dir.create(target_dir, recursive = TRUE, showWarnings = FALSE)

  members <- c(sample_row$barcodes, sample_row$genes, sample_row$matrix)
  utils::untar(archive, files = members, exdir = target_dir)

  matrix_path <- file.path(target_dir, sample_row$matrix)
  genes_path <- file.path(target_dir, sample_row$genes)
  barcodes_path <- file.path(target_dir, sample_row$barcodes)

  mat <- Matrix::readMM(gzfile(matrix_path))
  genes <- readr::read_tsv(gzfile(genes_path), col_names = FALSE, show_col_types = FALSE)
  barcodes <- readr::read_tsv(gzfile(barcodes_path), col_names = FALSE, show_col_types = FALSE)

  gene_names <- if (ncol(genes) >= 2) genes[[2]] else genes[[1]]
  gene_names <- make.unique(as.character(gene_names))
  cell_names <- paste(sample_id, as.character(barcodes[[1]]), sep = "_")

  rownames(mat) <- gene_names
  colnames(mat) <- cell_names
  mat
}

marker_score <- function(object, markers) {
  present <- intersect(markers, rownames(object))
  if (length(present) == 0) return(rep(NA_real_, ncol(object)))
  Matrix::colMeans(GetAssayData(object, assay = "RNA", slot = "data")[present, , drop = FALSE])
}

safe_write <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  readr::write_csv(x, path)
}

save_plot <- function(plot, path, width = 8, height = 5) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  ggsave(path, plot = plot, width = width, height = height, dpi = 300)
}

collapse_to_pseudobulk <- function(object, genes, group_cols) {
  counts <- GetAssayData(object, assay = "RNA", slot = "counts")
  meta <- object@meta.data
  genes <- intersect(genes, rownames(counts))
  key <- apply(meta[, group_cols, drop = FALSE], 1, paste, collapse = "|")
  groups <- split(seq_along(key), key)
  out <- lapply(groups, function(idx) Matrix::rowSums(counts[genes, idx, drop = FALSE]))
  mat <- do.call(cbind, out)
  rownames(mat) <- genes
  colnames(mat) <- names(groups)
  mat
}
