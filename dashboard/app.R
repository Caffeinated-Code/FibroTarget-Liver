suppressPackageStartupMessages({
  library(shiny)
  library(DT)
  library(plotly)
  library(readr)
  library(dplyr)
  library(ggplot2)
})

data_dir <- if (dir.exists(file.path(getwd(), "data"))) {
  file.path(getwd(), "data")
} else {
  file.path(getwd(), "dashboard", "data")
}
read_dash <- function(name) read_csv(file.path(data_dir, name), show_col_types = FALSE)

umap <- read_dash("umap_metadata.csv")
candidates <- read_dash("ranked_candidates.csv")
de <- read_dash("de_results.csv")
pathways <- read_dash("pathway_enrichment.csv")
pathfindr_terms <- if (file.exists(file.path(data_dir, "pathfindr_pseudobulk_reactome_enrichment.csv"))) read_dash("pathfindr_pseudobulk_reactome_enrichment.csv") else tibble()
pathfindr_summary <- if (file.exists(file.path(data_dir, "pathfindr_pseudobulk_run_summary.csv"))) read_dash("pathfindr_pseudobulk_run_summary.csv") else tibble()
qc <- read_dash("qc_summary.csv")
qc_decisions <- if (file.exists(file.path(data_dir, "qc_decision_log.csv"))) read_dash("qc_decision_log.csv") else tibble()
qc_filter <- if (file.exists(file.path(data_dir, "qc_filter_summary.csv"))) read_dash("qc_filter_summary.csv") else tibble()
qc_metrics <- if (file.exists(file.path(data_dir, "qc_metric_summary.csv"))) read_dash("qc_metric_summary.csv") else tibble()
pseudobulk <- if (file.exists(file.path(data_dir, "pseudobulk_priority_gene_de.csv"))) read_dash("pseudobulk_priority_gene_de.csv") else tibble()
hsc_validation <- if (file.exists(file.path(data_dir, "gse244832_hsc_candidate_validation.csv"))) read_dash("gse244832_hsc_candidate_validation.csv") else tibble()
refined_clusters <- if (file.exists(file.path(data_dir, "refined_cluster_annotations.csv"))) read_dash("refined_cluster_annotations.csv") else tibble()
score_components <- if (file.exists(file.path(data_dir, "target_prioritization_scoring_components.csv"))) read_dash("target_prioritization_scoring_components.csv") else tibble()
score_method <- if (file.exists(file.path(data_dir, "target_prioritization_scoring_method.csv"))) read_dash("target_prioritization_scoring_method.csv") else tibble()
blood_validation <- if (file.exists(file.path(data_dir, "gse136103_blood_candidate_marker_role_summary.csv"))) read_dash("gse136103_blood_candidate_marker_role_summary.csv") else tibble()
mouse_validation <- if (file.exists(file.path(data_dir, "gse136103_mouse_candidate_ortholog_summary.csv"))) read_dash("gse136103_mouse_candidate_ortholog_summary.csv") else tibble()

color_choices <- intersect(c("disease_state", "refined_cell_state", "reference_label", "compartment_call", "donor", "fraction"), colnames(umap))
class_choices <- sort(unique(candidates$candidate_class))
use_case_choices <- sort(unique(candidates$clinical_use_case))
class_palette <- c(
  "diagnostic biomarker" = "#2166AC",
  "pharmacodynamic biomarker" = "#1B9E77",
  "therapeutic target" = "#B2182B",
  "future validation marker" = "#756BB1",
  "mechanistic marker" = "#756BB1"
)
compartment_palette <- c(
  "mesenchymal_HSC_myofibroblast" = "#8C510A",
  "macrophage_monocyte" = "#1B9E77",
  "endothelial" = "#2166AC",
  "other_or_unresolved" = "#6B7280"
)

dt_opts <- list(pageLength = 15, scrollX = TRUE, autoWidth = TRUE)

ui <- fluidPage(
  titlePanel("Human Liver Fibrosis Single-Cell Target Discovery"),
  sidebarLayout(
    sidebarPanel(
      selectInput("color_by", "UMAP color", choices = color_choices, selected = if ("refined_cell_state" %in% color_choices) "refined_cell_state" else "compartment_call"),
      selectInput("compartment", "DE compartment", choices = sort(unique(de$compartment))),
      selectInput("candidate_class", "Candidate class", choices = c("All", class_choices), selected = "All"),
      selectInput("clinical_use_case", "Clinical use case", choices = c("All", use_case_choices), selected = "All"),
      width = 3
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("UMAP", plotlyOutput("umap_plot", height = 650)),
        tabPanel("Candidates", DTOutput("candidate_table")),
        tabPanel("Scoring", DTOutput("score_component_table"), tags$hr(), DTOutput("score_method_table")),
        tabPanel("Pseudobulk DE", DTOutput("pseudobulk_table")),
        tabPanel("GSE244832 HSC Validation", DTOutput("hsc_validation_table")),
        tabPanel("Blood And Mouse Validation", DTOutput("blood_validation_table"), DTOutput("mouse_validation_table")),
        tabPanel("Reference Labels", DTOutput("refined_cluster_table")),
        tabPanel("Differential Expression", DTOutput("de_table")),
        tabPanel("Pathways", DTOutput("pathway_table")),
        tabPanel("pathfindR", DTOutput("pathfindr_summary_table"), tags$hr(), DTOutput("pathfindr_table")),
        tabPanel("QC", DTOutput("qc_decision_table"), tags$hr(), DTOutput("qc_filter_table"), tags$hr(), DTOutput("qc_metric_table"), tags$hr(), DTOutput("qc_table"))
      )
    )
  )
)

