suppressPackageStartupMessages({
  library(yaml)
  library(dplyr)
  library(readr)
  library(ggplot2)
  library(msigdbr)
  library(tidyr)
})

source("src/R/utils.R")

args <- commandArgs(trailingOnly = TRUE)
get_arg <- function(flag, default = NULL) {
  i <- match(flag, args)
  if (is.na(i) || i == length(args)) default else args[[i + 1]]
}

cfg <- yaml::read_yaml(get_arg("--config", "config/project.yaml"))
tables_dir <- cfg$paths$tables_dir
de_path <- file.path(tables_dir, "compartment_de_cell_level_exploratory.csv")
if (!file.exists(de_path)) stop("Missing DE results. Run make analyze first.")
de <- read_csv(de_path, show_col_types = FALSE)
pseudobulk_path <- file.path(tables_dir, "pseudobulk_priority_gene_de.csv")
pseudobulk <- if (file.exists(pseudobulk_path)) read_csv(pseudobulk_path, show_col_types = FALSE) else tibble()
gse244_path <- file.path(tables_dir, "gse244832_focused_object_candidate_summary.csv")
gse244 <- if (file.exists(gse244_path)) read_csv(gse244_path, show_col_types = FALSE) else tibble()
gse207_path <- file.path(tables_dir, "validation_gse207310_candidate_lm_results.csv")
gse207 <- if (file.exists(gse207_path)) read_csv(gse207_path, show_col_types = FALSE) else tibble()
blood_path <- file.path(tables_dir, "gse136103_blood_candidate_marker_role_summary.csv")
blood <- if (file.exists(blood_path)) read_csv(blood_path, show_col_types = FALSE) else tibble()
mouse_path <- file.path(tables_dir, "gse136103_mouse_candidate_ortholog_summary.csv")
mouse <- if (file.exists(mouse_path)) read_csv(mouse_path, show_col_types = FALSE) else tibble()
pathfindr_path <- file.path(tables_dir, "pathfindr_pseudobulk_reactome_enrichment.csv")
pathfindr <- if (file.exists(pathfindr_path)) read_csv(pathfindr_path, show_col_types = FALSE) else tibble()
blood_detected_high <- if (nrow(blood) > 0) blood$gene[blood$mean_pct_detected >= 20] else character()
blood_allowed_context <- c("TIMP1", "LST1", "C1QA", "C1QB", "C1QC")

