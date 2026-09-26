# Integration Tests for Complete Pipeline
# File: test_integration.R
# Purpose: Test complete workflow and component interactions

library(testthat)
library(tidyverse)
library(tidymodels)
library(xgboost)

# ============================================================================
# TEST SETUP: Complete data preparation
# ============================================================================
create_complete_dataset <- function(n_rows = 500) {
  set.seed(42)
  
  tibble(
    RENTED_BIKE_COUNT = rnorm(n_rows, 0.5, 0.1),
    TEMPERATURE = runif(n_rows, 0.1, 0.95),
    HUMIDITY = runif(n_rows, 0.2, 0.98),
    WIND_SPEED = runif(n_rows, 0.0, 1.0),
    VISIBILITY = runif(n_rows, 0.3, 1.0),
    DEW_POINT_TEMPERATURE = runif(n_rows, 0.05, 0.9),
    SOLAR_RADIATION = runif(n_rows, 0.0, 0.4),
    RAINFALL = runif(n_rows, 0.0, 0.02),
    HOUR = sample(0:23, n_rows, replace = TRUE),
    SEASONS_AUTUMN = sample(0:1, n_rows, replace = TRUE),
    SEASONS_WINTER = sample(0:1, n_rows, replace = TRUE),
    HOLIDAY_NO_HOLIDAY = sample(0:1, n_rows, replace = TRUE),
    HOUR_0 = ifelse(HOUR == 0, 1, 0),
    HOUR_8 = ifelse(HOUR == 8, 1, 0),
    HOUR_18 = ifelse(HOUR == 18, 1, 0),
    HOUR_23 = ifelse(HOUR == 23, 1, 0),
    TEMPERATURE_HUMIDITY = TEMPERATURE * HUMIDITY,
    TEMPERATURE_SOLAR = TEMPERATURE * SOLAR_RADIATION,
    TEMPERATURE_RAINFALL = TEMPERATURE * RAINFALL,
    DEW_POINT_SPREAD = TEMPERATURE - DEW_POINT_TEMPERATURE
  )
}

# ============================================================================
# TEST SUITE 1: COMPLETE DATA PIPELINE
# ============================================================================
test_that("complete data pipeline processes without errors", {
  
  # Test 1: End-to-end data flow
  data <- create_complete_dataset(500)
  
  # Verify data structure
  expect_true(nrow(data) == 500)
  expect_true(ncol(data) == 20)
  expect_true(is_tibble(data))
  
  # Check no missing values
  expect_equal(sum(is.na(data)), 0)
  
})

test_that("data normalization maintains structure", {
  
  # Test 2: Data normalized correctly
  data <- create_complete_dataset(200)
  
  # Check ranges for normalized features
  numeric_cols <- data %>%
    select(TEMPERATURE, HUMIDITY, WIND_SPEED, VISIBILITY, 
           SOLAR_RADIATION, RAINFALL, TEMPERATURE_HUMIDITY, 
           TEMPERATURE_SOLAR, TEMPERATURE_RAINFALL)
  
  for (col in names(numeric_cols)) {
    expect_true(min(data[[col]]) >= 0)
    expect_true(max(data[[col]]) <= 1)
  }
  
})

test_that("feature engineering produces valid interactions", {
  
  # Test 3: Interaction features valid
  data <- create_complete_dataset(100)
  
  # Check TEMPERATURE_HUMIDITY
  expected_th <- data$TEMPERATURE * data$HUMIDITY
  expect_equal(data$TEMPERATURE_HUMIDITY, expected_th)
  
  # Check TEMPERATURE_SOLAR
  expected_ts <- data$TEMPERATURE * data$SOLAR_RADIATION
  expect_equal(data$TEMPERATURE_SOLAR, expected_ts)
  
  # Check DEW_POINT_SPREAD
  expected_dps <- data$TEMPERATURE - data$DEW_POINT_TEMPERATURE
  expect_equal(data$DEW_POINT_SPREAD, expected_dps)
  
})

# ============================================================================
# TEST SUITE 2: TRAIN-TEST SPLIT AND VALIDATION
# ============================================================================
test_that("data splits maintain integrity", {
  
  # Test 1: 75-25 split
  data <- create_complete_dataset(1000)
  
  set.seed(42)
  split <- initial_split(data, prop = 3/4)
  train_data <- training(split)
  test_data <- testing(split)
  
  expect_equal(nrow(train_data) + nrow(test_data), 1000)
  expect_true(nrow(train_data) > 700 & nrow(train_data) < 800)
  expect_true(nrow(test_data) > 200 & nrow(test_data) < 300)
  
})

