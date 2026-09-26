library(shiny)
library(shinydashboard)
library(tidyverse)
library(tidymodels)
library(DT)
library(ggplot2)
library(scales)

# ============================================================
# LOAD DATA AND MODELS
# ============================================================

source("utils.R")
source("features/build_features.R")
source("models/train_model.R")
source("models/evaluate_model.R")

# Load evaluation results
load_evaluation_results <- function() {
  if (file.exists("results/model_evaluation_results.csv")) {
    df <- read_csv("results/model_evaluation_results.csv", show_col_types = FALSE)
    return(as.data.frame(df) %>% as_tibble())
  } else {
    return(tibble(Model = character(), RSQ = numeric(), 
                  RMSE = numeric(), MAE = numeric(), MAPE = numeric()))
  }
}

# Load test data
load_test_data <- function() {
  tryCatch({
    return(read_csv("data_preprocessed/processed_seoul_bike_sharing_normalized.csv", show_col_types = FALSE))
  }, error = function(e) {
    return(NULL)
  })
}

# Load all trained models
load_all_models <- function() {
  tryCatch({
    models <- list(
      lm_weather = readRDS("checkpoints/lm_model_weather.rds"),
      lm_weather_poly = readRDS("checkpoints/lm_model_weather_poly.rds"),
      lm_weather_poly_int = readRDS("checkpoints/lm_model_weather_poly_interaction.rds"),
      lm_all = readRDS("checkpoints/lm_model_all.rds"),
      lm_all_poly = readRDS("checkpoints/lm_model_all_poly.rds"),
      xgb_weather = readRDS("checkpoints/xgb_model_weather.rds"),
      xgb_weather_poly = readRDS("checkpoints/xgb_model_weather_poly.rds"),
      xgb_weather_poly_int = readRDS("checkpoints/xgb_model_weather_poly_interaction.rds"),
      xgb_all = readRDS("checkpoints/xgb_model_all.rds"),
      xgb_all_poly = readRDS("checkpoints/xgb_model_all_poly.rds")
    )
    return(models)
  }, error = function(e) {
    return(NULL)
  })
}

# Model names mapping
get_model_display_names <- function() {
  c(
    "lm_model_weather" = "LM: Weather Only",
    "lm_model_weather_poly" = "LM: Weather + Polynomial",
    "lm_model_weather_poly_interaction" = "LM: Weather + Poly + Interaction",
    "lm_model_all" = "LM: All Variables",
    "lm_model_all_poly" = "LM: All Vars + Polynomial",
    "xgb_model_weather" = "XGBoost: Weather Only",
    "xgb_model_weather_poly" = "XGBoost: Weather + Polynomial",
    "xgb_model_weather_poly_interaction" = "XGBoost: Weather + Poly + Int",
    "xgb_model_all" = "XGBoost: All Variables",
    "xgb_model_all_poly" = "XGBoost: All Vars + Polynomial"
  )
}

# ============================================================
# SERVER LOGIC
# ============================================================

