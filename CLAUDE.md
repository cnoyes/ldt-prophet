# CLAUDE.md

This file provides **mandatory instructions** to Claude Code (claude.ai/code) when working with code in this repository.

---

## 🌐 CENTRAL DOCUMENTATION

**BEFORE MAKING ANY CHANGES**, read the ecosystem documentation in ldt-data:

```
../ldt-data/docs/ECOSYSTEM.md  - All repos and architecture
../ldt-data/docs/ROADMAP.md    - Phases and priorities
```

Or on GitHub: https://github.com/cnoyes/ldt-data/tree/main/docs

This ensures you understand how this repo fits into the larger LatterDay Tools ecosystem.

---

## ⚠️ MANDATORY PRACTICES

**You MUST:**
1. ✅ Create feature branches for all non-trivial work (NEVER commit directly to main)
2. ✅ Create GitHub issues before starting features
3. ✅ Use plan mode for features requiring 3+ file changes
4. ✅ Follow conventional commit format
5. ✅ Write tests for new features (when applicable)
6. ✅ Update documentation for user-facing changes

**Branch naming**: `<type>/<issue-number>-<brief-description>`
**Commit format**: `<type>(<scope>): <subject>`

---

## Project Overview

**Apostles Prophet-ability Calculator** - An interactive R Shiny application that calculates and visualizes the probability of each apostle of The Church of Jesus Christ of Latter-day Saints becoming prophet, based on actuarial life expectancy data and succession order.

**Technology Stack**: R + Shiny + ggplot2 + plotly
**Simulation Method**: Monte Carlo (100,000 runs)
**Mortality Model**: Weibull distribution fitted to CDC life table data

---

## Key Commands

### Running the Application

```bash
# Start the Shiny app on port 8080
Rscript app.R

# Or use the run script
Rscript run.R
```

The app will be available at `http://0.0.0.0:8080`

### Regenerating Data

```bash
# Regenerate all derived data (run after updating apostles.csv)
Rscript run_all.R
```

This will:
1. Load apostle data from `raw_data/apostles.csv`
2. Fit Weibull distribution to CDC mortality data
3. Run 100,000 Monte Carlo simulations
4. Generate all `.rds` files in `derived_data/`

### Development Setup

```bash
# Install required packages
R -e "install.packages(c('shiny', 'bslib', 'tidyverse', 'scales', 'plotly', 'glue', 'MASS'))"
```

---

## Architecture

### Data Processing Pipeline

The project follows a sequential data processing pipeline:

```
raw_data/ → src/ scripts → derived_data/ → app.R (Shiny)
```

**Pipeline Steps** (executed by `run_all.R`):
1. `src/1_load_apostles.R` - Load and process apostle data
2. `src/2_fit_death_curve.R` - Fit Weibull distribution to CDC mortality data
3. `src/3_calculate_prophet.R` - Run Monte Carlo simulations + timeline probabilities
4. `src/4_make_plots.R` - Create plotting functions (used by Shiny app)

### Shiny Application Structure

**app.R** - Main Shiny application with:
- Interactive plotly charts (age + succession probability)
- Click-to-highlight functionality across both charts
- Detailed information panel for selected apostles
- Mobile-responsive design

### Key Components

1. **Data Sources**:
   - `raw_data/apostles.csv` - Apostle birth and ordination dates
   - `raw_data/Table05.csv` - CDC life table mortality data

2. **Derived Data** (in `derived_data/`):
   - `apostles_with_labels.rds` - Processed apostle data
   - `simulation_results.rds` - Monte Carlo simulation results
   - `weibull_params.rds` - Fitted mortality model parameters
   - `timeline.rds` - Monthly prophet probabilities over 30 years (who is prophet at each time point)

3. **Simulation Logic**:
   - For each simulation: sample death age for each apostle
   - Determine prophet by succession order (who outlives seniors)
   - Aggregate results across 100,000 simulations
   - Timeline: for each monthly time point over 30 years, determine who is the most senior living apostle in each simulation

### Important Files

