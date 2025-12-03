# app.R
library(shiny)
library(bslib)
library(tidyverse)
library(scales)
library(plotly)
library(crosstalk)
library(glue)

# --------------------------- Load data ----------------------------------------
apostles_with_labels <- readRDS("derived_data/apostles_with_labels.rds")

# --------------------------- Prep ---------------------------------------------
today <- Sys.Date()

prep <- apostles_with_labels %>%
  mutate(
    # (1) Build display name; ignore blank/NA AND the placeholder middle initial "X"
    mid_clean = ifelse(is.na(Middle) | Middle == "" | Middle == "X", "", paste0(" ", Middle, ".")),
    name = paste0(First, mid_clean, " ", as.character(Last)),
    
    # Ordering by seniority (earlier ordination first)
    seniority = rank(`Ordained Apostle`, ties.method = "first"),
    name = forcats::fct_reorder(name, seniority, .desc = FALSE),
    
    # Enriched fields
    age_at_ordination = as.numeric(floor((`Ordained Apostle` - `Birth Date`) / 365.25)),
    years_in_quorum   = as.numeric(floor((today - `Ordained Apostle`) / 365.25)),
    
    # Tooltip-safe labels
    age_lbl  = sprintf("%.1f", Age),
    prob_lbl = dplyr::if_else(is.na(Prob), "", `Prob Label`),
    
    # Wikipedia link (best-effort)
    wiki_url = paste0("https://en.wikipedia.org/wiki/", gsub(" ", "_", paste(First, as.character(Last))))
  ) %>%
  arrange(seniority)

# Keep a plain tibble for lookups & ggplot, then wrap with highlight_key right before plotting
base_df <- prep

# --------------------------- Plot builders ------------------------------------
age_plot_gg <- function(df) {
  ggplot(
    df,
    aes(
      x = name, y = Age, fill = Age,
      text = glue(
        "<b>{name}</b><br>",
        "Age: {round(Age,1)}<br>",
        "Born: {format(`Birth Date`, '%b %d, %Y')}<br>",
        "Ordained: {format(`Ordained Apostle`, '%b %d, %Y')}<br>",
        "Age at ordination: {age_at_ordination}<br>",
        "Years in Quorum: {years_in_quorum}"
      ),
      key = name
    )
  ) +
    geom_col(width = 0.72, alpha = 0.95) +
    coord_flip() +
    scale_y_continuous(
      "Age (years)",
      limits = c(0, max(df$Age, na.rm = TRUE) * 1.08),
      expand = expansion(mult = c(0, 0.02))
    ) +
    scale_fill_gradient(low = "#C7E9B4", high = "#081D58") +
    labs(x = NULL, title = "Current Age of Apostles") +
    theme_minimal(base_size = 12) +
    theme(
      legend.position = "none",
      panel.grid.major.y = element_blank(),
      panel.grid.minor = element_blank(),
      axis.text.y = element_text(size = 11),
      plot.title = element_text(face = "bold", size = 14, margin = margin(b = 6))
    )
}

prob_plot_gg <- function(df) {
  ggplot(
    df,
    aes(
      x = name, y = Prob, fill = Prob,
      text = glue(
        "<b>{name}</b><br>",
        "Probability: {ifelse(is.na(Prob), '—', scales::percent(Prob, accuracy = 0.1))}<br>",
        "Seniority: {seniority}<br>",
        "Ordained: {format(`Ordained Apostle`, '%b %d, %Y')}<br>",
        "Age at ordination: {age_at_ordination}<br>",
        "Years in Quorum: {years_in_quorum}"
      ),
      key = name
    )
  ) +
    geom_col(width = 0.72, alpha = 0.95, na.rm = TRUE) +
    coord_flip() +
    scale_y_continuous(
      "Probability of Eventually Becoming President",
      labels = percent_format(accuracy = 1),
      limits = c(0, 1),
      expand = expansion(mult = c(0, 0.02))
    ) +
    scale_fill_gradient(low = "#BAE6FD", high = "#0C4A6E", na.value = "#E5E7EB") +
    labs(x = NULL, title = "Succession Probability (by Outliving Those Senior)") +
    theme_minimal(base_size = 12) +
    theme(
      legend.position = "none",
      panel.grid.major.y = element_blank(),
      panel.grid.minor = element_blank(),
      axis.text.y = element_text(size = 11),
      plot.title = element_text(face = "bold", size = 14, margin = margin(b = 6))
    )
}