server <- function(input, output, session) {
  
  # Reactive values
  eval_data <- reactiveVal(load_evaluation_results())
  test_data <- reactiveVal(load_test_data())
  trained_models <- reactiveVal(load_all_models())
  
  # Ensure data directory exists
  if (!dir.exists("data")) {
    dir.create("data", showWarnings = FALSE)
  }
  
  # ============================================================
  # TAB 1: DASHBOARD
  # ============================================================
  
  output$best_model_box <- renderInfoBox({
    df <- eval_data()
    if (is.null(df) || nrow(df) == 0) {
      infoBox(
        title = "Best Model",
        value = "No Data",
        icon = icon("chart-line"),
        color = "red"
      )
    } else {
      best_idx <- which.max(df$RSQ)
      best_model <- df[best_idx, ]
      infoBox(
        title = "Best Model (by R²)",
        value = best_model$Model,
        subtitle = paste("RSQ:", round(best_model$RSQ, 4)),
        icon = icon("chart-line"),
        color = "green"
      )
    }
  })
  
  output$total_models_box <- renderInfoBox({
    infoBox(
      title = "Total Models",
      value = 10,
      subtitle = "5 LM + 5 XGBoost",
      icon = icon("cubes"),
      color = "blue"
    )
  })
  
  output$best_rsq_box <- renderInfoBox({
    df <- eval_data()
    if (is.null(df) || nrow(df) == 0) {
      best_rsq <- 0
    } else {
      best_rsq <- max(df$RSQ, na.rm = TRUE)
    }
    infoBox(
      title = "Best R-squared",
      value = round(best_rsq, 4),
      subtitle = "Variance Explained",
      icon = icon("trophy"),
      color = "yellow"
    )
  })
  
  output$dashboard_table <- DT::renderDataTable({
    df <- eval_data()
    if (is.null(df) || nrow(df) == 0) {
      return(data.frame(Message = "No evaluation data available"))
    }
    
    df <- df %>%
      mutate(
        Model = get_model_display_names()[Model],
        RSQ = round(RSQ, 4),
        RMSE = round(RMSE, 2),
        MAE = round(MAE, 2),
        MAPE = round(MAPE, 4)
      ) %>%
      arrange(desc(RSQ))
    
    DT::datatable(df, 
                  options = list(pageLength = 10, autoWidth = TRUE),
                  rownames = FALSE)
  })
  
  output$best_model_summary <- renderPrint({
    df <- eval_data()
    if (is.null(df) || nrow(df) == 0) {
      cat("No evaluation data available\n")
    } else {
      best_idx <- which.max(df$RSQ)
      best_model <- df[best_idx, ]
      cat("Best Performing Model Summary\n")
      cat("================================\n\n")
      cat("Model:", get_model_display_names()[best_model$Model], "\n")
      cat("R-squared:", round(best_model$RSQ, 6), "\n")
      cat("RMSE:", round(best_model$RMSE, 2), "\n")
      cat("MAE:", round(best_model$MAE, 2), "\n")
      cat("MAPE:", round(best_model$MAPE, 6), "\n")
      cat("\nInterpretation:\n")
      cat(paste0("  - This model explains ", round(best_model$RSQ * 100, 2), 
                 "% of the variance in bike rental demand.\n"))
      cat(paste0("  - Average prediction error (RMSE): ", round(best_model$RMSE, 0), " bikes.\n"))
      cat(paste0("  - Average absolute error (MAE): ", round(best_model$MAE, 0), " bikes.\n"))
    }
  })
  
  output$top_models_table <- DT::renderDataTable({
    df <- eval_data()
    if (is.null(df) || nrow(df) == 0) {
      return(data.frame(Message = "No evaluation data available"))
    }
    
    df <- df %>%
      mutate(Model = get_model_display_names()[Model]) %>%
      arrange(desc(RSQ))
    
    top_n <- min(5, nrow(df))
    df <- df[1:top_n, ] %>%
      select(Model, RSQ) %>%
      mutate(Rank = row_number(), RSQ = round(RSQ, 4)) %>%
      select(Rank, Model, RSQ)
    
    DT::datatable(df, 
                  options = list(pageLength = 5, autoWidth = TRUE),
                  rownames = FALSE)
  })
  
  # ============================================================
  # TAB 2: MODEL COMPARISON
  # ============================================================
  
  output$rsq_plot <- renderPlot({
    df <- eval_data()
    if (is.null(df) || nrow(df) == 0) return(NULL)
    
    df %>%
      mutate(Model = get_model_display_names()[Model],
             Type = ifelse(grepl("xgb", tolower(Model)), "XGBoost", "Linear Regression")) %>%
      arrange(RSQ) %>%
      mutate(Model = factor(Model, levels = unique(Model))) %>%
      ggplot(aes(x = Model, y = RSQ, fill = Type)) +
      geom_bar(stat = "identity") +
      theme_minimal() +
      coord_flip() +
      labs(title = "R-squared by Model", y = "R-squared") +
      scale_fill_manual(values = c("Linear Regression" = "#1976d2", "XGBoost" = "#7b1fa2")) +
      theme(axis.title.y = element_blank(), legend.position = "bottom")
  })
  
  output$rmse_plot <- renderPlot({
    df <- eval_data()
    if (is.null(df) || nrow(df) == 0) return(NULL)
    
    df %>%
      mutate(Model = get_model_display_names()[Model],
             Type = ifelse(grepl("xgb", tolower(Model)), "XGBoost", "Linear Regression")) %>%
      arrange(RMSE) %>%
      mutate(Model = factor(Model, levels = unique(Model))) %>%
      ggplot(aes(x = Model, y = RMSE, fill = Type)) +
      geom_bar(stat = "identity") +
      theme_minimal() +
      coord_flip() +
      labs(title = "RMSE by Model (Lower is Better)", y = "RMSE") +
      scale_fill_manual(values = c("Linear Regression" = "#1976d2", "XGBoost" = "#7b1fa2")) +
      theme(axis.title.y = element_blank(), legend.position = "bottom")
  })
  
  output$mae_plot <- renderPlot({
    df <- eval_data()
    if (is.null(df) || nrow(df) == 0) return(NULL)
    
    df %>%
      mutate(Model = get_model_display_names()[Model],
             Type = ifelse(grepl("xgb", tolower(Model)), "XGBoost", "Linear Regression")) %>%
      arrange(MAE) %>%
      mutate(Model = factor(Model, levels = unique(Model))) %>%
      ggplot(aes(x = Model, y = MAE, fill = Type)) +
      geom_bar(stat = "identity") +
      theme_minimal() +
      coord_flip() +
      labs(title = "MAE by Model (Lower is Better)", y = "MAE") +
      scale_fill_manual(values = c("Linear Regression" = "#1976d2", "XGBoost" = "#7b1fa2")) +
      theme(axis.title.y = element_blank(), legend.position = "bottom")
  })
  
  output$mape_plot <- renderPlot({
    df <- eval_data()
    if (is.null(df) || nrow(df) == 0) return(NULL)
    
    df %>%
      mutate(Model = get_model_display_names()[Model],
             Type = ifelse(grepl("xgb", tolower(Model)), "XGBoost", "Linear Regression")) %>%
      arrange(MAPE) %>%
      mutate(Model = factor(Model, levels = unique(Model))) %>%
      ggplot(aes(x = Model, y = MAPE, fill = Type)) +
      geom_bar(stat = "identity") +
      theme_minimal() +
      coord_flip() +
      labs(title = "MAPE by Model (Lower is Better)", y = "MAPE") +
      scale_fill_manual(values = c("Linear Regression" = "#1976d2", "XGBoost" = "#7b1fa2")) +
      theme(axis.title.y = element_blank(), legend.position = "bottom")
  })
  
  output$multi_metric_plot <- renderPlot({
    df <- eval_data()
    if (is.null(df) || nrow(df) == 0) return(NULL)
    
    df_norm <- df %>%
      mutate(
        RSQ_norm = RSQ / max(RSQ, na.rm = TRUE),
        RMSE_norm = 1 - (RMSE / max(RMSE, na.rm = TRUE)),
        MAE_norm = 1 - (MAE / max(MAE, na.rm = TRUE)),
        MAPE_norm = 1 - (MAPE / max(MAPE, na.rm = TRUE)),
        Model = get_model_display_names()[Model]
      ) %>%
      select(Model, RSQ_norm, RMSE_norm, MAE_norm, MAPE_norm) %>%
      pivot_longer(-Model, names_to = "Metric", values_to = "Normalized_Score")
    
    df_norm %>%
      ggplot(aes(x = reorder(Model, Normalized_Score), y = Normalized_Score, fill = Metric)) +
      geom_bar(stat = "identity", position = "dodge") +
      theme_minimal() +
      coord_flip() +
      labs(title = "Normalized Performance Metrics (0-1 scale, higher is better)",
           x = "", y = "Normalized Score") +
      theme(axis.title.x = element_blank())
  })
  
  # ============================================================
  # TAB 3: DETAILED ANALYSIS
  # ============================================================
  
  output$filtered_results_table <- DT::renderDataTable({
    df <- eval_data()
    if (is.null(df) || nrow(df) == 0) {
      return(data.frame(Message = "No evaluation data available"))
    }
    
    filter_type <- input$model_type_filter
    
    if (filter_type == "lm") {
      df <- df %>% filter(grepl("lm_model", Model))
    } else if (filter_type == "xgb") {
      df <- df %>% filter(grepl("xgb_model", Model))
    }
    
    df <- df %>%
      mutate(
        Model = get_model_display_names()[Model],
        RSQ = round(RSQ, 4),
        RMSE = round(RMSE, 2),
        MAE = round(MAE, 2),
        MAPE = round(MAPE, 4)
      ) %>%
      arrange(desc(RSQ))
    
    DT::datatable(df, 
                  options = list(pageLength = 10, autoWidth = TRUE),
                  rownames = FALSE)
  })
  
  output$heatmap_plot <- renderPlot({
    df <- eval_data()
    if (is.null(df) || nrow(df) == 0) return(NULL)
    
    # Simple approach: create matrix manually
    model_names <- get_model_display_names()[df$Model]
    
    # Create matrix of values
    matrix_data <- matrix(
      c(df$RSQ, df$RMSE, df$MAE, df$MAPE),
      nrow = nrow(df),
      ncol = 4
    )
    
    # Scale each column independently
    matrix_scaled <- apply(matrix_data, 2, function(x) {
      (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
    })
    
    # Create dataframe for ggplot
    plot_data <- data.frame(
      Model = rep(model_names, 4),
      Metric = rep(c("RSQ", "RMSE", "MAE", "MAPE"), each = nrow(df)),
      Value = as.vector(matrix_scaled)
    )
    
    # Plot
    plot_data %>%
      ggplot(aes(x = factor(Metric, levels = c("RSQ", "RMSE", "MAE", "MAPE")), 
                 y = factor(Model, levels = rev(model_names)), 
                 fill = Value)) +
      geom_tile(color = "white", linewidth = 0.5) +
      scale_fill_gradient2(low = "red", mid = "white", high = "green", midpoint = 0) +
      theme_minimal() +
      theme(
        axis.text.x = element_text(angle = 0, hjust = 0.5, size = 11),
        axis.text.y = element_text(size = 9),
        plot.title = element_text(hjust = 0.5, size = 13)
      ) +
      labs(
        title = "Performance Heatmap (Scaled Values)",
        x = "Metric",
        y = "Model",
        fill = "Scaled Value"
      )
  })
  
  output$perf_stats <- renderPrint({
    df <- eval_data()
    if (is.null(df) || nrow(df) == 0) {
      cat("No evaluation data available\n")
    } else {
      cat("Performance Statistics Summary\n")
      cat("================================\n\n")
      
      cat("R-squared (RSQ):\n")
      cat("  Mean:", round(mean(df$RSQ, na.rm = TRUE), 4), "\n")
      cat("  Min:", round(min(df$RSQ, na.rm = TRUE), 4), "\n")
      cat("  Max:", round(max(df$RSQ, na.rm = TRUE), 4), "\n")
      cat("  SD:", round(sd(df$RSQ, na.rm = TRUE), 4), "\n\n")
      
      cat("RMSE:\n")
      cat("  Mean:", round(mean(df$RMSE, na.rm = TRUE), 2), "\n")
      cat("  Min:", round(min(df$RMSE, na.rm = TRUE), 2), "\n")
      cat("  Max:", round(max(df$RMSE, na.rm = TRUE), 2), "\n")
      cat("  SD:", round(sd(df$RMSE, na.rm = TRUE), 2), "\n\n")
      
      cat("MAE:\n")
      cat("  Mean:", round(mean(df$MAE, na.rm = TRUE), 2), "\n")
      cat("  Min:", round(min(df$MAE, na.rm = TRUE), 2), "\n")
      cat("  Max:", round(max(df$MAE, na.rm = TRUE), 2), "\n")
      cat("  SD:", round(sd(df$MAE, na.rm = TRUE), 2), "\n\n")
      
      cat("Model Type Comparison:\n")
      lm_avg <- df %>% filter(grepl("lm_model", Model)) %>% pull(RSQ) %>% mean(na.rm = TRUE)
      xgb_avg <- df %>% filter(grepl("xgb_model", Model)) %>% pull(RSQ) %>% mean(na.rm = TRUE)
      cat("  Linear Regression Avg R²:", round(lm_avg, 4), "\n")
      cat("  XGBoost Avg R²:", round(xgb_avg, 4), "\n")
    }
  })
  
  # ============================================================
  # TAB 4: MODEL SELECTION
  # ============================================================
  
  output$selected_best_model <- renderText({
    df <- eval_data()
    if (is.null(df) || nrow(df) == 0) {
      return("No evaluation data available")
    }
    
    metric <- input$metric_select
    
    if (metric == "RSQ") {
      best_idx <- which.max(df$RSQ)
    } else if (metric == "RMSE") {
      best_idx <- which.min(df$RMSE)
    } else if (metric == "MAE") {
      best_idx <- which.min(df$MAE)
    } else if (metric == "MAPE") {
      best_idx <- which.min(df$MAPE)
    }
    
    best <- df[best_idx, ]
    paste("🏆", get_model_display_names()[best$Model])
  })
  
  output$selected_model_stats <- renderPrint({
    df <- eval_data()
    if (is.null(df) || nrow(df) == 0) {
      cat("No evaluation data available\n")
      return()
    }
    
    metric <- input$metric_select
    
    if (metric == "RSQ") {
      best_idx <- which.max(df$RSQ)
      cat("Optimized for: R-squared (Higher is Better)\n\n")
    } else if (metric == "RMSE") {
      best_idx <- which.min(df$RMSE)
      cat("Optimized for: Root Mean Squared Error (Lower is Better)\n\n")
    } else if (metric == "MAE") {
      best_idx <- which.min(df$MAE)
      cat("Optimized for: Mean Absolute Error (Lower is Better)\n\n")
    } else if (metric == "MAPE") {
      best_idx <- which.min(df$MAPE)
      cat("Optimized for: Mean Absolute Percentage Error (Lower is Better)\n\n")
    }
    
    best <- df[best_idx, ]
    cat("Model:", get_model_display_names()[best$Model], "\n\n")
    cat("Performance Metrics:\n")
    cat("  R²:", round(best$RSQ, 6), "\n")
    cat("  RMSE:", round(best$RMSE, 2), "bikes\n")
    cat("  MAE:", round(best$MAE, 2), "bikes\n")
    cat("  MAPE:", round(best$MAPE, 6), "\n")
  })
  
  # ============================================================
  # TAB 5: PREDICTIONS
  # ============================================================
  
  prediction_result <- eventReactive(input$predict_btn, {
    models <- trained_models()
    
    if (is.null(models)) {
      return(list(error = "Models not loaded. Please check model files."))
    }
    
    model_key <- input$pred_model_select
    model <- models[[model_key]]
    
    # Create input data
    input_data <- tibble(
      TEMPERATURE = input$temp_input,
      HUMIDITY = input$humidity_input,
      WIND_SPEED = input$wind_input,
      VISIBILITY = input$visibility_input,
      SOLAR_RADIATION = input$solar_input,
      RAINFALL = input$rainfall_input,
      DEW_POINT_TEMPERATURE = input$dew_input,
      TEMPERATURE_HUMIDITY = input$temp_input * input$humidity_input,
      TEMPERATURE_SOLAR = input$temp_input * input$solar_input,
      TEMPERATURE_RAINFALL = input$temp_input * input$rainfall_input,
      DEW_POINT_SPREAD = input$temp_input - input$dew_input
    )
    
    tryCatch({
      prediction <- predict(model, new_data = input_data) %>% pull(.pred)
      return(list(
        success = TRUE,
        prediction = prediction,
        model_name = model_key
      ))
    }, error = function(e) {
      return(list(
        error = paste("Prediction error:", e$message)
      ))
    })
  })
  
  output$prediction_result <- renderText({
    result <- prediction_result()
    
    if (!is.null(result$error)) {
      return(paste("❌ Error:", result$error))
    }
    
    pred <- result$prediction
    
    if (pred < 0) pred <- 0
    
    paste("✓ Predicted Bike Rentals:", 
          format(round(pred), big.mark = ","),
          "bikes")
  })
  
  output$prediction_details <- renderPrint({
    result <- prediction_result()
    
    if (!is.null(result$error)) {
      cat("Error occurred during prediction\n")
      return()
    }
    
    cat("Prediction Details\n")
    cat("==================\n\n")
    cat("Input Parameters:\n")
    cat("  Temperature:", input$temp_input, "°C\n")
    cat("  Humidity:", input$humidity_input, "%\n")
    cat("  Wind Speed:", input$wind_input, "m/s\n")
    cat("  Visibility:", input$visibility_input, "m\n")
    cat("  Solar Radiation:", input$solar_input, "MJ/m²\n")
    cat("  Rainfall:", input$rainfall_input, "mm\n")
    cat("  Dew Point Temperature:", input$dew_input, "°C\n\n")
    
    cat("Prediction: ", format(round(result$prediction), big.mark = ","), "bikes\n", sep = "")
  })
  
  output$prediction_model_info <- renderPrint({
    result <- prediction_result()
    
    if (!is.null(result$error)) {
      return()
    }
    
    model_key <- result$model_name
    df <- eval_data()
    
    if (!is.null(df) && nrow(df) > 0) {
      model_row <- df %>% filter(grepl(model_key, Model))
      
      if (nrow(model_row) > 0) {
        cat("Selected Model Performance\n")
        cat("==========================\n\n")
        cat("Model:", get_model_display_names()[model_row$Model[1]], "\n\n")
        cat("Test Set Performance:\n")
        cat("  R²:", round(model_row$RSQ[1], 4), "\n")
        cat("  RMSE:", round(model_row$RMSE[1], 2), "\n")
        cat("  MAE:", round(model_row$MAE[1], 2), "\n")
        cat("  MAPE:", round(model_row$MAPE[1], 4), "\n")
      }
    }
  })
  
  # ============================================================
  # TAB 6: DATA EXPLORER
  # ============================================================
  
  output$data_summary <- renderPrint({
    data <- test_data()
    
    if (is.null(data)) {
      cat("No test data available\n")
    } else {
      cat("Dataset Summary\n")
      cat("===============\n\n")
      cat("Dimensions:", nrow(data), "rows ×", ncol(data), "columns\n\n")
      cat("Data Types:\n")
      print(glimpse(data))
    }
  })
  
  output$data_structure <- renderPrint({
    data <- test_data()
    
    if (is.null(data)) {
      cat("No test data available\n")
    } else {
      cat("Column Information\n")
      cat("==================\n\n")
      str(data)
    }
  })
  
  output$raw_data_table <- DT::renderDataTable({
    data <- test_data()
    
    if (is.null(data)) {
      return(data.frame(Message = "No test data available"))
    }
    
    # Use base R indexing instead of slice()
    n_rows <- min(50, nrow(data))
    df_display <- data[1:n_rows, ] %>%
      mutate(across(where(is.numeric), ~round(., 2)))
    
    DT::datatable(df_display,
                  options = list(scrollX = TRUE, pageLength = 10),
                  rownames = FALSE)
  },
  options = list(scrollX = TRUE, pageLength = 10)
  )
  
  output$var_stats_table <- DT::renderDataTable({
    data <- test_data()
    
    if (is.null(data)) {
      return(data.frame(Message = "No test data available"))
    }
    
    # Get numeric columns
    numeric_cols <- data %>% select(where(is.numeric))
    
    if (ncol(numeric_cols) == 0) {
      return(data.frame(Message = "No numeric columns available"))
    }
    
    # Create statistics manually
    stats_list <- list()
    
    for (col in names(numeric_cols)) {
      stats_list[[paste(col, "Mean", sep = "_")]] <- mean(numeric_cols[[col]], na.rm = TRUE)
      stats_list[[paste(col, "Median", sep = "_")]] <- median(numeric_cols[[col]], na.rm = TRUE)
      stats_list[[paste(col, "Min", sep = "_")]] <- min(numeric_cols[[col]], na.rm = TRUE)
      stats_list[[paste(col, "Max", sep = "_")]] <- max(numeric_cols[[col]], na.rm = TRUE)
      stats_list[[paste(col, "SD", sep = "_")]] <- sd(numeric_cols[[col]], na.rm = TRUE)
    }
    
    # Convert to dataframe
    stats_df <- as.data.frame(stats_list) %>%
      pivot_longer(everything(), names_to = "Statistic", values_to = "Value") %>%
      mutate(Value = round(Value, 2))
    
    DT::datatable(stats_df,
                  options = list(pageLength = 20, autoWidth = TRUE),
                  rownames = FALSE)
  })
}