manual_evidence <- tibble::tribble(
  ~gene, ~intended_compartment, ~literature_context, ~translational_modality, ~model_conservation, ~risk_note, ~candidate_class, ~clinical_use_case,
  "TREM2", "macrophage_monocyte", "Scar-associated macrophage marker reported in human cirrhosis; useful for macrophage-state biology.", "surface receptor; biomarker and target biology", "mouse ortholog supports preclinical macrophage studies", "macrophage biology can be protective or pathogenic depending on disease timing", "future validation marker", "macrophage state stratification and perturbation studies",
  "CD9", "macrophage_monocyte", "Reported with TREM2 in scar-associated macrophages.", "surface protein; cell-state biomarker", "conserved", "broad tetraspanin expression limits target specificity", "pharmacodynamic biomarker", "scar-associated macrophage pharmacodynamic readout",
  "SPP1", "macrophage_monocyte", "Osteopontin is linked to inflammatory macrophage and fibrotic tissue programs.", "secreted protein", "conserved", "pleiotropic inflammatory, cancer, and repair biology", "future validation marker", "macrophage-to-stromal mechanism follow-up",
  "GPNMB", "macrophage_monocyte", "Disease-associated macrophage and repair-state marker in chronic tissue injury.", "surface/secreted-associated protein", "conserved", "not liver-specific", "pharmacodynamic biomarker", "macrophage injury-state readout",
  "PLVAP", "endothelial", "Reported scar-associated endothelial marker in human cirrhosis.", "surface-associated endothelial marker", "conserved", "vascular biology raises safety considerations for intervention", "diagnostic biomarker", "scar-associated vascular niche readout",
  "ACKR1", "endothelial", "Reported scar-associated endothelial marker in human cirrhosis.", "surface atypical chemokine receptor", "conserved with species differences", "vascular and immune-trafficking roles require caution", "future validation marker", "spatial vascular and immune trafficking validation",
  "VWF", "endothelial", "Endothelial activation and vascular remodeling marker.", "secreted/endothelial biomarker", "conserved", "broad vascular expression", "diagnostic biomarker", "endothelial activation context marker",
  "COL1A1", "mesenchymal_HSC_myofibroblast", "Core collagen scar component.", "matrix biomarker", "conserved", "excellent fibrosis readout but poor direct target", "diagnostic biomarker", "fibrosis burden and pharmacodynamic endpoint",
  "COL3A1", "mesenchymal_HSC_myofibroblast", "Core collagen scar component.", "matrix biomarker", "conserved", "excellent fibrosis readout but poor direct target", "diagnostic biomarker", "fibrosis burden and pharmacodynamic endpoint",
  "ACTA2", "mesenchymal_HSC_myofibroblast", "Activated myofibroblast marker.", "cell-state marker", "conserved", "smooth muscle expression limits specificity", "pharmacodynamic biomarker", "activated stromal-state readout",
  "PDGFRB", "mesenchymal_HSC_myofibroblast", "Stellate/pericyte activation and fibrogenic signaling axis.", "surface receptor; druggable class", "conserved", "vascular and pericyte roles create on-target safety concerns", "therapeutic target", "stromal activation perturbation hypothesis",
  "PDGFRA", "mesenchymal_HSC_myofibroblast", "Mesenchymal activation marker and receptor tyrosine kinase.", "surface receptor; druggable class", "conserved", "broad mesenchymal biology", "therapeutic target", "stromal activation perturbation hypothesis",
  "LUM", "mesenchymal_HSC_myofibroblast", "Matrix-associated stromal marker.", "matrix biomarker", "conserved", "matrix marker more than direct intervention point", "diagnostic biomarker", "stromal matrix burden marker",
  "DCN", "mesenchymal_HSC_myofibroblast", "Matrix proteoglycan expressed by stromal populations.", "matrix biomarker", "conserved", "context-dependent anti-fibrotic and pro-remodeling roles", "future validation marker", "matrix biology validation",
  "RGS5", "mesenchymal_HSC_myofibroblast", "Pericyte and activated mesenchymal marker.", "cell-state marker", "conserved", "vascular mural cell expression", "future validation marker", "pericyte and stromal-state validation",
  "SMOC2", "mesenchymal_HSC_myofibroblast", "Reported HSC-derived secreted biomarker associated with human NAFLD/NASH severity.", "secreted biomarker", "conserved", "best positioned as biomarker before target", "diagnostic biomarker", "secreted diagnostic or pharmacodynamic marker",
  "TIMP1", "mesenchymal_HSC_myofibroblast", "Matrix remodeling inhibitor frequently elevated in fibrosis.", "secreted biomarker", "conserved", "broad injury response", "pharmacodynamic biomarker", "secreted pharmacodynamic marker with specificity caveat",
  "LOXL2", "mesenchymal_HSC_myofibroblast", "Collagen crosslinking enzyme and fibrotic matrix remodeling candidate.", "secreted/enzyme; druggable class", "conserved", "prior clinical fibrosis targeting has been challenging", "therapeutic target", "matrix stiffness target hypothesis with clinical-risk flag",
  "SERPINE1", "mesenchymal_HSC_myofibroblast", "TGF-beta-linked matrix remodeling and injury-response mediator.", "secreted inhibitor", "conserved", "broad coagulation and fibrinolysis biology", "future validation marker", "TGF-beta-linked injury mechanism",
  "MMP2", "mesenchymal_HSC_myofibroblast", "Matrix remodeling enzyme associated with activated stromal biology.", "secreted/enzyme", "conserved", "matrix remodeling can be protective or harmful by context", "future validation marker", "matrix remodeling mechanism",
  "THY1", "mesenchymal_HSC_myofibroblast", "Activated mesenchymal and portal fibroblast-associated marker.", "surface marker", "conserved", "broad stromal expression", "pharmacodynamic biomarker", "activated stromal and portal-fibroblast-like readout"
)

score_cap <- function(x, cap) pmin(cap, pmax(0, x))

