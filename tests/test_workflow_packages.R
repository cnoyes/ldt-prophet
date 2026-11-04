#!/usr/bin/env Rscript
# Regression test for #4: the daily workflow must install every package the R
# pipeline needs, so a fresh runner (or a cache invalidated by an OS migration)
# can run `run_all.R` + `scripts/export_to_json.R` without relying on packages
# that happen to be left over in a stale cache.
#
# If you delete this test, the next time GitHub rotates `ubuntu-latest` the
# daily job will fail with "The package X is required" and the site stops
# updating silently.
#
# Run: Rscript tests/test_workflow_packages.R   (base R only, no deps)

workflow <- ".github/workflows/daily-update.yml"
pipeline_files <- c(list.files("src", pattern = "^[1-4]_.*\\.R$", full.names = TRUE),
                    "scripts/export_to_json.R")

# Packages declared explicitly via library()/require()/pkg::fn in the pipeline.
extract <- function(x, pattern) {
  m <- regmatches(x, gregexpr(pattern, x, perl = TRUE))
  sub(pattern, "\\1", unlist(m), perl = TRUE)
}
explicit <- unique(unlist(lapply(pipeline_files, function(f) {
  src <- readLines(f, warn = FALSE)
  c(extract(src, "(?:library|require)\\(['\"]?([A-Za-z0-9.]+)"),
    extract(src, "([A-Za-z0-9.]+)::"))
})))

# Packages a called function needs but does not import (Suggests). tidyr's
# separate_wider_*() calls rlang::check_installed("stringr") at runtime.
implicit_rules <- list(stringr = "separate_wider_")
implicit <- names(Filter(function(pat) {
  any(vapply(pipeline_files, function(f) any(grepl(pat, readLines(f, warn = FALSE), fixed = TRUE)), logical(1)))
}, implicit_rules))

required <- sort(unique(c(explicit, implicit)))

# What the workflow installs: the R_PKGS env var (preferred) or, for older
# layouts, the literal install.packages(c(...)) call.
wf <- readLines(workflow, warn = FALSE)
pkgs_line <- grep("^\\s*R_PKGS:", wf, value = TRUE)
if (length(pkgs_line) == 0) pkgs_line <- grep("install\\.packages\\(", wf, value = TRUE)
installed <- unique(unlist(regmatches(pkgs_line, gregexpr("[A-Za-z0-9._]+", pkgs_line))))
installed <- setdiff(installed, c("R_PKGS", "install.packages", "install", "packages", "c"))

missing <- setdiff(required, installed)
cat("required :", paste(required, collapse = " "), "\n")
cat("installed:", paste(installed, collapse = " "), "\n")
if (length(missing) > 0) {
  stop("daily-update.yml does not install packages the pipeline needs: ",
       paste(missing, collapse = ", "), call. = FALSE)
}

# The cache key must change when the runner image changes, otherwise binaries
# built for the previous Ubuntu release are restored and fail to load (#4).
cache_key <- grep("^\\s*key:\\s", wf, value = TRUE)
if (!any(grepl("IMAGE_OS", cache_key))) {
  stop("R package cache key must include the runner image (IMAGE_OS); got: ",
       trimws(paste(cache_key, collapse = " | ")), call. = FALSE)
}

cat("OK: workflow installs all required packages and cache key is image-scoped\n")
