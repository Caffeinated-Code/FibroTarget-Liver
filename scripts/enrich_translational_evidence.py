#!/usr/bin/env python3
"""Add localization, tissue, perturbation, and trial-context evidence for target review."""

from __future__ import annotations

import csv
import json
import time
import urllib.parse
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REPORTS = ROOT / "reports" / "tables"
PRIORITY_GENES = [
    "SMOC2",
    "TIMP1",
    "PLVAP",
    "ACKR1",
    "COL1A1",
    "COL3A1",
    "PDGFRA",
    "PDGFRB",
    "TREM2",
    "CD9",
    "SPP1",
    "GPNMB",
]

CURATED_NOTES = {
    "SMOC2": {
        "target_positioning": "secreted HSC biomarker candidate; stronger near-term fit as diagnostic or pharmacodynamic marker than direct target",
        "clinical_caution": "extracellular matrix biology is tissue-repair linked, so target causality needs perturbation evidence before a therapeutic program",
    },
    "TIMP1": {
        "target_positioning": "secreted fibrosis and matrix-remodeling biomarker with strong assayability",
        "clinical_caution": "broad injury-response signal; specificity for liver fibrosis stage must be validated against inflammation and cancer contexts",
    },
    "PLVAP": {
        "target_positioning": "scar-associated endothelial surface marker; useful for vascular niche readouts and spatial validation",
        "clinical_caution": "vascular expression raises safety and tissue-specific delivery considerations",
    },
    "ACKR1": {
        "target_positioning": "endothelial chemokine-trafficking marker; useful for niche biology and cell-state annotation",
        "clinical_caution": "human population genetics and immune-trafficking biology require caution before intervention",
    },
    "COL1A1": {
        "target_positioning": "core scar matrix readout; best as endpoint or pharmacodynamic marker",
        "clinical_caution": "direct collagen targeting is unlikely to be selective enough for a therapeutic program",
    },
    "COL3A1": {
        "target_positioning": "core fibrillar collagen readout; useful for fibrosis burden and matrix remodeling",
        "clinical_caution": "direct targeting risks normal wound-healing and connective-tissue biology",
    },
    "PDGFRA": {
        "target_positioning": "druggable mesenchymal receptor axis; plausible HSC activation biology",
        "clinical_caution": "broad mesenchymal roles mean therapeutic window and liver-specific delivery matter",
    },
    "PDGFRB": {
        "target_positioning": "druggable stellate/pericyte receptor axis with strong fibrogenic plausibility",
        "clinical_caution": "pericyte and vascular biology create on-target safety concerns",
    },
    "TREM2": {
        "target_positioning": "scar-associated macrophage receptor; useful for macrophage-state stratification and perturbation studies",
        "clinical_caution": "macrophage effects may be protective or pathogenic depending on timing and tissue context",
    },
    "CD9": {
        "target_positioning": "surface marker of injury-associated macrophage states; more compelling as cell-state marker than standalone target",
        "clinical_caution": "broad tetraspanin expression limits specificity",
    },
    "SPP1": {
        "target_positioning": "secreted macrophage and fibrotic niche mediator; strong biology but pleiotropic",
        "clinical_caution": "inflammation, cancer, and repair biology complicate target safety",
    },
    "GPNMB": {
        "target_positioning": "injury-associated macrophage marker with translational biomarker potential",
        "clinical_caution": "not liver-specific; target role requires directionally clear perturbation evidence",
    },
}


def http_json(url: str, timeout: int = 35) -> dict:
    req = urllib.request.Request(url, headers={"User-Agent": "FibroTarget-Liver/0.1"})
    with urllib.request.urlopen(req, timeout=timeout) as response:
        return json.loads(response.read().decode("utf-8"))


def read_genes() -> list[str]:
    path = REPORTS / "ranked_biomarker_target_candidates.csv"
    genes = []
    if path.exists():
        with path.open() as handle:
            for row in csv.DictReader(handle):
                genes.append(row["gene"])
    return sorted(set(genes).union(PRIORITY_GENES), key=lambda g: PRIORITY_GENES.index(g) if g in PRIORITY_GENES else 999)


