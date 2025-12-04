# app.R
library(shiny)
library(ggplot2)
library(scales)

# --------------------------- Load data ----------------------------------------
apostles_with_labels <- readRDS("derived_data/apostles_with_labels.rds")

# --------------------------- Plot functions -----------------------------------
PlotAge <- function(apostles_with_labels) {
  ggplot(apostles_with_labels, aes(x = Last, y = Age, label = `Age Label`)) +
    geom_bar(stat = "identity", fill = 'darkblue') +
    geom_text(nudge_y = 2) +
    labs(x = "", y = "Age", title = "Ages of the Apostles") +
    coord_cartesian(ylim = c(50, 105)) +
    theme_minimal(base_size = 14) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          axis.text.y = element_blank(),
          panel.grid = element_blank())
}

PlotProb <- function(apostles_with_labels) {
  ggplot(apostles_with_labels,
         aes(x = Last, y = Prob, label = `Prob Label`)) +
    geom_bar(stat = "identity", fill = 'darkblue') +
    geom_text(nudge_y = .02) +
    labs(x = "", y = "Probability", title = "Probability of Becoming Prophet") +
    scale_y_continuous(labels = scales::percent) +
    theme_minimal(base_size = 14) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          axis.text.y = element_blank(),
          panel.grid = element_blank())
}

# --------------------------- UI -----------------------------------------------
ui <- fluidPage(
  titlePanel("Apostles - Age & Probability"),

  fluidRow(
    column(6, plotOutput("age_plot", height = "500px")),
    column(6, plotOutput("prob_plot", height = "500px"))
  )
)

# --------------------------- Server -------------------------------------------
server <- function(input, output, session) {

  output$age_plot <- renderPlot({
    PlotAge(apostles_with_labels)
  })

  output$prob_plot <- renderPlot({
    PlotProb(apostles_with_labels)
  })
}

shinyApp(ui, server, options = list(host = "0.0.0.0", port = 8080))