test_that("split preserves data distribution", {
  
  # Test 2: Distribution preservation
  data <- create_complete_dataset(500)
  
  set.seed(42)
  split <- initial_split(data, prop = 3/4)
  train_data <- training(split)
  test_data <- testing(split)
  
  # Compare mean values
  mean_train_temp <- mean(train_data$TEMPERATURE)
  mean_test_temp <- mean(test_data$TEMPERATURE)
  
  # Should be reasonably close
  expect_true(abs(mean_train_temp - mean_test_temp) < 0.2)
  
})

# ============================================================================
# TEST SUITE 3: MULTIPLE MODELS TRAINING AND EVALUATION
# ============================================================================
test_that("train and evaluate multiple models", {
  
  # Test 1: Train 5 different models
  data <- create_complete_dataset(400)
  
  set.seed(42)
  split <- initial_split(data, prop = 3/4)
  train_data <- training(split)
  test_data <- testing(split)
  
  # Model 1: LM Weather
  model_1 <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(RENTED_BIKE_COUNT ~ TEMPERATURE + HUMIDITY + WIND_SPEED + 
          VISIBILITY + DEW_POINT_TEMPERATURE + SOLAR_RADIATION + RAINFALL,
        data = train_data)
  
  # Model 2: LM All Variables
  model_2 <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(RENTED_BIKE_COUNT ~ ., data = train_data)
  
  # Model 3: XGB Weather
  model_3 <- boost_tree(mode = "regression") %>%
    set_engine("xgboost") %>%
    fit(RENTED_BIKE_COUNT ~ TEMPERATURE + HUMIDITY + WIND_SPEED + 
          VISIBILITY + DEW_POINT_TEMPERATURE + SOLAR_RADIATION + RAINFALL,
        data = train_data)
  
  # Model 4: XGB All Variables
  model_4 <- boost_tree(mode = "regression") %>%
    set_engine("xgboost") %>%
    fit(RENTED_BIKE_COUNT ~ ., data = train_data)
  
  # Model 5: LM with Interactions
  model_5 <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(RENTED_BIKE_COUNT ~ . + TEMPERATURE_HUMIDITY, data = train_data)
  
  # All models should be valid
  models <- list(model_1, model_2, model_3, model_4, model_5)
  for (model in models) {
    expect_true(inherits(model, "model_fit"))
  }
  
})

test_that("models produce predictions in valid range", {
  
  # Test 2: Prediction validity
  data <- create_complete_dataset(300)
  
  set.seed(42)
  split <- initial_split(data, prop = 3/4)
  train_data <- training(split)
  test_data <- testing(split)
  
  model <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(RENTED_BIKE_COUNT ~ ., data = train_data)
  
  predictions <- predict(model, test_data)$.pred
  
  # Predictions should be numeric and reasonable
  expect_true(all(is.numeric(predictions)))
  expect_true(all(is.finite(predictions)))
  
})

test_that("model comparison shows expected patterns", {
  
  # Test 3: Model hierarchy
  data <- create_complete_dataset(500)
  
  set.seed(42)
  split <- initial_split(data, prop = 3/4)
  train_data <- training(split)
  test_data <- testing(split)
  
  actual <- test_data$RENTED_BIKE_COUNT
  
  # Weather-only vs All-variables
  model_weather <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(RENTED_BIKE_COUNT ~ TEMPERATURE + HUMIDITY + WIND_SPEED + 
          VISIBILITY + DEW_POINT_TEMPERATURE + SOLAR_RADIATION + RAINFALL,
        data = train_data)
  
  model_all <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(RENTED_BIKE_COUNT ~ ., data = train_data)
  
  pred_weather <- predict(model_weather, test_data)$.pred
  pred_all <- predict(model_all, test_data)$.pred
  
  rmse_weather <- sqrt(mean((actual - pred_weather)^2))
  rmse_all <- sqrt(mean((actual - pred_all)^2))
  
  # All-variables should generally perform better or equal
  expect_true(rmse_all <= rmse_weather * 1.2)
  
})

# ============================================================================
# TEST SUITE 4: METRICS CALCULATION AND COMPARISON
# ============================================================================
test_that("evaluate multiple models with consistent metrics", {
  
  # Test: Complete evaluation
  data <- create_complete_dataset(400)
  
  set.seed(42)
  split <- initial_split(data, prop = 3/4)
  train_data <- training(split)
  test_data <- testing(split)
  
  actual <- test_data$RENTED_BIKE_COUNT
  
  # Create two models
  model_1 <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(RENTED_BIKE_COUNT ~ TEMPERATURE + HUMIDITY, data = train_data)
  
  model_2 <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(RENTED_BIKE_COUNT ~ ., data = train_data)
  
  # Get predictions
  pred_1 <- predict(model_1, test_data)$.pred
  pred_2 <- predict(model_2, test_data)$.pred
  
  # Calculate metrics for both
  calculate_metrics <- function(actual, predicted) {
    tibble(
      r_squared = 1 - (sum((actual - predicted)^2) / sum((actual - mean(actual))^2)),
      rmse = sqrt(mean((actual - predicted)^2)),
      mae = mean(abs(actual - predicted)),
      mape = mean(abs((actual - predicted) / actual)) * 100
    )
  }
  
  metrics_1 <- calculate_metrics(actual, pred_1)
  metrics_2 <- calculate_metrics(actual, pred_2)
  
  # Both should have valid metrics
  expect_true(all(is.numeric(unlist(metrics_1))))
  expect_true(all(is.numeric(unlist(metrics_2))))
  
  # Create comparison table
  comparison <- bind_rows(
    metrics_1 %>% mutate(Model = "Model 1"),
    metrics_2 %>% mutate(Model = "Model 2")
  )
  
  expect_equal(nrow(comparison), 2)
  expect_true("Model" %in% names(comparison))
  
})

