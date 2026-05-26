suppressPackageStartupMessages({
  library(yaml)
  library(dplyr)
  library(readr)
  library(ggplot2)
  library(stringr)
  library(tidyr)
})

source("src/R/utils.R")

args <- commandArgs(trailingOnly = TRUE)
get_arg <- function(flag, default = NULL) {
  i <- match(flag, args)
  if (is.na(i) || i == length(args)) default else args[[i + 1]]
}

cfg <- yaml::read_yaml(get_arg("--config", "config/project.yaml"))

java_home <- Sys.getenv("JAVA_HOME")
openjdk_home <- "/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home"
if (java_home == "" && dir.exists(openjdk_home)) {
  Sys.setenv(JAVA_HOME = openjdk_home)
  Sys.setenv(PATH = paste(file.path(openjdk_home, "bin"), Sys.getenv("PATH"), sep = .Platform$path.sep))
}

if (!requireNamespace("pathfindR", quietly = TRUE)) {
  stop("pathfindR is not installed. Run renv::restore() or install pathfindR with Java available.")
}

de_path <- file.path(cfg$paths$tables_dir, "pseudobulk_de_by_refined_state.csv")
if (!file.exists(de_path)) stop("Missing pseudobulk DE table. Run make pseudobulk first.")

de <- read_csv(de_path, show_col_types = FALSE)

state_map <- tibble::tribble(
  ~refined_cell_state, ~mechanism_compartment, ~label,
  "HSC_myofibroblast_reference_supported", "mesenchymal_HSC_myofibroblast", "HSC/myofibroblast",
  "endothelial_reference_supported", "endothelial", "Endothelial",
  "macrophage_reference_supported", "macrophage_monocyte", "Macrophage reference-supported",
  "macrophage_marker_supported", "macrophage_monocyte", "Macrophage marker-supported"
)

run_summary <- list()
all_results <- list()
work_root <- file.path(tempdir(), paste0("fibrotarget_pathfindr_", format(Sys.time(), "%Y%m%d%H%M%S")))
dir.create(work_root, recursive = TRUE, showWarnings = FALSE)

for (i in seq_len(nrow(state_map))) {
  state <- state_map$refined_cell_state[[i]]
  input <- de |>
    filter(refined_cell_state == state, log2FC > 0, p_adj < 0.05) |>
    transmute(Gene.symbol = gene, logFC = log2FC, adj.P.Val = p_adj) |>
    distinct(Gene.symbol, .keep_all = TRUE) |>
    as.data.frame()

  n_input <- nrow(input)
  if (n_input < 10) {
    run_summary[[state]] <- tibble::tibble(
      refined_cell_state = state,
      mechanism_compartment = state_map$mechanism_compartment[[i]],
      label = state_map$label[[i]],
      n_input_genes = n_input,
      status = "not_run",
      reason = "Fewer than 10 cirrhosis-up donor-level pseudobulk genes at FDR < 0.05.",
      gene_sets = "Reactome",
      p_val_threshold = 0.05,
      enrichment_threshold = 0.1,
      grSubNum = 100
    )
    next
  }

  out_dir <- file.path(work_root, make.names(state))
  result <- tryCatch(
    pathfindR::run_pathfindR(
      input,
      gene_sets = "Reactome",
      p_val_threshold = 0.05,
      enrichment_threshold = 0.1,
      output_dir = out_dir,
      plot_enrichment_chart = FALSE,
      list_active_snw_genes = TRUE,
      grSubNum = 100,
      grMaxDepth = 1,
      grSearchDepth = 1
    ),
    error = function(e) e
  )

  if (inherits(result, "error")) {
    run_summary[[state]] <- tibble::tibble(
      refined_cell_state = state,
      mechanism_compartment = state_map$mechanism_compartment[[i]],
      label = state_map$label[[i]],
      n_input_genes = n_input,
      status = "failed",
      reason = conditionMessage(result),
      gene_sets = "Reactome",
      p_val_threshold = 0.05,
      enrichment_threshold = 0.1,
      grSubNum = 100
    )
    next
  }

  result <- as_tibble(result) |>
    mutate(
      refined_cell_state = state,
      mechanism_compartment = state_map$mechanism_compartment[[i]],
      label = state_map$label[[i]],
      n_input_genes = n_input,
      n_up_genes = if_else(is.na(Up_regulated) | Up_regulated == "", 0L, str_count(Up_regulated, ",") + 1L),
      n_down_genes = if_else(is.na(Down_regulated) | Down_regulated == "", 0L, str_count(Down_regulated, ",") + 1L)
    ) |>
    relocate(refined_cell_state, mechanism_compartment, label, n_input_genes)

  all_results[[state]] <- result
  run_summary[[state]] <- tibble::tibble(
    refined_cell_state = state,
    mechanism_compartment = state_map$mechanism_compartment[[i]],
    label = state_map$label[[i]],
    n_input_genes = n_input,
    status = "complete",
    reason = paste0(nrow(result), " enriched Reactome terms returned."),
    gene_sets = "Reactome",
    p_val_threshold = 0.05,
    enrichment_threshold = 0.1,
    grSubNum = 100
  )
}

