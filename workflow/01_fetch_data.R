suppressPackageStartupMessages({
  library(yaml)
})

args <- commandArgs(trailingOnly = TRUE)
get_arg <- function(flag, default = NULL) {
  i <- match(flag, args)
  if (is.na(i) || i == length(args)) default else args[[i + 1]]
}

cfg <- yaml::read_yaml(get_arg("--config", "config/project.yaml"))
archive <- cfg$datasets$primary$archive
url <- cfg$datasets$primary$download_url
dir.create(dirname(archive), recursive = TRUE, showWarnings = FALSE)

if (file.exists(archive) && file.info(archive)$size > 1e6) {
  message("Primary archive already exists: ", archive)
} else {
  message("Downloading primary archive from GEO: ", url)
  download.file(url, destfile = archive, mode = "wb", quiet = FALSE)
}

manifest_path <- file.path(cfg$paths$metadata_dir, "download_manifest.csv")
manifest <- data.frame(
  accession = cfg$datasets$primary$accession,
  path = archive,
  bytes = file.info(archive)$size,
  source_url = url,
  downloaded_or_verified_at = as.character(Sys.time())
)
utils::write.csv(manifest, manifest_path, row.names = FALSE)
message("Wrote ", manifest_path)
