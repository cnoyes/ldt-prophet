# app.R
library(shiny)
library(ggplot2)
library(scales)
library(plotly)

# --------------------------- Load data ----------------------------------------
apostles_with_labels <- readRDS("derived_data/apostles_with_labels.rds")

# Add additional calculated fields for tooltips
today <- Sys.Date()
apostles_with_labels$full_name <- paste(apostles_with_labels$First, apostles_with_labels$Last)
apostles_with_labels$ordained_date_formatted <- format(apostles_with_labels$`Ordained Apostle`, "%B %d, %Y")
apostles_with_labels$birth_date_formatted <- format(apostles_with_labels$`Birth Date`, "%B %d, %Y")
apostles_with_labels$years_in_quorum <- as.numeric(floor((today - apostles_with_labels$`Ordained Apostle`) / 365.25))
apostles_with_labels$seniority <- rank(apostles_with_labels$`Ordained Apostle`, ties.method = "first")

# --------------------------- Plot functions -----------------------------------
PlotAge <- function(data) {
  # Create custom tooltip text
  data$tooltip_text <- paste0(
    "<b>", data$full_name, "</b><br>",
    "Age: ", round(data$Age, 1), " years<br>",
    "Born: ", data$birth_date_formatted, "<br>",
    "Ordained: ", data$ordained_date_formatted, "<br>",
    "Years in Quorum: ", data$years_in_quorum, "<br>",
    "Seniority: #", data$seniority
  )

  ggplot(data, aes(x = Last, y = Age, fill = Age, text = tooltip_text)) +
    geom_col(width = 0.7) +
    geom_text(aes(label = `Age Label`), nudge_y = 2, size = 3.5, fontface = "bold") +
    scale_fill_gradient(low = "#C7E9B4", high = "#081D58", guide = "none") +
    labs(
      x = "",
      y = "Age (years)",
      title = "Current Age of Apostles",
      subtitle = "Hover for details • Ordered by seniority"
    ) +
    coord_cartesian(ylim = c(50, 105)) +
    theme_minimal(base_size = 13) +
    theme(
      plot.title = element_text(face = "bold", size = 15, hjust = 0.5, margin = margin(b = 5)),
      plot.subtitle = element_text(color = "gray40", size = 11, hjust = 0.5, margin = margin(b = 15)),
      axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
      axis.text.y = element_blank(),
      panel.grid = element_blank()
    )
}

PlotProb <- function(data) {
  # Create custom tooltip text
  data$tooltip_text <- paste0(
    "<b>", data$full_name, "</b><br>",
    "Probability: ", ifelse(is.na(data$Prob), "—", paste0(round(data$Prob * 100, 1), "%")), "<br>",
    "Age: ", round(data$Age, 1), " years<br>",
    "Ordained: ", data$ordained_date_formatted, "<br>",
    "Years in Quorum: ", data$years_in_quorum, "<br>",
    "Seniority: #", data$seniority
  )

  ggplot(data, aes(x = Last, y = Prob, fill = Prob, text = tooltip_text)) +
    geom_col(width = 0.7) +
    geom_text(aes(label = `Prob Label`), nudge_y = .03, size = 3.5, fontface = "bold") +
    scale_fill_gradient(
      low = "#BAE6FD",
      high = "#0C4A6E",
      na.value = "#E5E7EB",
      guide = "none"
    ) +
    scale_y_continuous(labels = percent_format(accuracy = 1)) +
    labs(
      x = "",
      y = "Probability",
      title = "Succession Probability",
      subtitle = "Hover for details • Based on actuarial modeling"
    ) +
    theme_minimal(base_size = 13) +
    theme(
      plot.title = element_text(face = "bold", size = 15, hjust = 0.5, margin = margin(b = 5)),
      plot.subtitle = element_text(color = "gray40", size = 11, hjust = 0.5, margin = margin(b = 15)),
      axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
      axis.text.y = element_blank(),
      panel.grid = element_blank()
    )
}

