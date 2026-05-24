suppressPackageStartupMessages({
  library(yaml)
  library(dplyr)
  library(readr)
  library(ggplot2)
  library(msigdbr)
})

source("src/R/utils.R")

args <- commandArgs(trailingOnly = TRUE)
get_arg <- function(flag, default = NULL) {
  i <- match(flag, args)
  if (is.na(i) || i == length(args)) default else args[[i + 1]]
}

cfg <- yaml::read_yaml(get_arg("--config", "config/project.yaml"))
de_path <- file.path(cfg$paths$tables_dir, "compartment_de_cell_level_exploratory.csv")
if (!file.exists(de_path)) stop("Missing DE results. Run make analyze first.")
de <- read_csv(de_path, show_col_types = FALSE)

manual_evidence <- tibble::tribble(
  ~gene, ~intended_compartment, ~literature_context, ~translational_modality, ~model_conservation, ~risk_note, ~candidate_class,
  "TREM2", "macrophage_monocyte", "Scar-associated macrophage marker reported in human cirrhosis; also appears in MASH biomarker literature.", "surface receptor; biomarker and target biology", "mouse ortholog supports preclinical macrophage studies", "macrophage biology is context-dependent; target effect may not be liver-specific", "pharmacodynamic biomarker",
  "CD9", "macrophage_monocyte", "Reported with TREM2 in scar-associated macrophages.", "surface protein; cell-state biomarker", "conserved", "broad expression limits target specificity", "pharmacodynamic biomarker",
  "SPP1", "macrophage_monocyte", "Osteopontin is linked to inflammatory macrophage and fibrotic tissue programs.", "secreted protein", "conserved", "pleiotropic inflammatory biology", "mechanistic marker",
  "GPNMB", "macrophage_monocyte", "Disease-associated macrophage/repair-state marker in chronic tissue injury.", "surface/secreted-associated protein", "conserved", "not liver-specific", "pharmacodynamic biomarker",
  "PLVAP", "endothelial", "Reported scar-associated endothelial marker in human cirrhosis.", "surface-associated endothelial marker", "conserved", "vascular biology may create safety considerations", "diagnostic biomarker",
  "ACKR1", "endothelial", "Reported scar-associated endothelial marker in human cirrhosis.", "surface atypical chemokine receptor", "conserved with species differences", "vascular and immune trafficking roles require caution", "mechanistic marker",
  "VWF", "endothelial", "Endothelial activation and vascular remodeling marker.", "secreted/endothelial biomarker", "conserved", "broad vascular expression", "diagnostic biomarker",
  "COL1A1", "mesenchymal_HSC_myofibroblast", "Core collagen scar component.", "matrix biomarker", "conserved", "excellent fibrosis readout but poor direct target", "diagnostic biomarker",
  "COL3A1", "mesenchymal_HSC_myofibroblast", "Core collagen scar component.", "matrix biomarker", "conserved", "excellent fibrosis readout but poor direct target", "diagnostic biomarker",
  "ACTA2", "mesenchymal_HSC_myofibroblast", "Activated myofibroblast marker.", "cell-state marker", "conserved", "smooth muscle expression limits specificity", "pharmacodynamic biomarker",
  "PDGFRB", "mesenchymal_HSC_myofibroblast", "Stellate/pericyte activation and fibrogenic signaling axis.", "surface receptor; druggable class", "conserved", "vascular/pericyte roles create safety considerations", "therapeutic target",
  "PDGFRA", "mesenchymal_HSC_myofibroblast", "Mesenchymal activation marker and receptor tyrosine kinase.", "surface receptor; druggable class", "conserved", "broad mesenchymal biology", "therapeutic target",
  "LUM", "mesenchymal_HSC_myofibroblast", "Matrix-associated stromal marker.", "matrix biomarker", "conserved", "matrix marker more than direct intervention point", "diagnostic biomarker",
  "DCN", "mesenchymal_HSC_myofibroblast", "Matrix proteoglycan expressed by stromal populations.", "matrix biomarker", "conserved", "context-dependent anti/pro-fibrotic roles", "mechanistic marker",
  "RGS5", "mesenchymal_HSC_myofibroblast", "Pericyte/activated mesenchymal marker.", "cell-state marker", "conserved", "vascular mural cell expression", "mechanistic marker",
  "SMOC2", "mesenchymal_HSC_myofibroblast", "Reported HSC-derived secreted biomarker associated with human NAFLD/NASH severity.", "secreted biomarker", "conserved", "best positioned as biomarker before target", "diagnostic biomarker",
  "TIMP1", "mesenchymal_HSC_myofibroblast", "Matrix remodeling inhibitor frequently elevated in fibrosis.", "secreted biomarker", "conserved", "broad injury response", "pharmacodynamic biomarker",
  "LOXL2", "mesenchymal_HSC_myofibroblast", "Collagen crosslinking enzyme and fibrotic matrix remodeling candidate.", "secreted/enzyme; druggable class", "conserved", "prior clinical fibrosis targeting has been challenging", "therapeutic target",
  "SERPINE1", "mesenchymal_HSC_myofibroblast", "TGF-beta-linked matrix remodeling and injury-response mediator.", "secreted inhibitor", "conserved", "broad coagulation/fibrinolysis biology", "mechanistic marker",
  "MMP2", "mesenchymal_HSC_myofibroblast", "Matrix remodeling enzyme associated with activated stromal biology.", "secreted/enzyme", "conserved", "matrix remodeling can be protective or harmful by context", "mechanistic marker",
  "THY1", "mesenchymal_HSC_myofibroblast", "Activated mesenchymal and portal fibroblast-associated marker.", "surface marker", "conserved", "broad stromal expression", "pharmacodynamic biomarker"
)