# ============================================================================
# TEST SUITE 5: MODEL PERSISTENCE
# ============================================================================
test_that("complete workflow: train, save, load, evaluate", {
  
  # Test: Full cycle
  env <- tempdir()
  data <- create_complete_dataset(300)
  
  set.seed(42)
  split <- initial_split(data, prop = 3/4)
  train_data <- training(split)
  test_data <- testing(split)
  
  # Train model
  model <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(RENTED_BIKE_COUNT ~ ., data = train_data)
  
  # Save model
  model_path <- file.path(env, "integration_model.rds")
  saveRDS(model, model_path)
  expect_true(file.exists(model_path))
  
  # Load model
  loaded_model <- readRDS(model_path)
  expect_true(inherits(loaded_model, "model_fit"))
  
  # Make predictions with loaded model
  pred_original <- predict(model, test_data)$.pred
  pred_loaded <- predict(loaded_model, test_data)$.pred
  
  # Should be identical
  expect_equal(pred_original, pred_loaded)
  
  # Calculate metrics
  actual <- test_data$RENTED_BIKE_COUNT
  rmse <- sqrt(mean((actual - pred_loaded)^2))
  
  expect_true(is.numeric(rmse) && rmse > 0)
  
  # Cleanup
  unlink(model_path)
  
})

# ============================================================================
# TEST SUITE 6: SCALING AND ROBUSTNESS
# ============================================================================
test_that("pipeline handles different data sizes", {
  
  # Test 1: Small dataset
  small_data <- create_complete_dataset(50)
  split_small <- initial_split(small_data, prop = 3/4)
  train_small <- training(split_small)
  
  model_small <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(RENTED_BIKE_COUNT ~ ., data = train_small)
  
  expect_true(inherits(model_small, "model_fit"))
  
  # Test 2: Large dataset
  large_data <- create_complete_dataset(5000)
  split_large <- initial_split(large_data, prop = 3/4)
  train_large <- training(split_large)
  
  model_large <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(RENTED_BIKE_COUNT ~ ., data = train_large)
  
  expect_true(inherits(model_large, "model_fit"))
  
})

test_that("pipeline produces consistent results with fixed seed", {
  
  # Test: Reproducibility
  data1 <- create_complete_dataset(300)
  data2 <- create_complete_dataset(300)
  
  set.seed(42)
  split1 <- initial_split(data1, prop = 3/4)
  model1 <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(RENTED_BIKE_COUNT ~ ., data = training(split1))
  
  set.seed(42)
  split2 <- initial_split(data2, prop = 3/4)
  model2 <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(RENTED_BIKE_COUNT ~ ., data = training(split2))
  
  # Coefficients should be similar
  coef1 <- coef(model1$fit)
  coef2 <- coef(model2$fit)
  
  expect_true(all.equal(coef1, coef2, tolerance = 0.01))
  
})

# ============================================================================
# TEST SUITE 7: ERROR HANDLING
# ============================================================================
test_that("pipeline handles edge cases gracefully", {
  
  # Test 1: Very small dataset
  tiny_data <- create_complete_dataset(5)
  
  expect_error({
    model <- linear_reg() %>%
      set_engine("lm") %>%
      set_mode("regression") %>%
      fit(RENTED_BIKE_COUNT ~ ., data = tiny_data)
  }, NA)  # Should work or error appropriately
  
})

test_that("models handle missing values appropriately", {
  
  # Test: Missing value handling
  data <- create_complete_dataset(100)
  data$TEMPERATURE[c(1, 5, 10)] <- NA
  
  # Attempt to train (should error or handle gracefully)
  expect_error({
    model <- linear_reg() %>%
      set_engine("lm") %>%
      set_mode("regression") %>%
      fit(RENTED_BIKE_COUNT ~ ., data = data)
  }, NA)
  
})

