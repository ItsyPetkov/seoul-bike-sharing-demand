library("tidymodels")
library("tidyverse")
library("stringr")
library("xgboost")
library("shiny")
library("shinydashboard")
library("DT")
library("ggplot2")
library("scales")
library("mlflow")

source("utils.R")
#source("ui.R") # in case you want to run dashbaord server locally
#source("server.R") # in case you want to run dashbaord server locally
source("features/build_features.R")
source("models/train_model.R")
source("models/evaluate_model.R")

mlflow_set_tracking_uri("http://mlflow:5000")
mlflow_set_experiment("seoul-bike-sharing")

log_model_to_mlflow <- function(model_name, model_path, metrics) {

    run <- mlflow_start_run()

    tryCatch({

        mlflow_log_param("model_name", model_name)
        mlflow_log_param("train_test_split", "75/25")
        mlflow_log_param("random_seed", "42")

        mlflow_log_artifact(model_path, artifact_path = "model")

        if (is.data.frame(metrics) && nrow(metrics) > 0) {

            numeric_columns <- names(metrics)[
                vapply(metrics, is.numeric, logical(1))
            ]

            for (metric_name in numeric_columns) {

                metric_value <- metrics[[metric_name]][1]

                if (!is.na(metric_value) && is.finite(metric_value)) {

                    mlflow_log_metric(metric_name, as.numeric(metric_value))
                }
            }
        }

        mlflow_log_param("model_artifact", basename(model_path))

        log_message(paste("MLflow run logged successfully:", model_name),
                          "logs", "pipeline_outputs.log")

    }, error = function(e) {

        log_message(paste("MLflow logging failed for", model_name, ":",
                    conditionMessage(e)), "logs", "pipeline_outputs.log")

    }, finally = {

        mlflow_end_run()
    })
}

