suppressPackageStartupMessages({
  library(yaml)
  library(dplyr)
  library(readr)
  library(stringr)
})

args <- commandArgs(trailingOnly = TRUE)
get_arg <- function(flag, default = NULL) {
  i <- match(flag, args)
  if (is.na(i) || i == length(args)) default else args[[i + 1]]
}

cfg <- yaml::read_yaml(get_arg("--config", "config/project.yaml"))
archive <- cfg$datasets$primary$archive
if (!file.exists(archive)) stop("Missing primary archive: ", archive)

members <- system2("tar", c("-tf", archive), stdout = TRUE)
files <- tibble(file = members) |>
  mutate(
    gsm = str_extract(file, "^GSM[0-9]+"),
    sample_token = str_remove(file, "^GSM[0-9]+_"),
    sample_token = str_remove(sample_token, "_(barcodes|genes|matrix)\\.(tsv|mtx)\\.gz$"),
    assay_file = case_when(
      str_detect(file, "_barcodes\\.tsv\\.gz$") ~ "barcodes",
      str_detect(file, "_genes\\.tsv\\.gz$") ~ "genes",
      str_detect(file, "_matrix\\.mtx\\.gz$") ~ "matrix",
      TRUE ~ NA_character_
    )
  )

sample_manifest <- files |>
  filter(!is.na(assay_file)) |>
  distinct(gsm, sample_token) |>
  mutate(
    species = if_else(str_detect(sample_token, "^mouse"), "Mus musculus", "Homo sapiens"),
    tissue = case_when(
      str_detect(sample_token, "^blood") ~ "blood",
      str_detect(sample_token, "^mouse") ~ "mouse_liver",
      TRUE ~ "liver"
    ),
    disease_state = case_when(
      str_detect(sample_token, "^healthy") ~ "healthy",
      str_detect(sample_token, "^cirrhotic") ~ "cirrhotic",
      str_detect(sample_token, "^mouse_healthy") ~ "healthy",
      str_detect(sample_token, "^mouse_fibrotic") ~ "fibrotic",
      str_detect(sample_token, "^blood") ~ "blood_reference",
      TRUE ~ "unknown"
    ),
    donor = case_when(
      str_detect(sample_token, "^(healthy|cirrhotic)[0-9]+") ~ str_extract(sample_token, "^(healthy|cirrhotic)[0-9]+"),
      str_detect(sample_token, "^blood[0-9]+") ~ str_extract(sample_token, "^blood[0-9]+"),
      TRUE ~ sample_token
    ),
    fraction = case_when(
      str_detect(sample_token, "cd45\\+") ~ "CD45_positive",
      str_detect(sample_token, "cd45-") ~ "CD45_negative",
      TRUE ~ "not_fractionated"
    ),
    split = case_when(
      str_detect(sample_token, "cd45-A") ~ "A",
      str_detect(sample_token, "cd45-B") ~ "B",
      TRUE ~ NA_character_
    ),
    include_primary = species == "Homo sapiens" & tissue == "liver" & disease_state %in% c("healthy", "cirrhotic"),
    exclusion_reason = case_when(
      include_primary ~ NA_character_,
      species != "Homo sapiens" ~ "mouse excluded from primary human analysis",
      tissue != "liver" ~ "blood excluded from primary tissue analysis",
      TRUE ~ "not in primary contrast"
    )
  ) |>
  arrange(species, tissue, disease_state, donor, fraction, gsm)

sample_files <- files |>
  filter(!is.na(assay_file)) |>
  select(gsm, sample_token, assay_file, file) |>
  tidyr::pivot_wider(names_from = assay_file, values_from = file)

sample_manifest <- sample_manifest |>
  left_join(sample_files, by = c("gsm", "sample_token"))

dir.create(cfg$paths$metadata_dir, recursive = TRUE, showWarnings = FALSE)
write_csv(sample_manifest, file.path(cfg$paths$metadata_dir, "gse136103_sample_manifest.csv"))
write_csv(files, file.path(cfg$paths$metadata_dir, "gse136103_archive_files.csv"))

summary_tbl <- sample_manifest |>
  count(species, tissue, disease_state, include_primary, name = "libraries")
write_csv(summary_tbl, file.path(cfg$paths$metadata_dir, "gse136103_dataset_summary.csv"))

message("Curated ", nrow(sample_manifest), " libraries.")
message("Primary human liver libraries: ", sum(sample_manifest$include_primary))