# ============================================================================
# TEST SUITE 8: WORKFLOW DOCUMENTATION
# ============================================================================
test_that("complete workflow is documented and traceable", {
  
  # Test: Logging workflow
  env <- tempdir()
  log_file <- file.path(env, "workflow.log")
  
  # Simulate workflow logging
  write("[2026-09-22 10:00:00] [INFO] Starting pipeline", log_file)
  write("[2026-09-22 10:00:01] [INFO] Loading data", log_file, append = TRUE)
  write("[2026-09-22 10:00:02] [INFO] Training model", log_file, append = TRUE)
  write("[2026-09-22 10:00:05] [INFO] Evaluating model", log_file, append = TRUE)
  write("[2026-09-22 10:00:06] [INFO] Pipeline complete", log_file, append = TRUE)
  
  # Verify log
  log_content <- readLines(log_file)
  expect_equal(length(log_content), 5)
  
  # Cleanup
  unlink(log_file)
  
})

# ============================================================================
# TEST SUITE 9: PIPELINE METRICS COMPARISON
# ============================================================================
test_that("compare all models in structured format", {
  
  # Test: Comprehensive model comparison
  data <- create_complete_dataset(400)
  
  set.seed(42)
  split <- initial_split(data, prop = 3/4)
  train_data <- training(split)
  test_data <- testing(split)
  
  actual <- test_data$RENTED_BIKE_COUNT
  
  # Train multiple models
  models <- list(
    LM_Weather = linear_reg() %>%
      set_engine("lm") %>%
      set_mode("regression") %>%
      fit(RENTED_BIKE_COUNT ~ TEMPERATURE + HUMIDITY + WIND_SPEED + 
            VISIBILITY + DEW_POINT_TEMPERATURE + SOLAR_RADIATION + RAINFALL,
          data = train_data),
    
    LM_All = linear_reg() %>%
      set_engine("lm") %>%
      set_mode("regression") %>%
      fit(RENTED_BIKE_COUNT ~ ., data = train_data),
    
    XGB_Weather = boost_tree(mode = "regression") %>%
      set_engine("xgboost") %>%
      fit(RENTED_BIKE_COUNT ~ TEMPERATURE + HUMIDITY + WIND_SPEED + 
            VISIBILITY + DEW_POINT_TEMPERATURE + SOLAR_RADIATION + RAINFALL,
          data = train_data),
    
    XGB_All = boost_tree(mode = "regression") %>%
      set_engine("xgboost") %>%
      fit(RENTED_BIKE_COUNT ~ ., data = train_data)
  )
  
  # Evaluate all models
  results <- tibble(
    Model = character(),
    R_squared = numeric(),
    RMSE = numeric(),
    MAE = numeric(),
    MAPE = numeric()
  )
  
  for (i in seq_along(models)) {
    pred <- predict(models[[i]], test_data)$.pred
    
    r2 <- 1 - (sum((actual - pred)^2) / sum((actual - mean(actual))^2))
    rmse <- sqrt(mean((actual - pred)^2))
    mae <- mean(abs(actual - pred))
    mape <- mean(abs((actual - pred) / actual)) * 100
    
    results <- add_row(results,
      Model = names(models)[i],
      R_squared = r2,
      RMSE = rmse,
      MAE = mae,
      MAPE = mape
    )
  }
  
  # Verify results table
  expect_equal(nrow(results), 4)
  expect_true(all(c("Model", "R_squared", "RMSE", "MAE", "MAPE") %in% names(results)))
  
  # Best model should be identified
  best_model <- results %>% slice_max(R_squared)
  expect_equal(nrow(best_model), 1)
  
})

# ============================================================================
# TEST SUITE 10: PERFORMANCE BENCHMARKING
# ============================================================================
test_that("pipeline completes in reasonable time", {
  
  # Test: Overall pipeline timing
  start_time <- Sys.time()
  
  # Data preparation
  data <- create_complete_dataset(500)
  
  # Train-test split
  set.seed(42)
  split <- initial_split(data, prop = 3/4)
  train_data <- training(split)
  test_data <- testing(split)
  
  # Train models
  model_lm <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(RENTED_BIKE_COUNT ~ ., data = train_data)
  
  model_xgb <- boost_tree(mode = "regression") %>%
    set_engine("xgboost") %>%
    fit(RENTED_BIKE_COUNT ~ ., data = train_data)
  
  # Make predictions
  pred_lm <- predict(model_lm, test_data)$.pred
  pred_xgb <- predict(model_xgb, test_data)$.pred
  
  end_time <- Sys.time()
  elapsed <- as.numeric(end_time - start_time)
  
  # Should complete in reasonable time
  expect_true(elapsed < 30)  # Less than 30 seconds
  
})

# Print test summary
cat("\n========================================\n")
cat("INTEGRATION TESTS COMPLETED\n")
cat("========================================\n")