server <- function(input, output, session) {
  output$umap_plot <- renderPlotly({
    p <- ggplot(umap, aes(.data$umap_1, .data$umap_2, color = .data[[input$color_by]], text = paste(cell, disease_state, compartment_call, sep = "<br>"))) +
      geom_point(size = 0.35, alpha = 0.75) +
      theme_minimal() +
      labs(x = "UMAP 1", y = "UMAP 2", color = input$color_by)
    ggplotly(p, tooltip = "text")
  })

  candidate_filtered <- reactive({
    out <- candidates
    if (!is.null(input$candidate_class) && input$candidate_class != "All") {
      out <- out |> filter(candidate_class == input$candidate_class)
    }
    if (!is.null(input$clinical_use_case) && input$clinical_use_case != "All") {
      out <- out |> filter(clinical_use_case == input$clinical_use_case)
    }
    out
  })

  output$candidate_table <- renderDT({
    datatable(candidate_filtered(), filter = "top", options = dt_opts) |>
      formatStyle(
        "candidate_class",
        backgroundColor = styleEqual(names(class_palette), unname(class_palette)),
        color = "white",
        fontWeight = "bold"
      ) |>
      formatStyle(
        "compartment",
        backgroundColor = styleEqual(names(compartment_palette), unname(compartment_palette)),
        color = "white"
      ) |>
      formatRound(c("total_score", "avg_log2FC", "pseudobulk_log2FC"), digits = 2)
  })

  output$score_component_table <- renderDT({
    datatable(score_components, filter = "top", options = dt_opts) |>
      formatStyle(
        "candidate_class",
        backgroundColor = styleEqual(names(class_palette), unname(class_palette)),
        color = "white",
        fontWeight = "bold"
      ) |>
      formatRound(c("total_score", "disease_association_points", "donor_consistency_points", "specificity_points", "pathway_points", "external_validation_points"), digits = 1)
  })

  output$score_method_table <- renderDT({
    datatable(score_method, options = dt_opts)
  })

  output$pseudobulk_table <- renderDT({
    datatable(pseudobulk, filter = "top", options = dt_opts) |>
      formatRound(c("log2FC", "p_value", "p_adj"), digits = 3)
  })

  output$hsc_validation_table <- renderDT({
    datatable(hsc_validation, filter = "top", options = dt_opts) |>
      formatRound(c("weighted_pct_detected", "weighted_mean_norm", "steatohepatitis_vs_normal_delta", "whole_liver_mean_norm", "whole_liver_pct_detected"), digits = 2)
  })

  output$blood_validation_table <- renderDT({
    datatable(blood_validation, filter = "top", options = dt_opts) |>
      formatRound(c("mean_log_normalized_expression", "mean_pct_detected"), digits = 2)
  })

  output$mouse_validation_table <- renderDT({
    datatable(mouse_validation, filter = "top", options = dt_opts) |>
      formatRound(c("fibrotic_vs_healthy_delta", "pct_detected_delta"), digits = 2)
  })

  output$refined_cluster_table <- renderDT({
    datatable(refined_clusters, filter = "top", options = dt_opts)
  })

  output$de_table <- renderDT({
    de |>
      filter(compartment == input$compartment) |>
      arrange(p_val_adj) |>
      datatable(filter = "top", options = dt_opts) |>
      formatStyle(
        "compartment",
        backgroundColor = styleEqual(names(compartment_palette), unname(compartment_palette)),
        color = "white"
      ) |>
      formatRound(c("avg_log2FC", "p_val", "p_val_adj", "pct.1", "pct.2"), digits = 3)
  })

  output$pathway_table <- renderDT({
    datatable(pathways, filter = "top", options = dt_opts) |>
      formatStyle(
        "compartment",
        backgroundColor = styleEqual(names(compartment_palette), unname(compartment_palette)),
        color = "white"
      ) |>
      formatRound(c("p_value", "p_adj"), digits = 3)
  })

  output$pathfindr_summary_table <- renderDT({
    datatable(pathfindr_summary, filter = "top", options = dt_opts)
  })

  output$pathfindr_table <- renderDT({
    datatable(pathfindr_terms, filter = "top", options = dt_opts) |>
      formatStyle(
        "mechanism_compartment",
        backgroundColor = styleEqual(names(compartment_palette), unname(compartment_palette)),
        color = "white"
      ) |>
      formatRound(c("Fold_Enrichment", "lowest_p", "highest_p", "support"), digits = 3)
  })

  output$qc_decision_table <- renderDT({
    datatable(qc_decisions, filter = "top", options = dt_opts)
  })

  output$qc_filter_table <- renderDT({
    datatable(qc_filter, options = dt_opts) |>
      formatRound(c("pct_retained"), digits = 1)
  })

  output$qc_metric_table <- renderDT({
    datatable(qc_metrics, options = dt_opts) |>
      formatRound(colnames(qc_metrics)[vapply(qc_metrics, is.numeric, logical(1))], digits = 2)
  })

  output$qc_table <- renderDT({
    datatable(qc, filter = "top", options = dt_opts) |>
      formatStyle(
        "compartment_call",
        backgroundColor = styleEqual(names(compartment_palette), unname(compartment_palette)),
        color = "white"
      ) |>
      formatRound(c("median_genes", "median_umis", "median_percent_mt", "median_percent_ribo", "median_percent_hb", "median_log10_genes_per_umi"), digits = 2)
  })
}

shinyApp(ui, server)
