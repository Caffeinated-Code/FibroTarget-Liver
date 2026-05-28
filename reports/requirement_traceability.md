# Requirement Traceability

This audit maps the assignment and stakeholder clarification to the repository. Private conversation notes and the assignment PDF are used only for this audit and are not tracked in Git.

## Assignment Requirements

| Requirement | Status | Evidence |
|---|---:|---|
| Use GSE136103 as the primary dataset | Complete | `config/project.yaml`, `workflow/01_fetch_data.R`, `workflow/02_curate_metadata.R` |
| Compact end-to-end workflow | Complete | `Makefile`, `workflow/`, `scripts/`, `reports/`, `dashboard/` |
| Curate and summarize dataset and metadata | Complete | `data/metadata/gse136103_sample_manifest.csv`, `reports/tables/qc_by_library.csv` |
| QC and preprocessing with choices explained | Complete | `workflow/03_compact_analysis.R`, `reports/tables/qc_decision_log.csv`, `reports/executive_submission_summary.md`, `docs/analysis_walkthrough.md` |
| Annotate major liver cell types and validate required compartments | Complete | `workflow/07_refine_annotations.R`, `reports/tables/refined_cluster_annotations.csv`, `reports/figures/required_compartment_marker_dotplot.png`, `reports/figures/umap_refined_cell_states.png` |
| Required HSC/mesenchymal/myofibroblast compartment | Complete | Marker set in `config/project.yaml`; validation in marker dot plot and pseudobulk tables |
| Required macrophage/monocyte compartment | Complete | Marker set in `config/project.yaml`; marker validation and candidate evidence |
| Required endothelial compartment | Complete | Marker set in `config/project.yaml`; ACKR1/PLVAP support in reports and tables |
| Identify fibrosis/cirrhosis-associated genes or cell states | Complete | `reports/tables/pseudobulk_de_by_refined_state.csv`, `reports/tables/pseudobulk_priority_gene_de.csv` |
| Pathway or mechanism analysis | Complete | Hallmark/EnrichR-style enrichment plus pathfindR pseudobulk Reactome active-subnetwork analysis: `reports/tables/hallmark_pathway_enrichment.csv`, `reports/tables/pathfindr_pseudobulk_reactome_enrichment.csv`, pathway and pathfindR figures, `docs/analysis_walkthrough.md` |
| ML-assisted or rule-based biomarker prioritization score | Complete | `workflow/04_prioritize_targets.R`, `config/project.yaml`, `reports/tables/ranked_biomarker_target_candidates_translational.csv`, `reports/tables/target_prioritization_scoring_components.csv`, `reports/tables/target_prioritization_scoring_method.csv` |
| Ranked list of 10-20 candidates | Complete | `reports/tables/ranked_biomarker_target_candidates_translational.csv` |
| Explain diagnostic, therapeutic, and validation relevance | Complete | `reports/executive_submission_summary.md`, `docs/analysis_walkthrough.md`, candidate table columns |
| Reproducible GitHub repository | Complete | `README.md`, `Makefile`, `renv.lock`, `Dockerfile`, `nextflow/` |
| README with setup instructions | Complete | `README.md` |
| QC summary | Complete | `reports/tables/qc_by_library.csv`, `reports/tables/qc_filtered_by_library_compartment.csv` |
| Cell annotation figures | Complete | `reports/figures/umap_required_compartments.png`, `reports/figures/required_compartment_marker_dotplot.png`, `reports/figures/umap_refined_cell_states.png` |
| Differential expression results | Complete | `reports/tables/compartment_de_cell_level_exploratory.csv`, `reports/tables/pseudobulk_de_by_refined_state.csv` |
| Pathway results | Complete | `reports/tables/hallmark_pathway_enrichment.csv`, `reports/tables/pathfindr_pseudobulk_reactome_enrichment.csv`, pathway and pathfindR figures |
| Ranked biomarker or target table | Complete | `reports/tables/ranked_biomarker_target_candidates_translational.csv` |
| Navigable executive summary | Complete | `reports/executive_submission_summary.Rmd`, `reports/executive_submission_summary.html` |
| Written responses to all eight screening questions | Complete | `reports/screening_responses/README.md` |
| Optional validation dataset | Complete | GSE244832 focused HSC validation and focused Seurat object reanalysis; GSE207310 symbol-level validation; GSE136103 blood and mouse secondary validation |

## Stakeholder Clarification Applied

| Clarification | Status | Evidence |
|---|---:|---|
| Practical-level assignment, not publication-grade | Complete | Scope and limitations in `reports/executive_submission_summary.md` and `docs/technical_appendix.md` |
| Show scientific thinking and single-cell/transcriptomic approach | Complete | `reports/screening_responses/README.md`, `reports/executive_submission_summary.md`, `docs/analysis_walkthrough.md` |
| Interpret liver fibrosis biology, MASH, and cirrhosis critically | Complete | `reports/executive_submission_summary.md`, `docs/analysis_walkthrough.md` |
| Prioritize targets with translational relevance | Complete | `reports/tables/ranked_biomarker_target_candidates_translational.csv` |
| Use raw/reproducible data processing, not only RData object | Complete | GEO count matrices are primary input; published Seurat object is only a reference layer |
| Include validation dataset readiness and prioritization | Complete | `docs/technical_appendix.md`, `reports/tables/validation_dataset_feasibility.csv` |
| Add public evidence such as Open Targets, ClinVar, trials, conservation, safety, perturbation | Complete | `scripts/enrich_target_evidence.py`, `scripts/enrich_translational_evidence.py`, `reports/tables/target_public_evidence.csv`, `reports/tables/target_translational_evidence.csv`, `reports/tables/target_mouse_orthology.csv` |
| Consider production/AWS future | Complete | `nextflow/`, `Dockerfile`, `docs/technical_appendix.md`, `nextflow/fibrotarget_demo/README.md` |
| Include interactive visualization | Complete | `dashboard/app.R` |
| Do not track private conversation notes | Complete | `.gitignore`, `scripts/validate_repo_structure.py`, `git status` |
| Use blood and mouse samples without confounding the primary contrast | Complete | `workflow/13_validate_blood_mouse_markers.R`, `reports/tables/gse136103_blood_candidate_marker_role_summary.csv`, `reports/tables/gse136103_mouse_candidate_ortholog_summary.csv` |

## Remaining Gaps And Rationale

| Gap | Rationale | Next Step |
|---|---|---|
| Macrophage-focused external validation | Current validation is strongest for HSC and bulk NAFLD/NASH directionality | Add SCP2154 or another accessible macrophage atlas |
| SCP2154 macrophage atlas validation | Most useful for macrophage candidates, but portal/export logistics make it less reliable for the compact local run | Add as optional portal-dependent module |
| Full all-gene GSE244832 reanalysis | A focused Seurat object is now implemented; full all-gene reanalysis remains better suited to AWS due matrix size | Run full all-gene object generation as a cloud job |
| Expanded preclinical validation | GSE136103 mouse validation is executable and ortholog-aware, but it has one healthy and one fibrotic mouse sample | Add larger mouse MASH and fibrosis datasets to the Nextflow validation module |
| Ligand-receptor mechanism analysis | Addressed in written screening response, but not implemented as a code module | Add LIANA/CellChat/NicheNet module after stable cell-state annotation |
