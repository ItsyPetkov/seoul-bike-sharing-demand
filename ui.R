library(shiny)
library(shinydashboard)
library(tidyverse)
library(tidymodels)
library(DT)
library(ggplot2)
library(scales)

ui <- dashboardPage(
  skin = "blue",
  
  # Header
  dashboardHeader(
    title = "Seoul Bike Sharing Prediction Dashboard",
    titleWidth = 350,
    tags$li(class = "dropdown", 
            tags$a(href = "https://github.com", 
                   icon("github"), 
                   "GitHub",
                   target = "_blank"))
  ),
  
  # Sidebar
  dashboardSidebar(
    width = 250,
    sidebarMenu(
      id = "tabs",
      menuItem("Dashboard", tabName = "dashboard", icon = icon("tachometer-alt")),
      menuItem("Model Comparison", tabName = "comparison", icon = icon("chart-bar")),
      menuItem("Detailed Analysis", tabName = "analysis", icon = icon("microscope")),
      menuItem("Model Selection", tabName = "selection", icon = icon("hand-pointer")),
      menuItem("Predictions", tabName = "predictions", icon = icon("crystal-ball")),
      menuItem("Data Explorer", tabName = "explorer", icon = icon("database")),
      menuItem("About", tabName = "about", icon = icon("info-circle"))
    )
  ),
  
  # Body
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .box-header { background-color: #f4f4f4; }
        .info-box { margin-bottom: 20px; }
        .model-card { padding: 15px; margin: 10px 0; border-radius: 5px; }
        .lm-card { background-color: #e3f2fd; border-left: 4px solid #1976d2; }
        .xgb-card { background-color: #f3e5f5; border-left: 4px solid #7b1fa2; }
      "))
    ),
    
    tabItems(
      
      # ============================================================
      # TAB 1: DASHBOARD
      # ============================================================
      tabItem(tabName = "dashboard",
        h2("Performance Overview"),
        
        fluidRow(
          infoBoxOutput("best_model_box"),
          infoBoxOutput("total_models_box"),
          infoBoxOutput("best_rsq_box")
        ),
        
        fluidRow(
          box(
            title = "Model Performance Summary",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            width = 12,
            DT::dataTableOutput("dashboard_table")
          )
        ),
        
        fluidRow(
          box(
            title = "Best Model Details",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            verbatimTextOutput("best_model_summary")
          ),
          box(
            title = "Top 5 Models by R-squared",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            DT::dataTableOutput("top_models_table")
          )
        )
      ),
      
      # ============================================================
      # TAB 2: MODEL COMPARISON
      # ============================================================
      tabItem(tabName = "comparison",
        h2("Model Comparison Visualizations"),
        
        fluidRow(
          box(
            title = "R-squared Comparison",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            plotOutput("rsq_plot", height = 400)
          ),
          box(
            title = "RMSE Comparison",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            plotOutput("rmse_plot", height = 400)
          )
        ),
        
        fluidRow(
          box(
            title = "MAE Comparison",
            status = "danger",
            solidHeader = TRUE,
            width = 6,
            plotOutput("mae_plot", height = 400)
          ),
          box(
            title = "MAPE Comparison",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            plotOutput("mape_plot", height = 400)
          )
        ),
        
        fluidRow(
          box(
            title = "Multi-Metric Comparison (Normalized)",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            plotOutput("multi_metric_plot", height = 500)
          )
        )
      ),
      
      # ============================================================
      # TAB 3: DETAILED ANALYSIS
      # ============================================================
      tabItem(tabName = "analysis",
        h2("Detailed Performance Analysis"),
        
        fluidRow(
          column(
            width = 3,
            box(
              title = "Filter by Model Type",
              status = "primary",
              solidHeader = TRUE,
              width = 12,
              radioButtons("model_type_filter", 
                          label = "Select Model Type:",
                          choices = list("All Models" = "all",
                                       "Linear Regression" = "lm",
                                       "XGBoost" = "xgb"),
                          selected = "all")
            )
          ),
          column(
            width = 9,
            box(
              title = "Filtered Model Results",
              status = "info",
              solidHeader = TRUE,
              width = 12,
              DT::dataTableOutput("filtered_results_table")
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Model Performance Heatmap",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            plotOutput("heatmap_plot", height = 500)
          )
        ),
        
        fluidRow(
          box(
            title = "Performance Statistics",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            verbatimTextOutput("perf_stats")
          )
        )
      ),
      
      # ============================================================
      # TAB 4: MODEL SELECTION
      # ============================================================
      tabItem(tabName = "selection",
        h2("Model Selection Tool"),
        
        fluidRow(
          box(
            title = "Select Best Model By Metric",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            width = 12,
            
            column(
              width = 4,
              radioButtons("metric_select", 
                          label = "Choose Optimization Metric:",
                          choices = list("R-squared (Higher is Better)" = "RSQ",
                                       "RMSE (Lower is Better)" = "RMSE",
                                       "MAE (Lower is Better)" = "MAE",
                                       "MAPE (Lower is Better)" = "MAPE"))
            ),
            column(
              width = 8,
              box(
                title = "Best Model",
                status = "success",
                solidHeader = TRUE,
                width = 12,
                textOutput("selected_best_model"),
                br(),
                verbatimTextOutput("selected_model_stats")
              )
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Recommendations by Use Case",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            HTML("
              <h4>📊 Use Case Recommendations:</h4>
              <ul>
                <li><strong>Maximum Accuracy:</strong> Select model with highest R-squared</li>
                <li><strong>Minimize Large Errors:</strong> Select model with lowest RMSE</li>
                <li><strong>Average Error Reduction:</strong> Select model with lowest MAE</li>
                <li><strong>Percentage Error Focus:</strong> Select model with lowest MAPE</li>
                <li><strong>Speed Priority:</strong> Linear Regression models are faster</li>
                <li><strong>Non-linear Patterns:</strong> XGBoost captures complex patterns</li>
              </ul>
            ")
          )
        )
      ),
      
      # ============================================================
      # TAB 5: PREDICTIONS
      # ============================================================
      tabItem(tabName = "predictions",
        h2("Make Predictions"),
        
        fluidRow(
          box(
            title = "Select Model for Predictions",
            status = "primary",
            solidHeader = TRUE,
            width = 3,
            selectInput("pred_model_select",
                       label = "Choose Model:",
                       choices = c("lm_weather" = "lm_weather",
                                 "lm_weather_poly" = "lm_weather_poly",
                                 "lm_weather_poly_int" = "lm_weather_poly_int",
                                 "lm_all" = "lm_all",
                                 "lm_all_poly" = "lm_all_poly",
                                 "xgb_weather" = "xgb_weather",
                                 "xgb_weather_poly" = "xgb_weather_poly",
                                 "xgb_weather_poly_int" = "xgb_weather_poly_int",
                                 "xgb_all" = "xgb_all",
                                 "xgb_all_poly" = "xgb_all_poly"))
          ),
          
          box(
            title = "Input Features",
            status = "warning",
            solidHeader = TRUE,
            width = 9,
            
            fluidRow(
              column(3, numericInput("temp_input", "Temperature", value = 20, min = -20, max = 50, step = 0.5)),
              column(3, numericInput("humidity_input", "Humidity", value = 50, min = 0, max = 100, step = 1)),
              column(3, numericInput("wind_input", "Wind Speed", value = 2, min = 0, max = 20, step = 0.1)),
              column(3, numericInput("visibility_input", "Visibility", value = 1000, min = 0, max = 2000, step = 10))
            ),
            
            fluidRow(
              column(3, numericInput("solar_input", "Solar Radiation", value = 50, min = 0, max = 100, step = 1)),
              column(3, numericInput("rainfall_input", "Rainfall", value = 0, min = 0, max = 100, step = 0.1)),
              column(3, numericInput("dew_input", "Dew Point Temp", value = 10, min = -30, max = 40, step = 0.5)),
              column(3, actionButton("predict_btn", "Get Prediction", class = "btn-success"))
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Prediction Result",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            textOutput("prediction_result"),
            br(),
            verbatimTextOutput("prediction_details")
          )
        ),
        
        fluidRow(
          box(
            title = "Model Information",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            verbatimTextOutput("prediction_model_info")
          )
        )
      ),
      
      # ============================================================
      # TAB 6: DATA EXPLORER
      # ============================================================
      tabItem(tabName = "explorer",
        h2("Data Explorer"),
        
        fluidRow(
          box(
            title = "Dataset Summary",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            verbatimTextOutput("data_summary")
          ),
          box(
            title = "Data Structure",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            verbatimTextOutput("data_structure")
          )
        ),
        
        fluidRow(
          box(
            title = "Raw Test Data (First 50 rows)",
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            DT::dataTableOutput("raw_data_table")
          )
        ),
        
        fluidRow(
          box(
            title = "Variable Statistics",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            DT::dataTableOutput("var_stats_table")
          )
        )
      ),
      
      # ============================================================
      # TAB 7: ABOUT
      # ============================================================
      tabItem(tabName = "about",
        h2("About This Dashboard"),
        
        box(
          title = "Seoul Bike Sharing Prediction System",
          status = "info",
          solidHeader = TRUE,
          width = 12,
          style = "overflow-y: auto; max-height: 80vh;",
          HTML("
            <div style='font-size: 14px; line-height: 1.6;'>
              <h4>📋 Project Overview</h4>
              <p>This dashboard visualizes the performance of 10 different machine learning models trained to predict 
              bike rental demand in Seoul based on weather and temporal features.</p>
              
              <h4>🎯 Models Included</h4>
              <p><strong>Linear Regression (5 variants):</strong></p>
              <ul>
                <li>Weather features only</li>
                <li>Weather + polynomial terms</li>
                <li>Weather + polynomial + interaction terms</li>
                <li>All available variables</li>
                <li>All variables + polynomial terms</li>
              </ul>
              
              <p><strong>XGBoost (5 variants):</strong></p>
              <ul>
                <li>Weather features only</li>
                <li>Weather + polynomial terms</li>
                <li>Weather + polynomial + interaction terms</li>
                <li>All available variables</li>
                <li>All variables + polynomial terms</li>
              </ul>
              
              <h4>📊 Evaluation Metrics</h4>
              <ul>
                <li><strong>R-squared (RSQ):</strong> Proportion of variance explained (0-1, higher is better)</li>
                <li><strong>RMSE:</strong> Root Mean Squared Error (lower is better)</li>
                <li><strong>MAE:</strong> Mean Absolute Error (lower is better)</li>
                <li><strong>MAPE:</strong> Mean Absolute Percentage Error (lower is better)</li>
              </ul>
              
              <h4>🔧 Features Used</h4>
              <ul>
                <li>Temperature</li>
                <li>Humidity</li>
                <li>Wind Speed</li>
                <li>Visibility</li>
                <li>Dew Point Temperature</li>
                <li>Solar Radiation</li>
                <li>Rainfall</li>
                <li>Engineered interactions (Temperature × Humidity, etc.)</li>
              </ul>
              
              <h4>📁 Project Structure</h4>
              <ul>
                <li>main.R - Training and evaluation pipeline</li>
                <li>ui.R - User interface definition</li>
                <li>server.R - Server-side logic</li>
                <li>checkpoints/ - Saved model weights</li>
                <li>data/ - Preprocessed datasets</li>
              </ul>
              
              <h4>🚀 How to Use</h4>
              <ol>
                <li>View overall performance in the <strong>Dashboard</strong> tab</li>
                <li>Compare models visually in <strong>Model Comparison</strong></li>
                <li>Deep dive with <strong>Detailed Analysis</strong></li>
                <li>Select best model for your use case in <strong>Model Selection</strong></li>
                <li>Make predictions in <strong>Predictions</strong> tab</li>
                <li>Explore raw data in <strong>Data Explorer</strong></li>
              </ol>
            </div>
          ")
        )
      )
    )
  )
)