# --------------------------- UI -----------------------------------------------
ui <- page_fillable(
  theme = bs_theme(
    version = 5,
    base_font = font_google("Inter"),
    heading_font = font_google("Inter"),
    primary = "#0F766E"
  ),
  layout_columns(
    col_widths = c(12, 6, 6),
    
    div(
      class = "mb-3",
      h3("Apostles • Age & Probability"),
      p(class = "text-muted",
        "Click a bar to highlight that apostle across both charts. Click again to unselect. ",
        "Bars are ordered by seniority (ordination date).")
    ),
    
    card(
      full_screen = TRUE,
      card_header("Current Age"),
      card_body(plotlyOutput("age_plot", height = "420px"))
    ),
    
    card(
      full_screen = TRUE,
      card_header("Succession Probability"),
      card_body(plotlyOutput("prob_plot", height = "420px"))
    )
  ),
  
  card(
    full_screen = TRUE,
    card_header("Details"),
    card_body(uiOutput("details_ui"))
  )
)

# --------------------------- Server -------------------------------------------
server <- function(input, output, session) {
  
  # Convert ggplots -> plotly with linked selection (click to select, persistent)
  to_linked_plotly <- function(gg, src_id) {
    ggplotly(gg, tooltip = "text", dynamicTicks = TRUE, source = src_id) %>%
      toRGB() %>%
      highlight(
        on = "plotly_click",
        off = "plotly_doubleclick",
        dynamic = TRUE,
        persistent = TRUE,
        color = I("#E11D48"),
        opacityDim = 0.25,  # opacity for non-selected traces
        selected = attrs_selected(opacity = 1)
      ) %>%
      layout(hoverlabel = list(align = "left"),
             margin = list(l = 10, r = 10, t = 10, b = 10))
  }
  
  output$age_plot <- renderPlotly({
    # Wrap only at plotting time (avoid dplyr on SharedData)
    gg <- age_plot_gg(base_df)
    to_linked_plotly(gg, src_id = "age")
  })
  
  output$prob_plot <- renderPlotly({
    gg <- prob_plot_gg(base_df)
    to_linked_plotly(gg, src_id = "prob")
  })
  
  # Track the most recently clicked name (and keep all selected for highlight)
  # We'll use the most recent click to populate the Details card.
  selected_name <- reactiveVal(NULL)
  
  observeEvent(event_data("plotly_click", source = "age"), {
    k <- event_data("plotly_click", source = "age")$key
    if (length(k)) selected_name(k[length(k)])
  })
  observeEvent(event_data("plotly_click", source = "prob"), {
    k <- event_data("plotly_click", source = "prob")$key
    if (length(k)) selected_name(k[length(k)])
  })
  
  output$details_ui <- renderUI({
    nm <- selected_name()
    df <- base_df
    if (is.null(nm) || !(nm %in% df$name)) {
      tagList(
        p("Click a bar to see details here."),
        tags$small("Shown: current age, date ordained, age at ordination, years in quorum, and a Wikipedia link.")
      )
    } else {
      row <- df %>% filter(name == nm) %>% slice(1)
      tagList(
        h4(row$name),
        p(
          tags$b("Age: "), sprintf("%.1f", row$Age), br(),
          tags$b("Born: "), format(row$`Birth Date`, "%b %d, %Y"), br(),
          tags$b("Ordained Apostle: "), format(row$`Ordained Apostle`, "%b %d, %Y")
        ),
        p(
          tags$b("Age at ordination: "), row$age_at_ordination, br(),
          tags$b("Years in Quorum: "), row$years_in_quorum, br(),
          tags$b("Seniority: "), row$seniority
        ),
        p(
          tags$b("Wikipedia: "), a("Open article", href = row$wiki_url, target = "_blank", rel = "noopener")
        ),
        if (!is.na(row$Prob)) {
          p(tags$b("Probability: "), scales::percent(row$Prob, accuracy = 0.1))
        }
      )
    }
  })
}


shinyApp(ui, server, options = list(host = "0.0.0.0", port = 8080))