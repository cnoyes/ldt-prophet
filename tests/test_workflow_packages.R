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
# Runs in CI on every push/PR (.github/workflows/ci.yml), deliberately NOT in
# the production daily job, so a false positive blocks a PR, not the site.

WORKFLOW <- ".github/workflows/daily-update.yml"
PIPELINE_FILES <- c(list.files("src", pattern = "^[1-4]_.*\\.R$", full.names = TRUE),
                    "scripts/export_to_json.R")

# Packages a called function needs but does not import (tidyr Suggests).
# separate_wider_*() calls rlang::check_installed("stringr") at runtime.
IMPLICIT_RULES <- list(stringr = "separate_wider_")

# Ship with R; never in the install list.
BASE_PKGS <- rownames(installed.packages(priority = c("base", "recommended")))

extract <- function(x, pattern) {
  m <- regmatches(x, gregexpr(pattern, x, perl = TRUE))
  sub(pattern, "\\1", unlist(m), perl = TRUE)
}

# Packages the given R source lines need: library()/require()/pkg:: calls,
# plus IMPLICIT_RULES. Base/recommended packages are excluded (PR #5 review).
required_packages <- function(src) {
  src <- sub("#.*$", "", src)                       # ignore comments
  explicit <- c(extract(src, "(?:library|require)\\(['\"]?([A-Za-z0-9.]+)"),
                extract(src, "([A-Za-z0-9.]+)::"))
  implicit <- names(Filter(function(pat) any(grepl(pat, src, fixed = TRUE)), IMPLICIT_RULES))
  sort(setdiff(unique(c(explicit, implicit)), BASE_PKGS))
}

# Packages the workflow installs: the value of the single-line `R_PKGS:` job
# env var, comments stripped. Any other layout is an error, not a guess.
installed_packages <- function(wf) {
  line <- grep("^\\s*R_PKGS:", wf, value = TRUE)
  if (length(line) != 1) stop("expected exactly one `R_PKGS:` line in ", WORKFLOW, call. = FALSE)
  value <- sub("#.*$", "", sub("^\\s*R_PKGS:\\s*", "", line))
  pkgs <- strsplit(trimws(value), "\\s+")[[1]]
  if (length(pkgs) == 0 || any(pkgs == "") || grepl("^[>|]", value))
    stop("R_PKGS must be a single-line, space-separated list; got: ", sQuote(line), call. = FALSE)
  pkgs
}

cache_key_is_image_scoped <- function(wf) {
  any(grepl("IMAGE_OS", grep("^\\s*key:\\s", wf, value = TRUE)))
}

# --- self-tests for the parsers (review findings on PR #5) ------------------
stopifnot(
  # base namespaces are not install requirements
  identical(required_packages(c("x <- stats::setNames(1, 'a')", "library(dplyr)")), "dplyr"),
  # library() inside a comment does not count
  identical(required_packages("# library(plotly) someday"), character(0)),
  # implicit rule fires
  identical(required_packages(c("library(tidyr)", "separate_wider_delim(x)")), c("stringr", "tidyr")),
  # trailing comment on R_PKGS is not a package; extra spaces are tolerated
  identical(installed_packages("      R_PKGS: dplyr  tidyr   # stringr"), c("dplyr", "tidyr")),
  # folded/multi-line scalar is rejected rather than silently empty
  inherits(try(installed_packages(c("      R_PKGS: >-", "        dplyr tidyr")), silent = TRUE), "try-error"),
  identical(cache_key_is_image_scoped("          key: ${{ runner.os }}-${{ env.IMAGE_OS }}-r"), TRUE),
  identical(cache_key_is_image_scoped("          key: ${{ runner.os }}-r-4.4-"), FALSE)
)

# --- the real check ---------------------------------------------------------
src <- unlist(lapply(PIPELINE_FILES, readLines, warn = FALSE))
wf <- readLines(WORKFLOW, warn = FALSE)

required <- required_packages(src)
installed <- installed_packages(wf)
cat("required :", paste(required, collapse = " "), "\n")
cat("installed:", paste(installed, collapse = " "), "\n")

missing <- setdiff(required, installed)
if (length(missing) > 0) {
  stop(WORKFLOW, " does not install packages the pipeline needs: ",
       paste(missing, collapse = ", "), call. = FALSE)
}

# The cache key must change when the runner image changes, otherwise binaries
# built for the previous Ubuntu release are restored and fail to load (#4).
if (!cache_key_is_image_scoped(wf)) {
  stop("R package cache key in ", WORKFLOW, " must include IMAGE_OS", call. = FALSE)
}

cat("OK: workflow installs all required packages and cache key is image-scoped\n")