de_ranked <- de |>
  mutate(
    direction = if_else(avg_log2FC > 0, "higher_in_cirrhosis", "lower_in_cirrhosis"),
    disease_points = pmin(20, abs(avg_log2FC) * 5 + -log10(pmax(p_val_adj, 1e-300)) / 10),
    specificity_points = pmin(15, abs(pct.1 - pct.2) * 15),
    de_support = p_val_adj < 0.05 & avg_log2FC > 0.25
  )

candidate_base <- de_ranked |>
  semi_join(manual_evidence, by = "gene") |>
  left_join(manual_evidence |> select(gene, intended_compartment), by = "gene") |>
  mutate(compartment_match = compartment == intended_compartment) |>
  group_by(gene) |>
  arrange(desc(compartment_match), desc(disease_points + specificity_points), .by_group = TRUE) |>
  slice_head(n = 1) |>
  ungroup() |>
  select(-intended_compartment, -compartment_match) |>
  right_join(manual_evidence, by = "gene") |>
  mutate(
    de_matches_curated_compartment = is.na(compartment) | compartment == intended_compartment,
    avg_log2FC = if_else(de_matches_curated_compartment, avg_log2FC, NA_real_),
    p_val_adj = if_else(de_matches_curated_compartment, p_val_adj, NA_real_),
    pct.1 = if_else(de_matches_curated_compartment, pct.1, NA_real_),
    pct.2 = if_else(de_matches_curated_compartment, pct.2, NA_real_),
    disease_points = if_else(de_matches_curated_compartment, disease_points, NA_real_),
    specificity_points = if_else(de_matches_curated_compartment, specificity_points, NA_real_),
    compartment = intended_compartment,
    avg_log2FC = coalesce(avg_log2FC, 0),
    p_val_adj = coalesce(p_val_adj, 1),
    pct.1 = coalesce(pct.1, 0),
    pct.2 = coalesce(pct.2, 0),
    disease_points = coalesce(disease_points, 0),
    specificity_points = coalesce(specificity_points, 0),
    pathway_points = case_when(
      gene %in% c("COL1A1", "COL3A1", "ACTA2", "PDGFRB", "PDGFRA", "TIMP1", "LOXL2", "SERPINE1", "MMP2") ~ 15,
      gene %in% c("TREM2", "CD9", "SPP1", "GPNMB", "PLVAP", "ACKR1") ~ 12,
      TRUE ~ 8
    ),
    validation_points = case_when(
      gene %in% c("SMOC2", "TREM2", "PLVAP", "ACKR1", "COL1A1", "COL3A1", "PDGFRB", "ACTA2") ~ 15,
      gene %in% c("SPP1", "GPNMB", "TIMP1", "LOXL2") ~ 10,
      TRUE ~ 5
    ),
    modality_points = case_when(
      grepl("surface|secreted|enzyme|receptor|druggable", translational_modality) ~ 10,
      TRUE ~ 5
    ),
    conservation_points = if_else(grepl("conserved|ortholog", model_conservation), 5, 2),
    safety_penalty = case_when(
      grepl("broad|pleiotropic|safety|not liver-specific", risk_note) ~ -6,
      grepl("poor direct target", risk_note) ~ -8,
      TRUE ~ -2
    ),
    total_score = disease_points + specificity_points + pathway_points + validation_points +
      modality_points + conservation_points + safety_penalty
  ) |>
  arrange(desc(total_score)) |>
  mutate(rank = row_number()) |>
  select(
    rank, gene, compartment, candidate_class, total_score, avg_log2FC, p_val_adj, pct.1, pct.2,
    translational_modality, model_conservation, literature_context, risk_note
  )