train <- function() {

    #Initiate logging procedure
    log_message("Commencing model training pipeline construction:", "logs", "pipeline_outputs.log", append_bool=FALSE)

    log_message("Initializing seed to 42 for reproducibilty ...", "logs", "pipeline_outputs.log")

    # Setting seed
    set.seed(42)

    log_message("Reading in the dataset ...", "logs", "pipeline_outputs.log")

    #Read in the dataset
    bike_sharing_df <- read_csv("data_preprocessed/processed_seoul_bike_sharing_normalized.csv")
    spec(bike_sharing_df)

    log_message(paste(capture.output(str(spec(bike_sharing_df))), collapse = "\n"), "logs", "pipeline_outputs.log")

    log_message("Performing feature selection ...", "logs", "pipeline_outputs.log")

    # Selection features according to the 0.01 importance treshold
    bike_sharing_df <- bike_sharing_df %>% select(-DATE, -FUNCTIONING_DAY, -HOLIDAY_HOLIDAY, -SEASONS_SPRING, -HOUR_7, -HOUR_10,
                                              -SEASONS_SUMMER, -HOUR_19, -HOUR_4, -SNOWFALL, -HOUR_5, -HOUR_11, -HOUR_21, -SEASONS_WINTER,
                                              -HOUR_9, -HOUR_16, -HOUR_15, -HOUR_17, -HOUR_6, -HOUR_14, -HOUR_20, -HOUR_12, -HOUR_22,
                                              -HOUR_13, -HOUR_2, -HOUR_1, -HOUR_3)

    log_message(paste(capture.output(summary(bike_sharing_df)), collapse = "\n"), "logs", "pipeline_outputs.log")

    log_message("Performing feature engineering ...", "logs", "pipeline_outputs.log")

    # Creating features based on previous explorations and visualization conducted in notebooks
    bike_sharing_df <- engineer_bike_features(bike_sharing_df)
    
    log_message("Describing final dataset ...", "logs", "pipeline_outputs.log")

    log_message(paste(capture.output(summary(bike_sharing_df)), collapse = "\n"), "logs", "pipeline_outputs.log")

    log_message("Train/test splitting the dataset (75%/25%) ...", "logs", "pipeline_outputs.log")

    # Train/test split 75% train_data, 25% test_data
    data_split <- initial_split(bike_sharing_df, 3/4)
    train_data <- training(data_split)
    test_data <- testing(data_split)

    log_message(paste("Training data dims:", paste(dim(train_data), collapse = " x ")), "logs", "pipeline_outputs.log")
    log_message(paste("Testing data dims:", paste(dim(test_data), collapse = " x ")), "logs", "pipeline_outputs.log")
    log_message(paste("Original data dims:", paste(dim(bike_sharing_df), collapse = " x ")), "logs", "pipeline_outputs.log")

    log_message("Models instantiation ...", "logs", "pipeline_outputs.log")

    log_message("Fitting a linear regression model with weather features ...", "logs", "pipeline_outputs.log")

    # Weather variables fitting
    lm_model_weather <- fit_lm_model_weather(train_data)
    save_model(lm_model_weather, "checkpoints/lm_model_weather.rds")
    
    log_message(paste(capture.output(lm_model_weather$fit), collapse = "\n"), "logs", "pipeline_outputs.log")

    log_message("Fitting a linear regression model with weather features and polynomial terms ...", "logs", "pipeline_outputs.log")

    # Weather + polynomial variables fitting
    lm_model_weather_poly <- fit_lm_model_weather_poly(train_data)
    save_model(lm_model_weather_poly, "checkpoints/lm_model_weather_poly.rds")

    log_message(paste(capture.output(summary(lm_model_weather_poly)), collapse = "\n"), "logs", "pipeline_outputs.log")

    log_message("Fitting a linear regression model with weather features, polynomial and engineered terms ...", "logs", "pipeline_outputs.log")

    # Weather + polynomial + engineered (a.k.a interaction) variables fitting
    lm_model_weather_poly_interaction <- fit_lm_model_weather_interactions(train_data)
    save_model(lm_model_weather_poly_interaction, "checkpoints/lm_model_weather_poly_interaction.rds")

    log_message(paste(capture.output(summary(lm_model_weather_poly_interaction)), collapse = "\n"), "logs", "pipeline_outputs.log")

    log_message("Fitting a linear regression model with all variables ...", "logs", "pipeline_outputs.log")

    # All variables fitting
    lm_model_all <- fit_lm_model_all(train_data)
    save_model(lm_model_all, "checkpoints/lm_model_all.rds")

    log_message(paste(capture.output(lm_model_all$fit), collapse = "\n"), "logs", "pipeline_outputs.log")

    log_message("Fitting a linear regression model with all variables and polynomial terms ...", "logs", "pipeline_outputs.log")

    lm_model_all_poly <- fit_lm_model_all_poly(train_data)
    save_model(lm_model_all_poly, "checkpoints/lm_model_all_poly.rds")

    log_message(paste(capture.output(summary(lm_model_all_poly)), collapse = "\n"), "logs", "pipeline_outputs.log")

    log_message("Fitting an XGBoost model with weather features ...", "logs", "pipeline_outputs.log")

    # XGBoost fit with weather variables
    xgb_model_weather <- fit_xgb_model_weather(train_data)
    save_model(xgb_model_weather, "checkpoints/xgb_model_weather.rds")

    log_message(paste(capture.output(xgb_model_weather), collapse = "\n"), "logs", "pipeline_outputs.log")

    log_message("Fitting an XGBoost model with weather features and polynomial terms ...", "logs", "pipeline_outputs.log")

    # XGBoost fit with weather variables and polynomial terms
    xgb_model_weather_poly <- fit_xgb_model_weather_poly(train_data)
    save_model(xgb_model_weather_poly, "checkpoints/xgb_model_weather_poly.rds")

    log_message(paste(capture.output(xgb_model_weather_poly), collapse = "\n"), "logs", "pipeline_outputs.log")

    log_message("Fitting an XGBoost model with weather features, polynomial and engineered terms ...", "logs", "pipeline_outputs.log")

    # XGBoost fit with weather variables + polynomial + engineered (a.k.a interaction) terms
    xgb_model_weather_poly_interaction <- fit_xgb_model_weather_poly_interactions(train_data)
    save_model(xgb_model_weather_poly_interaction, "checkpoints/xgb_model_weather_poly_interaction.rds")

    log_message(paste(capture.output(xgb_model_weather_poly_interaction), collapse = "\n"), "logs", "pipeline_outputs.log")

    log_message("Fitting an XGBoost model with all variables ...", "logs", "pipeline_outputs.log")

    # XGBoost fit with all variables
    xgb_model_all <- fit_xgb_model_all(train_data)
    save_model(xgb_model_all, "checkpoints/xgb_model_all.rds")

    log_message(paste(capture.output(xgb_model_all), collapse = "\n"), "logs", "pipeline_outputs.log")

    log_message("Fitting an XGBoost model with all variables and polynomial terms ...", "logs", "pipeline_outputs.log")

    # XGBoost fit with all variables + polynomial terms
    xgb_model_all_poly <- fit_xgb_model_all_poly(train_data)
    save_model(xgb_model_all_poly, "checkpoints/xgb_model_all_poly.rds")

    log_message(paste(capture.output(xgb_model_all_poly), collapse = "\n"), "logs", "pipeline_outputs.log")

    return(test_data)
}