pathfindr_gene_support <- if (nrow(pathfindr) > 0) {
  pathfindr |>
    filter(!is.na(Up_regulated), Up_regulated != "") |>
    select(mechanism_compartment, Term_Description, Fold_Enrichment, lowest_p, Up_regulated) |>
    tidyr::separate_longer_delim(Up_regulated, delim = ",") |>
    mutate(gene = trimws(Up_regulated)) |>
    group_by(gene, mechanism_compartment) |>
    summarise(
      pathfindr_terms = n_distinct(Term_Description),
      pathfindr_best_p = min(lowest_p, na.rm = TRUE),
      pathfindr_top_term = Term_Description[which.min(lowest_p)][[1]],
      pathfindr_max_fold_enrichment = max(Fold_Enrichment, na.rm = TRUE),
      .groups = "drop"
    )
} else {
  tibble(
    gene = character(),
    mechanism_compartment = character(),
    pathfindr_terms = integer(),
    pathfindr_best_p = double(),
    pathfindr_top_term = character(),
    pathfindr_max_fold_enrichment = double()
  )
}

pseudobulk_support <- pseudobulk |>
  filter(gene %in% manual_evidence$gene) |>
  left_join(manual_evidence |> select(gene, intended_compartment), by = "gene") |>
  mutate(
    pseudobulk_compartment = case_when(
      grepl("HSC|Mesenchymal|myofibroblast|Stellate|Fibroblast", refined_cell_state, ignore.case = TRUE) ~ "mesenchymal_HSC_myofibroblast",
      grepl("Macrophage|Monocyte", refined_cell_state, ignore.case = TRUE) ~ "macrophage_monocyte",
      grepl("Endothelial", refined_cell_state, ignore.case = TRUE) ~ "endothelial",
      TRUE ~ refined_cell_state
    ),
    donor_points = if_else(
      pseudobulk_compartment == intended_compartment,
      score_cap((log2FC > 0) * (abs(log2FC) * 4 + -log10(pmax(p_adj, 1e-300)) / 3), 18),
      0
    )
  ) |>
  group_by(gene) |>
  arrange(desc(donor_points), .by_group = TRUE) |>
  slice_head(n = 1) |>
  ungroup() |>
  transmute(
    gene,
    pseudobulk_cell_state = refined_cell_state,
    pseudobulk_log2FC = log2FC,
    pseudobulk_p_adj = p_adj,
    n_healthy_donors,
    n_cirrhotic_donors,
    donor_consistency_points = donor_points
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
    disease_points = coalesce(disease_points, 0)
  ) |>
  left_join(pseudobulk_support, by = "gene") |>
  left_join(pathfindr_gene_support, by = c("gene", "intended_compartment" = "mechanism_compartment")) |>
  mutate(
    cell_level_disease_points = disease_points,
    specificity_points = coalesce(specificity_points, 0),
    donor_consistency_points = coalesce(donor_consistency_points, 0),
    disease_association_points = pmax(cell_level_disease_points, donor_consistency_points),
    pathway_points = case_when(
      !is.na(pathfindr_terms) & pathfindr_terms >= 3 ~ 14,
      !is.na(pathfindr_terms) & pathfindr_terms > 0 ~ 12,
      gene %in% c("COL1A1", "COL3A1", "ACTA2", "PDGFRB", "PDGFRA", "TIMP1", "LOXL2", "SERPINE1", "MMP2", "SMOC2", "LUM", "DCN") ~ 14,
      gene %in% c("TREM2", "CD9", "SPP1", "GPNMB", "PLVAP", "ACKR1", "VWF") ~ 12,
      TRUE ~ 7
    ),
    gse244_points = case_when(
      nrow(gse244) == 0 ~ 0,
      gene %in% gse244$gene[gse244$nash_vs_normal_delta > 0.1] ~ 8,
      gene %in% gse244$gene ~ 4,
      TRUE ~ 0
    ),
    gse207_points = case_when(
      nrow(gse207) == 0 ~ 0,
      gene %in% gse207$gene[gse207$log2FC_NASH_vs_NAFL > 0] ~ 5,
      gene %in% gse207$gene ~ 2,
      TRUE ~ 0
    ),
    mouse_points = case_when(
      nrow(mouse) == 0 ~ 0,
      gene %in% mouse$human_gene[mouse$fibrotic_vs_healthy_delta > 0.25] ~ 5,
      gene %in% mouse$human_gene[mouse$fibrotic_vs_healthy_delta > 0] ~ 3,
      gene %in% mouse$human_gene ~ 1,
      TRUE ~ 0
    ),
    blood_specificity_penalty = case_when(
      nrow(blood) == 0 ~ 0,
      gene %in% setdiff(blood_detected_high, blood_allowed_context) ~ -5,
      gene %in% blood_detected_high ~ -2,
      TRUE ~ 0
    ),
    external_validation_points = score_cap(gse244_points + gse207_points + mouse_points, 18),
    modality_points = case_when(
      grepl("surface|secreted|enzyme|receptor|druggable", translational_modality) ~ 10,
      grepl("matrix biomarker", translational_modality) ~ 6,
      TRUE ~ 4
    ),
    conservation_points = if_else(grepl("conserved|ortholog", model_conservation), 6, 2),
    safety_penalty = case_when(
      grepl("poor direct target", risk_note) ~ -8,
      grepl("broad|pleiotropic|safety|not liver-specific|vascular|pericyte|coagulation|smooth muscle", risk_note) ~ -6,
      TRUE ~ -2
    ),
    therapeutic_penalty = case_when(
      candidate_class == "therapeutic target" & grepl("prior clinical|broad|vascular|pericyte", risk_note) ~ -4,
      candidate_class == "diagnostic biomarker" & grepl("broad injury", risk_note) ~ -3,
      TRUE ~ 0
    ),
    total_score = disease_association_points + specificity_points + donor_consistency_points +
      pathway_points + external_validation_points + modality_points + conservation_points +
      safety_penalty + blood_specificity_penalty + therapeutic_penalty
  ) |>
  arrange(desc(total_score)) |>
  mutate(rank = row_number()) |>
  select(
    rank, gene, compartment, candidate_class, clinical_use_case, total_score,
    disease_association_points, donor_consistency_points, specificity_points, pathway_points,
    external_validation_points, modality_points, conservation_points, safety_penalty,
    blood_specificity_penalty, therapeutic_penalty, avg_log2FC, p_val_adj, pct.1, pct.2,
    pseudobulk_cell_state, pseudobulk_log2FC, pseudobulk_p_adj, n_healthy_donors, n_cirrhotic_donors,
    pathfindr_terms, pathfindr_best_p, pathfindr_top_term, pathfindr_max_fold_enrichment,
    translational_modality, model_conservation, literature_context, risk_note
  )