- `app.R` - Main Shiny application (interactive UI)
- `run_all.R` - Master script to regenerate all derived data
- `src/1_load_apostles.R` - Data loading and preprocessing
- `src/2_fit_death_curve.R` - Mortality model fitting
- `src/3_calculate_prophet.R` - Monte Carlo simulation engine + timeline computation
- `src/4_make_plots.R` - Plotting functions
- `scripts/export_to_json.R` - Export derived data to JSON for Next.js frontend
- `web/components/TimelineChart.tsx` - Timeline line chart (prophet probability over time)
- `raw_data/apostles.csv` - Source data for apostles
- `raw_data/Table05.csv` - CDC mortality data

---

## Data Management

### Updating Apostle Data

To add or update apostle information:

1. Edit `raw_data/apostles.csv`:
   ```csv
   Name,Birth Date,Ordained Apostle
   First Middle Last,YYYY-MM-DD,YYYY-MM-DD
   ```

2. Regenerate derived data:
   ```bash
   Rscript run_all.R
   ```

3. Restart the Shiny app

### Data Flow

```
apostles.csv → 1_load_apostles.R → apostles_with_labels.rds
                                           ↓
Table05.csv → 2_fit_death_curve.R → weibull_params.rds
                                           ↓
                    3_calculate_prophet.R → simulation_results.rds
                                         ↓ → timeline.rds
                              4_make_plots.R (functions)
                                           ↓
                                        app.R (Shiny UI)
```

---

## Common Patterns

### Adding New Visualizations

1. Create plotting function in `src/4_make_plots.R`
2. Load required data in `app.R`
3. Add plotly output to UI
4. Add render function to server

### Modifying Simulation Parameters

Edit `src/3_calculate_prophet.R`:
- `n_sims` - Number of Monte Carlo simulations (default: 100,000)
- Weibull parameters loaded from `weibull_params.rds`

### Customizing Mortality Model

Edit `src/2_fit_death_curve.R`:
- Currently uses Weibull distribution
- Fitted to CDC life table data (Table05.csv)
- Can substitute alternative mortality models

---

## Deployment

### Local Development
```bash
Rscript app.R  # Runs on port 8080
```

### Production Deployment

The app is configured for deployment to:
- **shinyapps.io** - Using `rsconnect` package
- **Posit Connect** - Standard Shiny deployment
- **Shiny Server** - Open source option

Before deploying:
1. Ensure all derived data is generated (`Rscript run_all.R`)
2. Verify all dependencies are installed
3. Test locally on port 8080

---

## Troubleshooting

### Common Issues

1. **Issue**: App fails to start with "object not found" errors
   **Solution**: Run `Rscript run_all.R` to regenerate derived data files

2. **Issue**: Plots not displaying correctly
   **Solution**: Verify ggplot2 and plotly packages are installed

3. **Issue**: Simulation results seem incorrect
   **Solution**: Check that `raw_data/apostles.csv` has valid dates and is sorted by ordination date

4. **Issue**: Mobile display issues
   **Solution**: Margins and font sizes are optimized in app.R (lines 42-48, 72-78)

---

## Development Workflow

### Making Changes

1. Create feature branch: `git checkout -b feature/description`
2. Make changes to relevant files
3. Test locally: `Rscript app.R`
4. If data pipeline changed: `Rscript run_all.R`
5. Commit with conventional format: `feat(ui): add new chart`
6. Create pull request

### Testing Checklist

- [ ] App starts without errors
- [ ] Both charts display correctly
- [ ] Click-to-highlight works across both charts
- [ ] Mobile responsive layout works
- [ ] Tooltips show correct information
- [ ] All apostles appear in correct seniority order

---

## Additional Resources

- **Methodology**: See README.md for Monte Carlo simulation details
- **Data Sources**: CDC National Vital Statistics Reports
- **Shiny Documentation**: https://shiny.posit.co/
- **plotly R Documentation**: https://plotly.com/r/

---

**Last Updated**: 2025-12-04
**Project Type**: R Shiny Application
**Purpose**: Educational/Statistical Analysis
