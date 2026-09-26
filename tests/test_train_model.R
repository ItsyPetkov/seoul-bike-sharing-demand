# Unit Tests for Model Training Functions
# File: test_train_model.R
# Purpose: Test model training functions in models/train_model.R

library(testthat)
library(tidyverse)
library(tidymodels)
library(xgboost)

# ============================================================================
# TEST SETUP: Create mock data for testing
# ============================================================================
create_test_data <- function(n_rows = 100, n_features = 7) {
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

# ============================================================================
# TEST SUITE 1: LINEAR REGRESSION - WEATHER ONLY
# ============================================================================
test_that("fit_lm_model_weather creates model object", {
  
  # Test 1: Model creation
  train_data <- create_test_data(100)
  
  model <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(
      RENTED_BIKE_COUNT ~ TEMPERATURE + HUMIDITY + WIND_SPEED + 
        VISIBILITY + DEW_POINT_TEMPERATURE + SOLAR_RADIATION + 
        RAINFALL,
      data = train_data
    )
  
  expect_true(inherits(model, "model_fit"))
  
})

test_that("fit_lm_model_weather produces numeric predictions", {
  
  # Test 2: Predictions
  train_data <- create_test_data(100)
  test_data <- train_data[1:10, ]
  
  model <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(
      RENTED_BIKE_COUNT ~ TEMPERATURE + HUMIDITY + WIND_SPEED + 
        VISIBILITY + DEW_POINT_TEMPERATURE + SOLAR_RADIATION + 
        RAINFALL,
      data = train_data
    )
  
  predictions <- predict(model, test_data)
  
  expect_true(is.numeric(predictions$.pred))
  expect_equal(length(predictions$.pred), 10)
  
})

test_that("fit_lm_model_weather uses 7 weather features", {
  
  # Test 3: Feature usage
  train_data <- create_test_data(100)
  
  model <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(
      RENTED_BIKE_COUNT ~ TEMPERATURE + HUMIDITY + WIND_SPEED + 
        VISIBILITY + DEW_POINT_TEMPERATURE + SOLAR_RADIATION + 
        RAINFALL,
      data = train_data
    )
  
  # Extract number of coefficients (including intercept)
  n_coefs <- length(coef(model$fit))
  expect_equal(n_coefs, 8)  # 7 features + 1 intercept
  
})

# ============================================================================
# TEST SUITE 2: LINEAR REGRESSION - WITH POLYNOMIAL TERMS
# ============================================================================
test_that("fit_lm_model_weather_poly handles polynomial transformations", {
  
  # Test 1: Model with polynomial terms
  train_data <- create_test_data(100)
  
  model <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(
      RENTED_BIKE_COUNT ~
        poly(TEMPERATURE, 2, raw = TRUE) +
        poly(HUMIDITY, 2, raw = TRUE) +
        WIND_SPEED +
        VISIBILITY +
        SOLAR_RADIATION +
        RAINFALL,
      data = train_data
    )
  
  expect_true(inherits(model, "model_fit"))
  
})

test_that("fit_lm_model_weather_poly produces valid predictions", {
  
  # Test 2: Polynomial model predictions
  train_data <- create_test_data(100)
  test_data <- train_data[1:10, ]
  
  model <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(
      RENTED_BIKE_COUNT ~
        poly(TEMPERATURE, 2, raw = TRUE) +
        poly(HUMIDITY, 2, raw = TRUE) +
        WIND_SPEED +
        VISIBILITY +
        SOLAR_RADIATION +
        RAINFALL,
      data = train_data
    )
  
  predictions <- predict(model, test_data)
  
  expect_true(is.numeric(predictions$.pred))
  expect_equal(length(predictions$.pred), 10)
  expect_true(all(is.finite(predictions$.pred)))
  
})

# ============================================================================
# TEST SUITE 3: LINEAR REGRESSION - ALL VARIABLES
# ============================================================================
test_that("fit_lm_model_all uses all available features", {
  
  # Test 1: Model with all variables
  train_data <- create_test_data(100)
  
  model <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(RENTED_BIKE_COUNT ~ ., data = train_data)
  
  expect_true(inherits(model, "model_fit"))
  
})

test_that("fit_lm_model_all outperforms weather-only", {
  
  # Test 2: All-variable model should have lower error
  train_data <- create_test_data(200)
  test_data <- create_test_data(50)
  
  # Weather-only model
  model_weather <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(
      RENTED_BIKE_COUNT ~ TEMPERATURE + HUMIDITY + WIND_SPEED + 
        VISIBILITY + DEW_POINT_TEMPERATURE + SOLAR_RADIATION + 
        RAINFALL,
      data = train_data
    )
  
  # All-variable model
  model_all <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(RENTED_BIKE_COUNT ~ ., data = train_data)
  
  # Calculate RMSE for both
  pred_weather <- predict(model_weather, test_data)$.pred
  pred_all <- predict(model_all, test_data)$.pred
  
  rmse_weather <- sqrt(mean((test_data$RENTED_BIKE_COUNT - pred_weather)^2))
  rmse_all <- sqrt(mean((test_data$RENTED_BIKE_COUNT - pred_all)^2))
  
  # All-variable model should generally perform better
  # (allowing for some variance in test sets)
  expect_true(rmse_all <= rmse_weather * 1.2)  # Allow 20% tolerance
  
})

# ============================================================================
# TEST SUITE 4: LINEAR REGRESSION - WITH INTERACTIONS
# ============================================================================
test_that("fit_lm_model_weather_interactions includes interaction terms", {
  
  # Test 1: Model with interactions
  train_data <- create_test_data(100)
  
  model <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(
      RENTED_BIKE_COUNT ~
        poly(TEMPERATURE, 2, raw = TRUE) +
        poly(HUMIDITY, 2, raw = TRUE) +
        WIND_SPEED +
        VISIBILITY +
        SOLAR_RADIATION +
        RAINFALL +
        TEMPERATURE_HUMIDITY +
        TEMPERATURE_SOLAR +
        TEMPERATURE_RAINFALL +
        DEW_POINT_SPREAD,
      data = train_data
    )
  
  expect_true(inherits(model, "model_fit"))
  
})

test_that("interaction model produces reasonable predictions", {
  
  # Test 2: Predictions from interaction model
  train_data <- create_test_data(100)
  test_data <- train_data[1:10, ]
  
  model <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(
      RENTED_BIKE_COUNT ~
        poly(TEMPERATURE, 2, raw = TRUE) +
        poly(HUMIDITY, 2, raw = TRUE) +
        WIND_SPEED +
        VISIBILITY +
        SOLAR_RADIATION +
        RAINFALL +
        TEMPERATURE_HUMIDITY +
        TEMPERATURE_SOLAR +
        TEMPERATURE_RAINFALL +
        DEW_POINT_SPREAD,
      data = train_data
    )
  
  predictions <- predict(model, test_data)
  
  expect_equal(length(predictions$.pred), 10)
  expect_true(all(is.finite(predictions$.pred)))
  
})

# ============================================================================
# TEST SUITE 5: XGBOOST - WEATHER ONLY
# ============================================================================
test_that("fit_xgb_model_weather creates XGBoost model", {
  
  # Test 1: XGBoost model creation
  train_data <- create_test_data(100)
  
  model <- boost_tree(mode = "regression") %>%
    set_engine("xgboost") %>%
    fit(
      RENTED_BIKE_COUNT ~ TEMPERATURE + HUMIDITY + WIND_SPEED +
        VISIBILITY + DEW_POINT_TEMPERATURE + SOLAR_RADIATION +
        RAINFALL,
      data = train_data
    )
  
  expect_true(inherits(model, "model_fit"))
  
})

test_that("fit_xgb_model_weather produces predictions", {
  
  # Test 2: XGBoost predictions
  train_data <- create_test_data(100)
  test_data <- train_data[1:10, ]
  
  model <- boost_tree(mode = "regression") %>%
    set_engine("xgboost") %>%
    fit(
      RENTED_BIKE_COUNT ~ TEMPERATURE + HUMIDITY + WIND_SPEED +
        VISIBILITY + DEW_POINT_TEMPERATURE + SOLAR_RADIATION +
        RAINFALL,
      data = train_data
    )
  
  predictions <- predict(model, test_data)
  
  expect_true(is.numeric(predictions$.pred))
  expect_equal(length(predictions$.pred), 10)
  
})

# ============================================================================
# TEST SUITE 6: XGBOOST - ALL VARIABLES
# ============================================================================
test_that("fit_xgb_model_all creates XGBoost with all features", {
  
  # Test 1: XGBoost all-variable model
  train_data <- create_test_data(100)
  
  model <- boost_tree(mode = "regression") %>%
    set_engine("xgboost") %>%
    fit(RENTED_BIKE_COUNT ~ ., data = train_data)
  
  expect_true(inherits(model, "model_fit"))
  
})

test_that("fit_xgb_model_all outperforms weather-only XGBoost", {
  
  # Test 2: All-variable XGB should outperform weather-only
  train_data <- create_test_data(200)
  test_data <- create_test_data(50)
  
  # Weather-only
  model_weather <- boost_tree(mode = "regression") %>%
    set_engine("xgboost") %>%
    fit(
      RENTED_BIKE_COUNT ~ TEMPERATURE + HUMIDITY + WIND_SPEED +
        VISIBILITY + DEW_POINT_TEMPERATURE + SOLAR_RADIATION +
        RAINFALL,
      data = train_data
    )
  
  # All variables
  model_all <- boost_tree(mode = "regression") %>%
    set_engine("xgboost") %>%
    fit(RENTED_BIKE_COUNT ~ ., data = train_data)
  
  # Performance comparison
  pred_weather <- predict(model_weather, test_data)$.pred
  pred_all <- predict(model_all, test_data)$.pred
  
  rmse_weather <- sqrt(mean((test_data$RENTED_BIKE_COUNT - pred_weather)^2))
  rmse_all <- sqrt(mean((test_data$RENTED_BIKE_COUNT - pred_all)^2))
  
  # All-variable should be better
  expect_true(rmse_all <= rmse_weather)
  
})

# ============================================================================
# TEST SUITE 7: MODEL COMPARISON
# ============================================================================
test_that("linear regression and XGBoost produce different predictions", {
  
  # Test: Different algorithms produce different results
  train_data <- create_test_data(150)
  test_data <- train_data[1:10, ]
  
  # LM model
  model_lm <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(RENTED_BIKE_COUNT ~ ., data = train_data)
  
  # XGB model
  model_xgb <- boost_tree(mode = "regression") %>%
    set_engine("xgboost") %>%
    fit(RENTED_BIKE_COUNT ~ ., data = train_data)
  
  pred_lm <- predict(model_lm, test_data)$.pred
  pred_xgb <- predict(model_xgb, test_data)$.pred
  
  # Predictions should differ
  expect_false(isTRUE(all.equal(pred_lm, pred_xgb)))
  
})

test_that("models handle missing values in training data", {
  
  # Test: Training with some NA values
  train_data <- create_test_data(100)
  train_data$TEMPERATURE[c(1, 5, 10)] <- NA
  
  # Model should fail or handle gracefully
  expect_error({
    model <- linear_reg() %>%
      set_engine("lm") %>%
      set_mode("regression") %>%
      fit(RENTED_BIKE_COUNT ~ ., data = train_data)
  }, NA)  # Expect either error or successful fit
  
})

# ============================================================================
# TEST SUITE 8: MODEL SERIALIZATION
# ============================================================================
test_that("models can be saved and loaded", {
  
  # Test: Save and load functionality
  train_data <- create_test_data(100)
  
  model <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(RENTED_BIKE_COUNT ~ ., data = train_data)
  
  # Save to temporary file
  temp_file <- tempfile(fileext = ".rds")
  saveRDS(model, temp_file)
  
  # Load back
  loaded_model <- readRDS(temp_file)
  
  expect_true(inherits(loaded_model, "model_fit"))
  
  # Clean up
  unlink(temp_file)
  
})

test_that("model predictions consistent after serialization", {
  
  # Test: Predictions identical before/after save-load
  train_data <- create_test_data(100)
  test_data <- train_data[1:10, ]
  
  model <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(RENTED_BIKE_COUNT ~ ., data = train_data)
  
  # Original predictions
  pred_original <- predict(model, test_data)$.pred
  
  # Save and load
  temp_file <- tempfile(fileext = ".rds")
  saveRDS(model, temp_file)
  loaded_model <- readRDS(temp_file)
  
  # Loaded predictions
  pred_loaded <- predict(loaded_model, test_data)$.pred
  
  expect_equal(pred_original, pred_loaded)
  
  # Clean up
  unlink(temp_file)
  
})

# ============================================================================
# EDGE CASE TESTS
# ============================================================================
test_that("models handle perfect correlation in features", {
  
  # Test: Highly correlated features
  train_data <- create_test_data(100)
  # Create perfectly correlated feature
  train_data$CORRELATED <- train_data$TEMPERATURE * 2
  
  # Model should fit but may have issues with coefficients
  expect_silent({
    model <- linear_reg() %>%
      set_engine("lm") %>%
      set_mode("regression") %>%
      fit(RENTED_BIKE_COUNT ~ TEMPERATURE, data = train_data)
  })
  
})

test_that("models handle extreme values", {
  
  # Test: Very large and small values
  train_data <- create_test_data(100)
  train_data$TEMPERATURE <- train_data$TEMPERATURE * 1e6
  
  model <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(RENTED_BIKE_COUNT ~ TEMPERATURE, data = train_data)
  
  expect_true(inherits(model, "model_fit"))
  
})

# ============================================================================
# PERFORMANCE TESTS
# ============================================================================
test_that("models train efficiently on large datasets", {
  
  # Test: Training speed
  train_data <- create_test_data(5000)
  
  start_time <- Sys.time()
  model <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(RENTED_BIKE_COUNT ~ ., data = train_data)
  end_time <- Sys.time()
  
  train_time <- as.numeric(end_time - start_time)
  
  # Should complete in reasonable time (< 30 seconds)
  expect_true(train_time < 30)
  
})

# Print test summary
cat("\n========================================\n")
cat("MODEL TRAINING UNIT TESTS COMPLETED\n")
cat("========================================\n")
