#!/usr/bin/env Rscript
# Regression test for #4: DESCRIPTION `Imports` must list every package the R
# pipeline needs, because that is what the daily workflow installs
# (r-lib/actions/setup-r-dependencies). A package the pipeline uses but
# DESCRIPTION omits only works while it happens to be in a cache; the next
# runner-image rotation then fails the daily job with "The package X is
# required" and the site stops updating silently.
#
# Run: Rscript tests/test_workflow_packages.R   (base R only, no deps)
# Runs in CI on every push/PR (.github/workflows/ci.yml), deliberately NOT in
# the production daily job, so a false positive blocks a PR, not the site.

PIPELINE_FILES <- c(list.files("src", pattern = "^[1-4]_.*\\.R$", full.names = TRUE),
                    "scripts/export_to_json.R")

# Packages a called function needs but does not import (tidyr Suggests).
# separate_wider_*() calls rlang::check_installed("stringr") at runtime.
IMPLICIT_RULES <- list(stringr = "separate_wider_")

# Ship with R; never in Imports.
BASE_PKGS <- rownames(installed.packages(priority = c("base", "recommended")))

extract <- function(x, pattern) {
  m <- regmatches(x, gregexpr(pattern, x, perl = TRUE))
  sub(pattern, "\\1", unlist(m), perl = TRUE)
}

# Packages the given R source lines need: library()/require()/pkg:: calls,
# plus IMPLICIT_RULES. Base/recommended packages are excluded.
required_packages <- function(src) {
  src <- sub("#.*$", "", src)                       # ignore comments
  explicit <- c(extract(src, "(?:library|require)\\(['\"]?([A-Za-z0-9.]+)"),
                extract(src, "([A-Za-z0-9.]+)::"))
  implicit <- names(Filter(function(pat) any(grepl(pat, src, fixed = TRUE)), IMPLICIT_RULES))
  sort(setdiff(unique(c(explicit, implicit)), BASE_PKGS))
}

# Package names in a DESCRIPTION dependency field, version constraints dropped.
description_imports <- function(path = "DESCRIPTION", field = "Imports") {
  dcf <- read.dcf(path, fields = field)[1, field]
  if (is.na(dcf)) stop("no ", field, " field in ", path, call. = FALSE)
  trimws(sub("\\s*\\(.*\\)", "", strsplit(dcf, ",")[[1]]))
}

# --- self-tests for the parsers --------------------------------------------
tmp <- tempfile(); writeLines(c("Package: x", "Imports: dplyr (>= 1.0),", "    tidyr"), tmp)
stopifnot(
  identical(required_packages(c("x <- stats::setNames(1, 'a')", "library(dplyr)")), "dplyr"),
  identical(required_packages("# library(plotly) someday"), character(0)),
  identical(required_packages(c("library(tidyr)", "separate_wider_delim(x)")), c("stringr", "tidyr")),
  identical(description_imports(tmp), c("dplyr", "tidyr"))
)

# --- the real check ---------------------------------------------------------
required <- required_packages(unlist(lapply(PIPELINE_FILES, readLines, warn = FALSE)))
imports <- setdiff(description_imports(), BASE_PKGS)
cat("required:", paste(required, collapse = " "), "\n")
cat("imports :", paste(imports, collapse = " "), "\n")

missing <- setdiff(required, imports)
if (length(missing) > 0) {
  stop("DESCRIPTION Imports does not list packages the pipeline needs: ",
       paste(missing, collapse = ", "), call. = FALSE)
}

cat("OK: DESCRIPTION Imports cover every package the pipeline needs\n")