pathfindr_results <- bind_rows(all_results)
pathfindr_summary <- bind_rows(run_summary)

safe_write(pathfindr_summary, file.path(cfg$paths$tables_dir, "pathfindr_pseudobulk_run_summary.csv"))
safe_write(pathfindr_results, file.path(cfg$paths$tables_dir, "pathfindr_pseudobulk_reactome_enrichment.csv"))

if (nrow(pathfindr_results) > 0) {
  top_terms <- pathfindr_results |>
    group_by(label) |>
    arrange(lowest_p, desc(Fold_Enrichment), .by_group = TRUE) |>
    slice_head(n = 8) |>
    ungroup() |>
    mutate(
      term_short = stringr::str_trunc(Term_Description, 64),
      term_short = reorder(term_short, -log10(pmax(lowest_p, 1e-300)))
    )

  p_bar <- top_terms |>
    ggplot(aes(-log10(pmax(lowest_p, 1e-300)), term_short, fill = label)) +
    geom_col(width = 0.72) +
    facet_wrap(~label, scales = "free_y") +
    labs(
      title = "pathfindR Reactome enrichment from donor-level pseudobulk DE",
      subtitle = "Active-subnetwork search on cirrhosis-up genes at FDR < 0.05",
      x = "-log10(lowest enrichment p-value)",
      y = NULL,
      fill = "Pseudobulk state"
    ) +
    theme_project() +
    theme(legend.position = "bottom")
  save_plot(p_bar, file.path(cfg$paths$figures_dir, "pathfindr_pseudobulk_reactome_barplot.png"), 11, 7)

  p_dot <- top_terms |>
    ggplot(aes(Fold_Enrichment, term_short, size = n_up_genes, color = -log10(pmax(lowest_p, 1e-300)))) +
    geom_point(alpha = 0.9) +
    facet_wrap(~label, scales = "free_y") +
    scale_color_viridis_c(option = "C") +
    labs(
      title = "pathfindR active-subnetwork terms and supporting genes",
      subtitle = "Dot size is the number of up-regulated pseudobulk genes in the term",
      x = "Fold enrichment",
      y = NULL,
      color = "-log10(p)",
      size = "Up genes"
    ) +
    theme_project() +
    theme(legend.position = "bottom")
  save_plot(p_dot, file.path(cfg$paths$figures_dir, "pathfindr_pseudobulk_reactome_dotplot.png"), 11, 7)
} else {
  placeholder <- ggplot(pathfindr_summary, aes(label, n_input_genes, fill = status)) +
    geom_col() +
    coord_flip() +
    labs(
      title = "pathfindR pseudobulk analysis was not run",
      subtitle = "No refined state had enough cirrhosis-up donor-level genes at FDR < 0.05",
      x = NULL,
      y = "Input genes"
    ) +
    theme_project()
  save_plot(placeholder, file.path(cfg$paths$figures_dir, "pathfindr_pseudobulk_reactome_barplot.png"), 9, 5)
  save_plot(placeholder, file.path(cfg$paths$figures_dir, "pathfindr_pseudobulk_reactome_dotplot.png"), 9, 5)
}

message("pathfindR pseudobulk mechanism analysis complete.")
