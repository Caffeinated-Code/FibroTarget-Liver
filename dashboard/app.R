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

ui <- fluidPage(
  titlePanel("Human Liver Fibrosis Single-Cell Target Discovery"),
  sidebarLayout(
    sidebarPanel(
      selectInput("color_by", "UMAP color", choices = c("disease_state", "compartment_call", "donor", "fraction"), selected = "compartment_call"),
      selectInput("compartment", "DE compartment", choices = sort(unique(de$compartment))),
      width = 3
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("UMAP", plotlyOutput("umap_plot", height = 650)),
        tabPanel("Candidates", DTOutput("candidate_table")),
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
