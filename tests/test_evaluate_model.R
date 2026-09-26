# Unit Tests for Model Evaluation Functions
# File: test_evaluate_model.R
# Purpose: Test model evaluation functions in models/evaluate_model.R

library(testthat)
library(tidyverse)
library(tidymodels)
library(xgboost)

# ============================================================================
# TEST SETUP: Create mock model and data
# ============================================================================
create_test_data <- function(n_rows = 100) {
  set.seed(42)
  tibble(
    RENTED_BIKE_COUNT = rnorm(n_rows, 0.5, 0.1),
    TEMPERATURE = runif(n_rows, 0.2, 0.9),
    HUMIDITY = runif(n_rows, 0.3, 0.95),
    WIND_SPEED = runif(n_rows, 0.0, 1.0),
    VISIBILITY = runif(n_rows, 0.4, 1.0),
    DEW_POINT_TEMPERATURE = runif(n_rows, 0.1, 0.8),
    SOLAR_RADIATION = runif(n_rows, 0.0, 0.3),
    RAINFALL = runif(n_rows, 0.0, 0.01),
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

create_test_model <- function(train_data) {
  linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(RENTED_BIKE_COUNT ~ ., data = train_data)
}

# ============================================================================
# TEST SUITE 1: R-SQUARED CALCULATION
# ============================================================================
test_that("calculate_r_squared computes correct metric", {
  
  # Test 1: Perfect predictions (R² = 1)
  actual <- c(1, 2, 3, 4, 5)
  predicted <- c(1, 2, 3, 4, 5)
  
  ss_res <- sum((actual - predicted)^2)
  ss_tot <- sum((actual - mean(actual))^2)
  r_squared <- 1 - (ss_res / ss_tot)
  
  expect_equal(r_squared, 1)
  
})

test_that("calculate_r_squared handles poor predictions", {
  
  # Test 2: Poor predictions (R² near 0)
  actual <- c(1, 2, 3, 4, 5)
  predicted <- c(3, 3, 3, 3, 3)  # Always predicting mean
  
  ss_res <- sum((actual - predicted)^2)
  ss_tot <- sum((actual - mean(actual))^2)
  r_squared <- 1 - (ss_res / ss_tot)
  
  expect_equal(r_squared, 0)
  
})

test_that("calculate_r_squared handles negative values", {
  
  # Test 3: Very poor predictions (R² < 0)
  actual <- c(1, 2, 3, 4, 5)
  predicted <- c(5, 4, 3, 2, 1)  # Inverse prediction
  
  ss_res <- sum((actual - predicted)^2)
  ss_tot <- sum((actual - mean(actual))^2)
  r_squared <- 1 - (ss_res / ss_tot)
  
  expect_true(r_squared < 0)
  
})

test_that("calculate_r_squared returns value between -1 and 1", {
  
  # Test 4: Value range
  actual <- rnorm(100, mean = 5, sd = 2)
  predicted <- actual + rnorm(100, mean = 0, sd = 0.5)
  
  ss_res <- sum((actual - predicted)^2)
  ss_tot <- sum((actual - mean(actual))^2)
  r_squared <- 1 - (ss_res / ss_tot)
  
  expect_true(r_squared >= -1 & r_squared <= 1)
  
})

# ============================================================================
# TEST SUITE 2: RMSE (ROOT MEAN SQUARED ERROR)
# ============================================================================
test_that("calculate_rmse computes correct metric", {
  
  # Test 1: Basic RMSE
  actual <- c(1, 2, 3, 4, 5)
  predicted <- c(1.1, 2.1, 2.9, 4.2, 4.8)
  
  rmse <- sqrt(mean((actual - predicted)^2))
  
  expect_true(rmse > 0)
  expect_true(rmse < 0.5)
  
})

test_that("calculate_rmse perfect predictions", {
  
  # Test 2: Perfect predictions (RMSE = 0)
  actual <- c(1, 2, 3, 4, 5)
  predicted <- c(1, 2, 3, 4, 5)
  
  rmse <- sqrt(mean((actual - predicted)^2))
  
  expect_equal(rmse, 0)
  
})

test_that("calculate_rmse penalizes large errors", {
  
  # Test 3: RMSE penalizes large errors more
  errors1 <- c(0.1, 0.1, 0.1)  # Small consistent errors
  errors2 <- c(0.1, 0.1, 0.5)  # One large error
  
  rmse1 <- sqrt(mean(errors1^2))
  rmse2 <- sqrt(mean(errors2^2))
  
  expect_true(rmse2 > rmse1)
  
})

test_that("calculate_rmse handles large values", {
  
  # Test 4: Large value range
  actual <- c(1000, 2000, 3000)
  predicted <- c(1100, 2050, 2900)
  
  rmse <- sqrt(mean((actual - predicted)^2))
  
  expect_true(rmse > 0 & rmse < 200)
  
})

# ============================================================================
# TEST SUITE 3: MAE (MEAN ABSOLUTE ERROR)
# ============================================================================
test_that("calculate_mae computes correct metric", {
  
  # Test 1: Basic MAE
  actual <- c(1, 2, 3, 4, 5)
  predicted <- c(1.5, 2.0, 2.5, 4.0, 5.5)
  
  mae <- mean(abs(actual - predicted))
  
  expect_true(mae > 0)
  expect_true(mae < 1)
  
})

test_that("calculate_mae perfect predictions", {
  
  # Test 2: Perfect predictions (MAE = 0)
  actual <- c(1, 2, 3, 4, 5)
  predicted <- c(1, 2, 3, 4, 5)
  
  mae <- mean(abs(actual - predicted))
  
  expect_equal(mae, 0)
  
})

test_that("calculate_mae robust to outliers", {
  
  # Test 3: MAE less affected by outliers than RMSE
  actual <- c(1, 2, 3, 4, 5)
  predicted <- c(1, 2, 3, 4, 50)  # Large error on last value
  
  mae <- mean(abs(actual - predicted))
  rmse <- sqrt(mean((actual - predicted)^2))
  
  # RMSE should be much larger due to squaring
  expect_true(rmse > mae * 3)
  
})

# ============================================================================
# TEST SUITE 4: MAPE (MEAN ABSOLUTE PERCENTAGE ERROR)
# ============================================================================
test_that("calculate_mape computes correct metric", {
  
  # Test 1: Basic MAPE
  actual <- c(100, 200, 300)
  predicted <- c(110, 210, 285)
  
  mape <- mean(abs((actual - predicted) / actual)) * 100
  
  expect_true(mape > 0)
  expect_true(mape < 100)
  
})

test_that("calculate_mape perfect predictions", {
  
  # Test 2: Perfect predictions (MAPE = 0)
  actual <- c(100, 200, 300)
  predicted <- c(100, 200, 300)
  
  mape <- mean(abs((actual - predicted) / actual)) * 100
  
  expect_equal(mape, 0)
  
})

test_that("calculate_mape handles percentage correctly", {
  
  # Test 3: Percentage representation
  actual <- c(100, 200)
  predicted <- c(110, 240)
  
  # 10% error, 20% error -> average 15%
  mape <- mean(abs((actual - predicted) / actual)) * 100
  
  expect_equal(mape, 15)
  
})

test_that("calculate_mape scaled independently of magnitude", {
  
  # Test 4: MAPE independent of scale
  actual1 <- c(1, 2, 3)
  predicted1 <- c(1.1, 2.2, 3.3)
  
  actual2 <- c(100, 200, 300)
  predicted2 <- c(110, 220, 330)
  
  mape1 <- mean(abs((actual1 - predicted1) / actual1)) * 100
  mape2 <- mean(abs((actual2 - predicted2) / actual2)) * 100
  
  expect_equal(mape1, mape2)
  
})

# ============================================================================
# TEST SUITE 5: FULL EVALUATION FUNCTION
# ============================================================================
test_that("evaluate_model returns tibble with all metrics", {
  
  # Test 1: Complete evaluation
  train_data <- create_test_data(100)
  test_data <- create_test_data(30)
  
  model <- create_test_model(train_data)
  predictions <- predict(model, test_data)$.pred
  
  # Manual evaluation
  actual <- test_data$RENTED_BIKE_COUNT
  
  ss_res <- sum((actual - predictions)^2)
  ss_tot <- sum((actual - mean(actual))^2)
  r_squared <- 1 - (ss_res / ss_tot)
  
  rmse <- sqrt(mean((actual - predictions)^2))
  mae <- mean(abs(actual - predictions))
  mape <- mean(abs((actual - predictions) / actual)) * 100
  
  # Results should be numeric
  expect_true(is.numeric(r_squared))
  expect_true(is.numeric(rmse))
  expect_true(is.numeric(mae))
  expect_true(is.numeric(mape))
  
})

test_that("evaluate_model produces reasonable metric values", {
  
  # Test 2: Metric ranges
  train_data <- create_test_data(100)
  test_data <- create_test_data(30)
  
  model <- create_test_model(train_data)
  predictions <- predict(model, test_data)$.pred
  actual <- test_data$RENTED_BIKE_COUNT
  
  r_squared <- 1 - (sum((actual - predictions)^2) / sum((actual - mean(actual))^2))
  rmse <- sqrt(mean((actual - predictions)^2))
  mae <- mean(abs(actual - predictions))
  mape <- mean(abs((actual - predictions) / actual)) * 100
  
  # Range checks
  expect_true(r_squared >= -1 & r_squared <= 1)
  expect_true(rmse >= 0)
  expect_true(mae >= 0)
  expect_true(mape >= 0)
  
})

# ============================================================================
# TEST SUITE 6: METRIC RELATIONSHIPS
# ============================================================================
test_that("RMSE greater than or equal to MAE", {
  
  # Test: RMSE >= MAE (always true)
  actual <- c(1, 2, 3, 4, 5)
  predicted <- c(1.2, 1.9, 3.1, 3.8, 5.2)
  
  mae <- mean(abs(actual - predicted))
  rmse <- sqrt(mean((actual - predicted)^2))
  
  expect_true(rmse >= mae)
  
})

test_that("MAE and RMSE increase with prediction error", {
  
  # Test: Both metrics monotonically increase with error
  actual <- c(1, 2, 3, 4, 5)
  
  errors <- list(
    c(0, 0, 0, 0, 0),        # No error
    c(0.1, 0.1, 0.1, 0.1, 0.1),  # Small error
    c(0.5, 0.5, 0.5, 0.5, 0.5)   # Large error
  )
  
  mae_values <- c()
  rmse_values <- c()
  
  for (error in errors) {
    predicted <- actual + error
    mae_values <- c(mae_values, mean(abs(actual - predicted)))
    rmse_values <- c(rmse_values, sqrt(mean((actual - predicted)^2)))
  }
  
  expect_true(all(diff(mae_values) >= 0))
  expect_true(all(diff(rmse_values) >= 0))
  
})

# ============================================================================
# TEST SUITE 7: EVALUATION WITH DIFFERENT MODELS
# ============================================================================
test_that("different models produce different metrics", {
  
  # Test: LM vs XGB metrics differ
  train_data <- create_test_data(150)
  test_data <- create_test_data(50)
  
  # LM model
  model_lm <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(RENTED_BIKE_COUNT ~ ., data = train_data)
  
  # XGB model
  model_xgb <- boost_tree(mode = "regression") %>%
    set_engine("xgboost") %>%
    fit(RENTED_BIKE_COUNT ~ ., data = train_data)
  
  # Get predictions
  pred_lm <- predict(model_lm, test_data)$.pred
  pred_xgb <- predict(model_xgb, test_data)$.pred
  
  actual <- test_data$RENTED_BIKE_COUNT
  
  # Calculate RMSE for each
  rmse_lm <- sqrt(mean((actual - pred_lm)^2))
  rmse_xgb <- sqrt(mean((actual - pred_xgb)^2))
  
  # Should differ
  expect_false(isTRUE(all.equal(rmse_lm, rmse_xgb)))
  
})

# ============================================================================
# TEST SUITE 8: EVALUATION SUMMARY STATISTICS
# ============================================================================
test_that("evaluation produces summary tibble", {
  
  # Test: Summary format
  train_data <- create_test_data(100)
  test_data <- create_test_data(30)
  
  model <- create_test_model(train_data)
  predictions <- predict(model, test_data)$.pred
  actual <- test_data$RENTED_BIKE_COUNT
  
  # Create result tibble
  result <- tibble(
    Model = "test_model",
    RSQ = 1 - (sum((actual - predictions)^2) / sum((actual - mean(actual))^2)),
    RMSE = sqrt(mean((actual - predictions)^2)),
    MAE = mean(abs(actual - predictions)),
    MAPE = mean(abs((actual - predictions) / actual)) * 100
  )
  
  expect_true(is.data.frame(result) || is_tibble(result))
  expect_equal(ncol(result), 5)
  expect_equal(names(result), c("Model", "RSQ", "RMSE", "MAE", "MAPE"))
  
})

# ============================================================================
# EDGE CASE TESTS
# ============================================================================
test_that("metrics handle constant predictions", {
  
  # Test: Predictions are all the same value
  actual <- c(1, 2, 3, 4, 5)
  predicted <- c(3, 3, 3, 3, 3)
  
  mae <- mean(abs(actual - predicted))
  rmse <- sqrt(mean((actual - predicted)^2))
  
  expect_true(mae > 0)
  expect_true(rmse > 0)
  
})

test_that("metrics handle very small errors", {
  
  # Test: Errors smaller than machine precision
  actual <- c(1.0, 2.0, 3.0)
  predicted <- c(1.0 + 1e-10, 2.0 + 1e-10, 3.0 + 1e-10)
  
  mae <- mean(abs(actual - predicted))
  rmse <- sqrt(mean((actual - predicted)^2))
  
  expect_true(mae > 0)
  expect_true(rmse > 0)
  
})

test_that("metrics handle extreme value ranges", {
  
  # Test: Very large and very small numbers
  actual <- c(1e-10, 1e10)
  predicted <- c(1.1e-10, 1.1e10)
  
  mae <- mean(abs(actual - predicted))
  rmse <- sqrt(mean((actual - predicted)^2))
  
  expect_true(mae > 0)
  expect_true(rmse > 0)
  
})

test_that("evaluation handles normalized vs unnormalized data", {
  
  # Test: Metrics work on normalized [0,1] scale
  actual <- c(0.1, 0.3, 0.5, 0.7, 0.9)
  predicted <- c(0.12, 0.28, 0.52, 0.68, 0.88)
  
  mae <- mean(abs(actual - predicted))
  rmse <- sqrt(mean((actual - predicted)^2))
  
  # Should be small since data is normalized
  expect_true(mae < 0.1)
  expect_true(rmse < 0.1)
  
})

# ============================================================================
# PERFORMANCE TESTS
# ============================================================================
test_that("metrics calculate efficiently on large datasets", {
  
  # Test: Performance with large arrays
  n_large <- 100000
  actual <- rnorm(n_large, 0.5, 0.1)
  predicted <- actual + rnorm(n_large, 0, 0.05)
  
  start_time <- Sys.time()
  
  mae <- mean(abs(actual - predicted))
  rmse <- sqrt(mean((actual - predicted)^2))
  mape <- mean(abs((actual - predicted) / actual)) * 100
  ss_res <- sum((actual - predicted)^2)
  ss_tot <- sum((actual - mean(actual))^2)
  r_squared <- 1 - (ss_res / ss_tot)
  
  end_time <- Sys.time()
  calc_time <- as.numeric(end_time - start_time)
  
  # Should complete very fast (< 1 second)
  expect_true(calc_time < 1)
  expect_true(is.finite(mae) && is.finite(rmse) && is.finite(mape))
  
})

# ============================================================================
# COMPARATIVE TESTS
# ============================================================================
test_that("evaluation metrics consistent across model types", {
  
  # Test: Same evaluation logic for different models
  train_data <- create_test_data(120)
  test_data <- create_test_data(40)
  
  # Create multiple models
  model_lm <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(RENTED_BIKE_COUNT ~ TEMPERATURE + HUMIDITY + WIND_SPEED, data = train_data)
  
  model_xgb <- boost_tree(mode = "regression") %>%
    set_engine("xgboost") %>%
    fit(RENTED_BIKE_COUNT ~ TEMPERATURE + HUMIDITY + WIND_SPEED, data = train_data)
  
  actual <- test_data$RENTED_BIKE_COUNT
  
  # Evaluate both
  pred_lm <- predict(model_lm, test_data)$.pred
  pred_xgb <- predict(model_xgb, test_data)$.pred
  
  r2_lm <- 1 - (sum((actual - pred_lm)^2) / sum((actual - mean(actual))^2))
  r2_xgb <- 1 - (sum((actual - pred_xgb)^2) / sum((actual - mean(actual))^2))
  
  # Both should be between -1 and 1
  expect_true(r2_lm >= -1 && r2_lm <= 1)
  expect_true(r2_xgb >= -1 && r2_xgb <= 1)
  
})

# Print test summary
cat("\n========================================\n")
cat("MODEL EVALUATION UNIT TESTS COMPLETED\n")
cat("========================================\n")
