#!/usr/bin/env Rscript
# Export apostles data to JSON for Next.js frontend

library(jsonlite)

# Load the data
apostles_with_labels <- readRDS("derived_data/apostles_with_labels.rds")

# Calculate additional fields
today <- Sys.Date()
apostles_with_labels$years_in_quorum <- as.numeric(floor((today - apostles_with_labels$`Ordained Apostle`) / 365.25))
apostles_with_labels$seniority <- rank(apostles_with_labels$`Ordained Apostle`, ties.method = "first")

# Create clean data structure for JSON
apostles_json <- data.frame(
  id = seq_len(nrow(apostles_with_labels)),
  firstName = apostles_with_labels$First,
  middleName = ifelse(is.na(apostles_with_labels$Middle) | apostles_with_labels$Middle == "",
                      NA, apostles_with_labels$Middle),
  lastName = apostles_with_labels$Last,
  fullName = paste(apostles_with_labels$First, apostles_with_labels$Last),
  age = round(apostles_with_labels$Age, 1),
  birthDate = as.character(apostles_with_labels$`Birth Date`),
  ordinationDate = as.character(apostles_with_labels$`Ordained Apostle`),
  yearsInQuorum = apostles_with_labels$years_in_quorum,
  seniority = apostles_with_labels$seniority,
  probability = ifelse(is.na(apostles_with_labels$Prob), NA, round(apostles_with_labels$Prob, 4)),
  probabilityPercent = ifelse(is.na(apostles_with_labels$Prob), NA,
                              round(apostles_with_labels$Prob * 100, 1))
)

# Order by seniority
apostles_json <- apostles_json[order(apostles_json$seniority), ]

# Create metadata
metadata <- list(
  generatedAt = as.character(Sys.time()),
  totalApostles = nrow(apostles_json),
  simulationRuns = 100000,
  description = "Apostolic succession probability data based on Monte Carlo simulation"
)

# Combine into final structure
output <- list(
  metadata = metadata,
  apostles = apostles_json
)

# Export to JSON (both locations)
web_path <- "web/public/apostles.json"
legacy_path <- "public/data/apostles.json"

dir.create(dirname(web_path), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(legacy_path), recursive = TRUE, showWarnings = FALSE)

write_json(output, web_path, pretty = TRUE, auto_unbox = TRUE)
write_json(output, legacy_path, pretty = TRUE, auto_unbox = TRUE)

cat("✓ Data exported to", web_path, "\n")
cat("✓ Data exported to", legacy_path, "\n")
cat("  Total apostles:", nrow(apostles_json), "\n")
cat("  Generated at:", as.character(Sys.time()), "\n")