# --------------------------- UI -----------------------------------------------
ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      body {
        background-color: #f8f9fa;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      }
      h2 { color: #0C4A6E; font-weight: 600; margin-bottom: 20px; }
      h3 { color: #164E63; font-weight: 600; margin-top: 25px; }
      .info-box {
        background-color: #EFF6FF;
        border-left: 4px solid #0C4A6E;
        padding: 15px;
        margin: 20px 0;
        border-radius: 4px;
      }
      .disclaimer {
        background-color: #FEF3C7;
        border-left: 4px solid #D97706;
        padding: 12px;
        margin: 20px 0;
        font-size: 13px;
        border-radius: 4px;
      }
      .plot-container {
        background-color: white;
        padding: 20px;
        border-radius: 8px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        margin-bottom: 20px;
      }
    "))
  ),

  div(style = "padding: 30px 15px 10px 15px;",
    h1("Prophet Probability Tracker",
       style = "color: #0C4A6E; font-weight: 700; margin-bottom: 5px; margin-top: 0; text-align: center;"),
    p("Statistical analysis of succession probabilities in the Quorum of the Twelve Apostles",
      style = "color: #64748B; font-size: 16px; margin-top: 0; text-align: center;")
  ),

  tabsetPanel(
    id = "main_tabs",
    type = "pills",

    # HOME TAB
    tabPanel(
      "Dashboard",
      br(),
      fluidRow(
        column(12,
          div(class = "info-box",
            h4(style = "margin-top: 0;", "ℹ️ About This Tool"),
            p("This application uses actuarial science and Monte Carlo simulation to estimate the probability
              that each apostle will eventually become President of The Church of Jesus Christ of Latter-day Saints.
              Calculations are based on current ages, seniority (ordination dates), and CDC life expectancy data.")
          )
        )
      ),
      fluidRow(
        column(6,
          div(class = "plot-container",
            plotlyOutput("age_plot", height = "500px")
          )
        ),
        column(6,
          div(class = "plot-container",
            plotlyOutput("prob_plot", height = "500px")
          )
        )
      ),
      fluidRow(
        column(12,
          div(class = "disclaimer",
            strong("⚠️ Disclaimer: "),
            "These probabilities are statistical estimates for educational purposes only.
            They do not represent official church doctrine or predictions.
            Apostolic succession is determined by seniority and inspiration, not probability."
          )
        )
      )
    ),

    # ABOUT TAB
    tabPanel(
      "About",
      br(),
      fluidRow(
        column(10, offset = 1,
          h2("About the Prophet Probability Tracker"),

          h3("What This Tool Does"),
          p("The Prophet Probability Tracker uses actuarial science to calculate the statistical likelihood
            that each member of the Quorum of the Twelve Apostles will eventually serve as President of
            The Church of Jesus Christ of Latter-day Saints."),

          h3("Why It's Interesting"),
          p("Apostolic succession in the LDS Church follows a well-defined pattern: the senior apostle
            (longest serving in the Quorum) becomes the next President. However, determining who will eventually
            serve as President depends on life expectancy and the ages of those senior to each apostle."),

          p("This creates an interesting statistical question: Given current ages and seniority, what is the
            probability that each apostle will outlive all those senior to them and thus become President?"),

          h3("Educational Purpose"),
          p("This tool is designed for:"),
          tags$ul(
            tags$li("Educational exploration of actuarial mathematics"),
            tags$li("Understanding statistical modeling and Monte Carlo simulation"),
            tags$li("Visualizing demographic data about church leadership"),
            tags$li("Appreciating the complexity of succession planning")
          ),

          div(class = "disclaimer",
            strong("Important: "),
            "This analysis is purely statistical and educational. It does not account for revelation,
            inspiration, or unforeseen circumstances. The actual succession is guided by divine will,
            not probability calculations."
          ),

          h3("Data Sources"),
          tags$ul(
            tags$li(tags$a(href = "https://www.churchofjesuschrist.org/study/manual/general-handbook/5-general-and-area-leadership?lang=eng#title_number8",
                          target = "_blank", "Quorum of the Twelve Apostles (Official Church Website)")),
            tags$li(tags$a(href = "https://www.cdc.gov/nchs/products/life_tables.htm",
                          target = "_blank", "CDC Life Tables (Mortality Data)")),
            tags$li("Publicly available biographical information")
          )
        )
      )
    ),

    # METHODOLOGY TAB
    tabPanel(
      "Methodology",
      br(),
      fluidRow(
        column(10, offset = 1,
          h2("Methodology & Technical Details"),

          h3("Overview"),
          p("This analysis uses Monte Carlo simulation with 100,000 iterations to estimate succession probabilities.
            Each simulation models the lifespan of each apostle and determines who becomes President."),

          h3("Step 1: Mortality Modeling"),
          p("We use CDC life table data to model mortality rates by age. A Weibull distribution is fitted to
            this data to create a smooth mortality curve that can predict life expectancy at any age."),

          h3("Step 2: Monte Carlo Simulation"),
          p("For each of 100,000 simulation runs:"),
          tags$ol(
            tags$li("Generate a random death age for each apostle based on their current age and the mortality model"),
            tags$li("Determine which apostle would become President by checking seniority order"),
            tags$li("The apostle who is most senior among those still living becomes President in that simulation"),
            tags$li("Record which apostle became President in this run")
          ),

          h3("Step 3: Probability Calculation"),
          p("After 100,000 simulations, the probability for each apostle is calculated as:"),
          div(style = "background-color: #F1F5F9; padding: 15px; margin: 15px 0; font-family: monospace; border-radius: 4px;",
            "Probability = (Number of times apostle became President) / 100,000"
          ),

          h3("Key Assumptions"),
          tags$ul(
            tags$li("Life expectancy follows CDC mortality data for the general U.S. male population"),
            tags$li("Succession follows strict seniority (ordination date) order"),
            tags$li("No adjustments for health, lifestyle, or other individual factors"),
            tags$li("Current apostles remain in their positions (no resignations or other changes)")
          ),

          h3("Limitations"),
          tags$ul(
            tags$li("Does not account for individual health conditions"),
            tags$li("Uses population-level mortality data, not individual-specific data"),
            tags$li("Cannot predict unforeseen circumstances"),
            tags$li("Assumes mortality patterns remain constant over time")
          ),

          h3("Technical Implementation"),
          p("Built with:"),
          tags$ul(
            tags$li("R programming language for statistical analysis"),
            tags$li("Shiny framework for web application"),
            tags$li("ggplot2 for data visualization"),
            tags$li("Weibull distribution for mortality modeling")
          ),

          div(class = "info-box",
            h4(style = "margin-top: 0;", "📦 Open Source"),
            p("This project is open source. View the code and methodology at: ",
              tags$a(href = "https://github.com/cnoyes/apostles", target = "_blank",
                    "github.com/cnoyes/apostles"))
          )
        )
      )
    )
  ),

  # Footer
  hr(),
  div(style = "text-align: center; color: #94A3B8; padding: 20px;",
    p("Prophet Probability Tracker | Statistical analysis for educational purposes only"),
    p(style = "font-size: 12px;",
      "Not affiliated with The Church of Jesus Christ of Latter-day Saints | ",
      tags$a(href = "https://github.com/cnoyes/apostles", target = "_blank", "View on GitHub"))
  )
)

# --------------------------- Server -------------------------------------------
server <- function(input, output, session) {

  output$age_plot <- renderPlotly({
    p <- PlotAge(apostles_with_labels)
    ggplotly(p, tooltip = "text") %>%
      layout(
        hoverlabel = list(bgcolor = "white", font = list(size = 12)),
        margin = list(l = 50, r = 50, t = 80, b = 100)
      ) %>%
      config(displayModeBar = FALSE)  # Hide plotly toolbar for cleaner look
  })

  output$prob_plot <- renderPlotly({
    p <- PlotProb(apostles_with_labels)
    ggplotly(p, tooltip = "text") %>%
      layout(
        hoverlabel = list(bgcolor = "white", font = list(size = 12)),
        margin = list(l = 50, r = 50, t = 80, b = 100)
      ) %>%
      config(displayModeBar = FALSE)  # Hide plotly toolbar for cleaner look
  })
}

shinyApp(ui, server, options = list(host = "0.0.0.0", port = 8080))