def write_csv(path: Path, rows: list[dict], fieldnames: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def uniprot_lookup(symbol: str) -> dict:
    query = urllib.parse.quote(f"gene_exact:{symbol} AND organism_id:9606")
    fields = "accession,protein_name,gene_names,cc_subcellular_location,cc_tissue_specificity,cc_function"
    url = f"https://rest.uniprot.org/uniprotkb/search?query={query}&fields={fields}&format=json&size=1"
    try:
        result = http_json(url)
    except Exception as exc:
        return {"uniprot_error": str(exc)}
    rows = result.get("results", [])
    if not rows:
        return {}
    row = rows[0]
    comments = row.get("comments", [])

    def comment_text(comment_type: str) -> str:
        texts = []
        for comment in comments:
            if comment.get("commentType") != comment_type:
                continue
            for text in comment.get("texts", []):
                value = text.get("value")
                if value:
                    texts.append(value)
            for loc in comment.get("subcellularLocations", []):
                location = loc.get("location", {}).get("value")
                topology = loc.get("topology", {}).get("value")
                if location or topology:
                    texts.append("; ".join(x for x in [location, topology] if x))
        return " | ".join(dict.fromkeys(texts))

    return {
        "uniprot_accession": row.get("primaryAccession", ""),
        "protein_name": row.get("proteinDescription", {}).get("recommendedName", {}).get("fullName", {}).get("value", ""),
        "uniprot_subcellular_location": comment_text("SUBCELLULAR LOCATION"),
        "uniprot_tissue_specificity": comment_text("TISSUE SPECIFICITY"),
        "uniprot_function": comment_text("FUNCTION"),
    }


def pubmed_search(symbol: str, focus: str) -> tuple[str, str]:
    term = urllib.parse.quote(f'({symbol}[Title/Abstract]) AND ("liver fibrosis"[Title/Abstract] OR cirrhosis[Title/Abstract] OR MASH[Title/Abstract] OR NASH[Title/Abstract]) AND ({focus})')
    url = f"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term={term}&retmode=json&retmax=5&sort=relevance"
    try:
        result = http_json(url)
    except Exception:
        return "", ""
    esearch = result.get("esearchresult", {})
    return esearch.get("count", ""), ";".join(esearch.get("idlist", []))


def clinical_trials(symbol: str) -> tuple[str, str, str]:
    term = urllib.parse.quote(f"{symbol} AND (MASH OR NASH OR liver fibrosis OR cirrhosis)")
    url = f"https://clinicaltrials.gov/api/v2/studies?query.term={term}&pageSize=10&format=json"
    try:
        result = http_json(url)
    except Exception:
        return "", "", ""
    trials = []
    phases = set()
    sponsors = set()
    for study in result.get("studies", []):
        protocol = study.get("protocolSection", {})
        ident = protocol.get("identificationModule", {})
        design = protocol.get("designModule", {})
        status = protocol.get("statusModule", {})
        sponsor = protocol.get("sponsorCollaboratorsModule", {}).get("leadSponsor", {}).get("name", "")
        phase = ", ".join(design.get("phases", []))
        if phase:
            phases.add(phase)
        if sponsor:
            sponsors.add(sponsor)
        trials.append(f"{ident.get('nctId', '')}: {ident.get('briefTitle', '')} ({phase}; {status.get('overallStatus', '')}; {sponsor})")
    return " | ".join(trials[:5]), "; ".join(sorted(phases)), "; ".join(sorted(sponsors))


def main() -> None:
    rows = []
    for gene in read_genes():
        localization = uniprot_lookup(gene)
        perturb_count, perturb_pmids = pubmed_search(gene, "knockout[Title/Abstract] OR knockdown[Title/Abstract] OR inhibitor[Title/Abstract] OR blockade[Title/Abstract] OR silencing[Title/Abstract]")
        safety_count, safety_pmids = pubmed_search(gene, "toxicity[Title/Abstract] OR safety[Title/Abstract] OR adverse[Title/Abstract]")
        trials, phases, sponsors = clinical_trials(gene)
        curated = CURATED_NOTES.get(gene, {})
        rows.append(
            {
                "gene": gene,
                "uniprot_error": localization.get("uniprot_error", ""),
                **localization,
                "pubmed_liver_fibrosis_perturbation_count": perturb_count,
                "pubmed_liver_fibrosis_perturbation_pmids": perturb_pmids,
                "pubmed_liver_fibrosis_safety_count": safety_count,
                "pubmed_liver_fibrosis_safety_pmids": safety_pmids,
                "clinicaltrials_liver_context_examples": trials,
                "clinicaltrials_phases_seen": phases,
                "clinicaltrials_sponsors_seen": sponsors,
                "target_positioning": curated.get("target_positioning", ""),
                "clinical_caution": curated.get("clinical_caution", ""),
                "source_timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
            }
        )
        time.sleep(0.25)

    fieldnames = [
        "gene",
        "uniprot_accession",
        "protein_name",
        "uniprot_subcellular_location",
        "uniprot_tissue_specificity",
        "uniprot_function",
        "uniprot_error",
        "pubmed_liver_fibrosis_perturbation_count",
        "pubmed_liver_fibrosis_perturbation_pmids",
        "pubmed_liver_fibrosis_safety_count",
        "pubmed_liver_fibrosis_safety_pmids",
        "clinicaltrials_liver_context_examples",
        "clinicaltrials_phases_seen",
        "clinicaltrials_sponsors_seen",
        "target_positioning",
        "clinical_caution",
        "source_timestamp",
    ]
    write_csv(REPORTS / "target_translational_evidence.csv", rows, fieldnames)
    print("target_translational_evidence_ready")


if __name__ == "__main__":
    main()
