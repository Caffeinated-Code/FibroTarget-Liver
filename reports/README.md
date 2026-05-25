# Reports And Review Artifacts

This folder contains reviewable outputs, not core pipeline code.

## Narrative Outputs

- `executive_summary/README.md`: concise scientific summary and interpretation
- `screening_responses/README.md`: written responses to the eight screening questions
- `run_notes.md`: implementation notes, caveats, and improvement opportunities

## Figures

- `figures/umap_disease_state.png`
- `figures/umap_required_compartments.png`
- `figures/required_compartment_marker_dotplot.png`
- `figures/umap_refined_cell_states.png`
- `figures/pseudobulk_priority_gene_de.png`
- `figures/gse244832_hsc_validation_heatmap.png`
- `figures/ranked_candidate_scores.png`

## Tables

Key tables:

- `tables/ranked_biomarker_target_candidates_enriched.csv`
- `tables/ranked_biomarker_target_candidates_translational.csv`
- `tables/pseudobulk_de_by_refined_state.csv`
- `tables/pseudobulk_priority_gene_de.csv`
- `tables/refined_cluster_annotations.csv`
- `tables/gse244832_hsc_candidate_validation.csv`
- `tables/target_public_evidence.csv`
- `tables/target_translational_evidence.csv`
- `tables/target_mouse_orthology.csv`
- `tables/validation_gse244832_candidate_expression_by_condition.csv`
- `tables/hallmark_pathway_enrichment.csv`
- `tables/compartment_de_cell_level_exploratory.csv`

The cell-level DE table is exploratory. Donor-aware interpretation should use `pseudobulk_de_by_refined_state.csv` and `pseudobulk_priority_gene_de.csv`.
