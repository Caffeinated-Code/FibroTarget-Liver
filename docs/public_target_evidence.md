# Public Target Evidence

The target evidence enrichment step supplements the ranked candidate table with open-source public resources.

Sources queried:

- MyGene.info for gene identifiers
- Open Targets Platform GraphQL API for tractability and safety-liability annotations
- ClinicalTrials.gov API for liver fibrosis, cirrhosis, NASH, and MASH trial context
- NCBI ClinVar E-utilities for human gene-level ClinVar record counts
- UniProt REST API for protein localization, function, and tissue-specificity comments
- NCBI PubMed E-utilities for liver-fibrosis perturbation and safety literature signal
- `babelgene` for human-to-mouse orthology checks

Outputs:

- `reports/tables/target_public_evidence.csv`
- `reports/tables/ranked_biomarker_target_candidates_enriched.csv`
- `reports/tables/target_translational_evidence.csv`
- `reports/tables/target_mouse_orthology.csv`
- `reports/tables/ranked_biomarker_target_candidates_translational.csv`

Run:

```bash
make evidence
make translational-evidence
```

Interpretation notes:

- ClinicalTrials.gov matches are broad text-query matches and should be manually reviewed before making company or trial-stage claims.
- Open Targets tractability is useful for druggability triage, but it is not a liver-specific safety assessment.
- ClinVar gene-level counts indicate clinical variant knowledge, not whether a fibrosis target is safe or causal.
- PubMed counts and PMIDs are triage signals, not systematic reviews.
- Mouse orthology supports preclinical feasibility, but conserved expression does not guarantee conserved disease function.
- These evidence layers should supplement, not replace, donor-aware disease biology and validation data.