evaluate <- function(test_data){
    lm_model_weather <- load_model("checkpoints/lm_model_weather.rds")
    lm_model_weather_poly <- load_model("checkpoints/lm_model_weather_poly.rds")
    lm_model_weather_poly_interaction <- load_model("checkpoints/lm_model_weather_poly_interaction.rds")
    lm_model_all <- load_model("checkpoints/lm_model_all.rds")
    lm_model_all_poly <- load_model("checkpoints/lm_model_all_poly.rds")
    xgb_model_weather <- load_model("checkpoints/xgb_model_weather.rds")
    xgb_model_weather_poly <- load_model("checkpoints/xgb_model_weather_poly.rds")
    xgb_model_weather_poly_interaction <- load_model("checkpoints/xgb_model_weather_poly_interaction.rds")
    xgb_model_all <- load_model("checkpoints/xgb_model_all.rds")
    xgb_model_all_poly <- load_model("checkpoints/xgb_model_all_poly.rds")

    log_message("Commencing model evaluation pipeline construction:", "logs", "model_evaluation.log", append_bool=FALSE)

    tibble_lm_model_weather <- evaluate_model(lm_model_weather, test_data, "lm_model_weather")
    log_message(paste(capture.output(tibble_lm_model_weather), collapse = "\n"), "logs", "model_evaluation.log")
    log_model_to_mlflow("lm_model_weather", "checkpoints/lm_model_weather.rds", tibble_lm_model_weather)

    tibble_lm_model_weather_poly <- evaluate_model(lm_model_weather_poly, test_data, "lm_model_weather_poly")
    log_message(paste(capture.output(tibble_lm_model_weather_poly), collapse = "\n"), "logs", "model_evaluation.log")
    log_model_to_mlflow("lm_model_weather_poly", "checkpoints/lm_model_weather_poly.rds", tibble_lm_model_weather_poly)

    tibble_lm_model_weather_poly_interaction <- evaluate_model(lm_model_weather_poly_interaction, test_data, "lm_model_weather_poly_interaction")
    log_message(paste(capture.output(tibble_lm_model_weather_poly_interaction), collapse = "\n"), "logs", "model_evaluation.log")
    log_model_to_mlflow("lm_model_weather_poly_interaction", "checkpoints/lm_model_weather_poly_interaction.rds", tibble_lm_model_weather_poly_interaction)

    tibble_lm_model_all <- evaluate_model(lm_model_all, test_data, "lm_model_all")
    log_message(paste(capture.output(tibble_lm_model_all), collapse = "\n"), "logs", "model_evaluation.log")
    log_model_to_mlflow("lm_model_all", "checkpoints/lm_model_all.rds", tibble_lm_model_all)

    tibble_lm_model_all_poly <- evaluate_model(lm_model_all_poly, test_data, "lm_model_all_poly")
    log_message(paste(capture.output(tibble_lm_model_all_poly), collapse = "\n"), "logs", "model_evaluation.log")
    log_model_to_mlflow("lm_model_all_poly", "checkpoints/lm_model_all_poly.rds", tibble_lm_model_all_poly)

    tibble_xgb_model_weather <- evaluate_model(xgb_model_weather, test_data, "xgb_model_weather")
    log_message(paste(capture.output(tibble_xgb_model_weather), collapse = "\n"), "logs", "model_evaluation.log")
    log_model_to_mlflow("xgb_model_weather", "checkpoints/xgb_model_weather.rds", tibble_xgb_model_weather)

    tibble_xgb_model_weather_poly <- evaluate_model(xgb_model_weather_poly, test_data, "xgb_model_weather_poly")
    log_message(paste(capture.output(tibble_xgb_model_weather_poly), collapse = "\n"), "logs", "model_evaluation.log")
    log_model_to_mlflow("xgb_model_weather_poly", "checkpoints/xgb_model_weather_poly.rds", tibble_xgb_model_weather_poly)

    tibble_xgb_model_weather_poly_interaction <- evaluate_model(xgb_model_weather_poly_interaction, test_data, "xgb_model_weather_poly_interaction")
    log_message(paste(capture.output(tibble_xgb_model_weather_poly_interaction), collapse = "\n"), "logs", "model_evaluation.log")
    log_model_to_mlflow("xgb_model_weather_poly_interaction", "checkpoints/xgb_model_weather_poly_interaction.rds", tibble_xgb_model_weather_poly_interaction)

    tibble_xgb_model_all <- evaluate_model(xgb_model_all, test_data, "xgb_model_all")
    log_message(paste(capture.output(tibble_xgb_model_all), collapse = "\n"), "logs", "model_evaluation.log")
    log_model_to_mlflow("xgb_model_all", "checkpoints/xgb_model_all.rds", tibble_xgb_model_all)

    tibble_xgb_model_all_poly <- evaluate_model(xgb_model_all_poly, test_data, "xgb_model_all_poly")
    log_message(paste(capture.output(tibble_xgb_model_all_poly), collapse = "\n"), "logs", "model_evaluation.log")
    log_model_to_mlflow("xgb_model_all_poly", "checkpoints/xgb_model_all_poly.rds", tibble_xgb_model_all_poly)

    all_results <- bind_rows(
        tibble_lm_model_weather,
        tibble_lm_model_weather_poly,
        tibble_lm_model_weather_poly_interaction,
        tibble_lm_model_all,
        tibble_lm_model_all_poly,
        tibble_xgb_model_weather,
        tibble_xgb_model_weather_poly,
        tibble_xgb_model_weather_poly_interaction,
        tibble_xgb_model_all,
        tibble_xgb_model_all_poly
    )

    write_csv(all_results, "results/model_evaluation_results.csv")
    
    return(all_results)
}

main <- function(){
    test_data <- train()
    results <- evaluate(test_data)
    #shinyApp(ui = ui, server = server) # in case you want to run dashbaord server locally
}

main()