safe_write(candidate_base, file.path(cfg$paths$tables_dir, "ranked_biomarker_target_candidates.csv"))

score_components <- candidate_base |>
  select(
    rank, gene, candidate_class, clinical_use_case, total_score,
    disease_association_points, donor_consistency_points, specificity_points,
    pathway_points, external_validation_points, modality_points, conservation_points,
    safety_penalty, blood_specificity_penalty, therapeutic_penalty, risk_note
  )
safe_write(score_components, file.path(cfg$paths$tables_dir, "target_prioritization_scoring_components.csv"))

score_method <- tibble::tribble(
  ~component, ~direction, ~max_points, ~rationale,
  "disease_association_points", "positive", 20, "Rewards cirrhosis-up genes with meaningful effect size and adjusted significance, using donor-aware support when available.",
  "donor_consistency_points", "positive", 18, "Rewards signals that survive donor-level pseudobulk rather than only cell-level testing.",
  "specificity_points", "positive", 15, "Rewards a higher fraction of expressing cells in cirrhotic versus healthy cells inside the intended compartment.",
  "pathway_points", "positive", 14, "Rewards genes present in pathfindR Reactome active-subnetwork terms from donor-level pseudobulk signatures, with curated fibrosis mechanism support as fallback.",
  "external_validation_points", "positive", 18, "Rewards directionality in GSE244832, GSE207310, and mouse ortholog checks.",
  "modality_points", "positive", 10, "Rewards secreted, surface, receptor, enzyme, or otherwise assayable proteins.",
  "conservation_points", "positive", 6, "Rewards human-to-mouse orthology for preclinical feasibility.",
  "safety_penalty", "negative", -8, "Penalizes broad tissue expression, vascular or immune safety risk, pleiotropy, and direct targeting of structural matrix proteins.",
  "blood_specificity_penalty", "negative", -5, "Penalizes broad blood detectability unless the intended use is circulating injury or immune context.",
  "therapeutic_penalty", "negative", -4, "Penalizes therapeutic hypotheses with known clinical or on-target safety concerns."
)
safe_write(score_method, file.path(cfg$paths$tables_dir, "target_prioritization_scoring_method.csv"))

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
