suppressPackageStartupMessages({
  library(shiny)
  library(DT)
  library(plotly)
  library(readr)
  library(dplyr)
  library(ggplot2)
})

data_dir <- if (file.exists(file.path(getwd(), "data", "umap_metadata.csv"))) {
  file.path(getwd(), "data")
} else if (file.exists(file.path(getwd(), "dashboard", "data", "umap_metadata.csv"))) {
  file.path(getwd(), "dashboard", "data")
} else {
  stop("Could not find dashboard/data/umap_metadata.csv. Run from the repo root or dashboard directory.")
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

cluster_composition <- umap |>
  mutate(cluster_key = as.character(seurat_clusters)) |>
  group_by(cluster_key) |>
  summarise(
    cluster_cells = n(),
    cluster_composition_pct = 100 * n() / nrow(umap),
    healthy_pct = 100 * sum(disease_state == "healthy", na.rm = TRUE) / n(),
    cirrhotic_pct = 100 * sum(disease_state == "cirrhotic", na.rm = TRUE) / n(),
    donors = n_distinct(donor),
    .groups = "drop"
  )

refined_clusters <- refined_clusters |>
  mutate(cluster_key = as.character(seurat_cluster)) |>
  left_join(cluster_composition, by = "cluster_key") |>
  select(
    seurat_cluster,
    cluster_cells,
    cluster_composition_pct,
    healthy_pct,
    cirrhotic_pct,
    donors,
    refined_cell_state,
    reference_label,
    annotation_lineage,
    compartment_call,
    canonical_state,
    correlation,
    reference_confidence
  )

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

total_candidates <- nrow(candidates)
top_candidate <- candidates |> arrange(rank) |> slice_head(n = 1)
top_candidate_label <- if (nrow(top_candidate) > 0) top_candidate$gene[[1]] else "NA"
human_liver_cells <- nrow(umap)
required_compartments <- umap |>
  filter(compartment_call %in% c("mesenchymal_HSC_myofibroblast", "macrophage_monocyte", "endothelial")) |>
  distinct(compartment_call) |>
  nrow()

metric_card <- function(label, value, note = NULL) {
  tags$div(
    class = "metric-card",
    tags$div(class = "metric-label", label),
    tags$div(class = "metric-value", value),
    if (!is.null(note)) tags$div(class = "metric-note", note)
  )
}

ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      body {
        background: #f6f7f9;
        color: #1f2933;
      }
      .container-fluid {
        max-width: 1480px;
      }
      .app-header {
        background: #ffffff;
        border-bottom: 1px solid #dde3ea;
        margin: 0 -15px 18px -15px;
        padding: 20px 28px 18px 28px;
      }
      .app-kicker {
        color: #52616f;
        font-size: 12px;
        font-weight: 700;
        letter-spacing: 0.08em;
        text-transform: uppercase;
      }
      .app-title {
        font-size: 28px;
        font-weight: 700;
        line-height: 1.15;
        margin: 4px 0 6px 0;
      }
      .app-subtitle {
        color: #52616f;
        font-size: 15px;
        max-width: 920px;
      }
      .metric-row {
        display: grid;
        gap: 12px;
        grid-template-columns: repeat(4, minmax(160px, 1fr));
        margin-bottom: 16px;
      }
      .metric-card {
        background: #ffffff;
        border: 1px solid #dde3ea;
        border-radius: 8px;
        padding: 13px 15px;
      }
      .metric-label {
        color: #52616f;
        font-size: 12px;
        font-weight: 700;
        text-transform: uppercase;
      }
      .metric-value {
        color: #111827;
        font-size: 26px;
        font-weight: 750;
        line-height: 1.25;
        margin-top: 3px;
      }
      .metric-note {
        color: #637381;
        font-size: 12px;
        margin-top: 2px;
      }
      .sidebar-panel {
        background: #ffffff;
        border: 1px solid #dde3ea;
        border-radius: 8px;
        padding: 16px;
      }
      .well {
        background: transparent;
        border: 0;
        box-shadow: none;
        padding: 0;
      }
      .main-panel {
        background: #ffffff;
        border: 1px solid #dde3ea;
        border-radius: 8px;
        padding: 14px;
      }
      .nav-tabs > li > a {
        color: #334e68;
        font-weight: 600;
      }
      .nav-tabs > li.active > a,
      .nav-tabs > li.active > a:focus,
      .nav-tabs > li.active > a:hover {
        color: #111827;
        border-top: 3px solid #2f6f73;
      }
      label {
        color: #334e68;
        font-weight: 700;
      }
      table.dataTable tbody td {
        vertical-align: top;
      }
      .table-controls {
        display: grid;
        gap: 12px;
        grid-template-columns: repeat(2, minmax(220px, 1fr));
        margin-bottom: 12px;
      }
      @media (max-width: 900px) {
        .metric-row {
          grid-template-columns: repeat(2, minmax(140px, 1fr));
        }
        .table-controls {
          grid-template-columns: 1fr;
        }
      }
      @media (max-width: 560px) {
        .metric-row {
          grid-template-columns: 1fr;
        }
        .app-title {
          font-size: 23px;
        }
      }
    "))
  ),
  tags$div(
    class = "app-header",
    tags$div(class = "app-kicker", "FibroTarget-Liver"),
    tags$div(class = "app-title", "Human Liver Fibrosis Target Discovery"),
    tags$div(class = "app-subtitle", "GSE136103 single-cell discovery with candidate scoring, donor-aware evidence, validation summaries, pathway results, and QC review.")
  ),
  tags$div(
    class = "metric-row",
    metric_card("Cells in UMAP", format(human_liver_cells, big.mark = ","), "human liver discovery view"),
    metric_card("Candidate shortlist", total_candidates, "ranked translational table"),
    metric_card("Top ranked gene", top_candidate_label, "current score leader"),
    metric_card("Required compartments", required_compartments, "stromal, myeloid, endothelial")
  ),
  sidebarLayout(
    sidebarPanel(
      class = "sidebar-panel",
      selectInput("color_by", "UMAP color", choices = color_choices, selected = if ("refined_cell_state" %in% color_choices) "refined_cell_state" else "compartment_call"),
      width = 3
    ),
    mainPanel(
      class = "main-panel",
      tabsetPanel(
        tabPanel("Overview", plotlyOutput("umap_plot", height = 590)),
        tabPanel(
          "Candidates",
          tags$div(
            class = "table-controls",
            selectInput("candidate_class", "Candidate class", choices = c("All", class_choices), selected = "All"),
            selectInput("clinical_use_case", "Clinical use case", choices = c("All", use_case_choices), selected = "All")
          ),
          DTOutput("candidate_table")
        ),
        tabPanel("Scoring", DTOutput("score_component_table"), tags$hr(), DTOutput("score_method_table")),
        tabPanel("Pseudobulk", DTOutput("pseudobulk_table")),
        tabPanel("HSC Validation", DTOutput("hsc_validation_table")),
        tabPanel("Blood And Mouse", DTOutput("blood_validation_table"), tags$hr(), DTOutput("mouse_validation_table")),
        tabPanel("Reference Labels", DTOutput("refined_cluster_table")),
        tabPanel(
          "Cell-Level DE",
          tags$div(
            class = "table-controls",
            selectInput("compartment", "DE compartment", choices = sort(unique(de$compartment)))
          ),
          DTOutput("de_table")
        ),
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
    datatable(refined_clusters, filter = "top", options = dt_opts) |>
      formatStyle(
        "compartment_call",
        backgroundColor = styleEqual(names(compartment_palette), unname(compartment_palette)),
        color = "white"
      ) |>
      formatRound(c("cluster_composition_pct", "healthy_pct", "cirrhotic_pct", "correlation"), digits = 2)
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