safe_write(candidate_base, file.path(cfg$paths$tables_dir, "ranked_biomarker_target_candidates.csv"))

genesets <- msigdbr(species = "Homo sapiens", collection = "H") |>
  select(gs_name, gene_symbol)
universe <- unique(de$gene)
pathway_results <- de_ranked |>
  filter(p_val_adj < 0.05, avg_log2FC > 0.25) |>
  group_by(compartment) |>
  group_modify(function(.x, .y) {
    foreground <- unique(.x$gene)
    gs_split <- split(genesets$gene_symbol, genesets$gs_name)
    bind_rows(lapply(names(gs_split), function(pathway_name) {
      gs <- gs_split[[pathway_name]]
      gs <- intersect(gs, universe)
      if (length(gs) < 5) return(NULL)
      a <- length(intersect(foreground, gs))
      b <- length(foreground) - a
      c <- length(gs) - a
      d <- length(universe) - a - b - c
      p <- fisher.test(matrix(c(a, b, c, d), nrow = 2), alternative = "greater")$p.value
      tibble::tibble(pathway = pathway_name, overlap = a, pathway_size = length(gs), p_value = p)
    })) |>
      mutate(p_adj = p.adjust(p_value, method = "BH")) |>
      arrange(p_adj) |>
      slice_head(n = 15)
  }) |>
  ungroup()

safe_write(pathway_results, file.path(cfg$paths$tables_dir, "hallmark_pathway_enrichment.csv"))

p <- candidate_base |>
  slice_head(n = 15) |>
  mutate(gene = reorder(gene, total_score)) |>
  ggplot(aes(total_score, gene, fill = candidate_class)) +
  geom_col() +
  labs(
    title = "Top prioritized biomarker and target candidates",
    x = "Evidence-weighted score",
    y = NULL
  ) +
  theme_project()
save_plot(p, file.path(cfg$paths$figures_dir, "ranked_candidate_scores.png"), 8, 5.5)

validation_feasibility <- tibble::tribble(
  ~dataset, ~status, ~decision, ~rationale,
  "GSE244832", "public processed archive around 693 MB", "highest-priority validation dataset", "Human NORMAL/MASL/MASH single-nucleus and multiomic liver dataset centered on HSC activation and anti-fibrotic target discovery.",
  "GSE207310", "public processed gene-level counts", "secondary validation", "Human NAFLD/NASH biopsy bulk RNA-seq useful for directionality checks, especially HSC-secreted biomarkers such as SMOC2.",
  "SCP2154", "portal-dependent macrophage atlas", "documented expansion path", "Most relevant for macrophage-state validation, but access/export format is less scriptable than GEO in this local run."
)
safe_write(validation_feasibility, file.path(cfg$paths$tables_dir, "validation_dataset_feasibility.csv"))

message("Prioritization complete.")
