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
qc <- read_dash("qc_summary.csv")
pseudobulk <- if (file.exists(file.path(data_dir, "pseudobulk_priority_gene_de.csv"))) read_dash("pseudobulk_priority_gene_de.csv") else tibble()
hsc_validation <- if (file.exists(file.path(data_dir, "gse244832_hsc_candidate_validation.csv"))) read_dash("gse244832_hsc_candidate_validation.csv") else tibble()
refined_clusters <- if (file.exists(file.path(data_dir, "refined_cluster_annotations.csv"))) read_dash("refined_cluster_annotations.csv") else tibble()

color_choices <- intersect(c("disease_state", "refined_cell_state", "reference_label", "compartment_call", "donor", "fraction"), colnames(umap))

ui <- fluidPage(
  titlePanel("Human Liver Fibrosis Single-Cell Target Discovery"),
  sidebarLayout(
    sidebarPanel(
      selectInput("color_by", "UMAP color", choices = color_choices, selected = if ("refined_cell_state" %in% color_choices) "refined_cell_state" else "compartment_call"),
      selectInput("compartment", "DE compartment", choices = sort(unique(de$compartment))),
      width = 3
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("UMAP", plotlyOutput("umap_plot", height = 650)),
        tabPanel("Candidates", DTOutput("candidate_table")),
        tabPanel("Pseudobulk DE", DTOutput("pseudobulk_table")),
        tabPanel("GSE244832 HSC Validation", DTOutput("hsc_validation_table")),
        tabPanel("Reference Labels", DTOutput("refined_cluster_table")),
        tabPanel("Differential Expression", DTOutput("de_table")),
        tabPanel("Pathways", DTOutput("pathway_table")),
        tabPanel("QC", DTOutput("qc_table"))
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

  output$candidate_table <- renderDT({
    datatable(candidates, filter = "top", options = list(pageLength = 15, scrollX = TRUE))
  })

  output$pseudobulk_table <- renderDT({
    datatable(pseudobulk, filter = "top", options = list(pageLength = 20, scrollX = TRUE))
  })

  output$hsc_validation_table <- renderDT({
    datatable(hsc_validation, filter = "top", options = list(pageLength = 20, scrollX = TRUE))
  })

  output$refined_cluster_table <- renderDT({
    datatable(refined_clusters, filter = "top", options = list(pageLength = 20, scrollX = TRUE))
  })

  output$de_table <- renderDT({
    de |>
      filter(compartment == input$compartment) |>
      arrange(p_val_adj) |>
      datatable(filter = "top", options = list(pageLength = 20, scrollX = TRUE))
  })

  output$pathway_table <- renderDT({
    datatable(pathways, filter = "top", options = list(pageLength = 20, scrollX = TRUE))
  })

  output$qc_table <- renderDT({
    datatable(qc, filter = "top", options = list(pageLength = 20, scrollX = TRUE))
  })
}

shinyApp(ui, server)
