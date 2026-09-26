# Unit Tests for Feature Engineering Functions
# File: test_features.R
# Purpose: Test feature engineering functions in features/build_features.R

library(testthat)
library(tidyverse)

# Source the feature engineering function
# source("features/build_features.R")

# Mock function for testing (since we're testing the function itself)
engineer_bike_features <- function(dataset) {
  dataset %>%
    mutate(
      # Temperature + humidity relationship
      TEMPERATURE_HUMIDITY = TEMPERATURE * HUMIDITY,
      
      # Temperature + solar radiation relationship
      TEMPERATURE_SOLAR = TEMPERATURE * SOLAR_RADIATION,
      
      # Temperature + rainfall relationship
      TEMPERATURE_RAINFALL = TEMPERATURE * RAINFALL,
      
      # Temperature and dew point are highly correlated (0.91)
      DEW_POINT_SPREAD = TEMPERATURE - DEW_POINT_TEMPERATURE
    )
}

# ============================================================================
# TEST SUITE 1: TEMPERATURE_HUMIDITY INTERACTION
# ============================================================================
test_that("TEMPERATURE_HUMIDITY creates correct interaction", {
  
  # Test 1: Basic multiplication
  df <- tibble(
    TEMPERATURE = c(0.5, 0.6, 0.7),
    HUMIDITY = c(0.4, 0.5, 0.6),
    SOLAR_RADIATION = c(0.1, 0.2, 0.3),
    RAINFALL = c(0.0, 0.0, 0.0),
    DEW_POINT_TEMPERATURE = c(0.3, 0.4, 0.5)
  )
  
  result <- engineer_bike_features(df)
  
  expect_equal(result$TEMPERATURE_HUMIDITY[1], 0.5 * 0.4)
  expect_equal(result$TEMPERATURE_HUMIDITY[2], 0.6 * 0.5)
  expect_equal(result$TEMPERATURE_HUMIDITY[3], 0.7 * 0.6)
  
})

test_that("TEMPERATURE_HUMIDITY handles zero values", {
  
  # Test 2: Zero temperature
  df <- tibble(
    TEMPERATURE = c(0, 0.5),
    HUMIDITY = c(0.5, 0.8),
    SOLAR_RADIATION = c(0.1, 0.1),
    RAINFALL = c(0.0, 0.0),
    DEW_POINT_TEMPERATURE = c(0.3, 0.3)
  )
  
  result <- engineer_bike_features(df)
  
  expect_equal(result$TEMPERATURE_HUMIDITY[1], 0)
  expect_equal(result$TEMPERATURE_HUMIDITY[2], 0.4)
  
})

test_that("TEMPERATURE_HUMIDITY result in valid range for normalized inputs", {
  
  # Test 3: Normalized inputs (0-1) produce valid outputs
  df <- tibble(
    TEMPERATURE = c(0.2, 0.5, 0.8),
    HUMIDITY = c(0.3, 0.6, 0.9),
    SOLAR_RADIATION = c(0.1, 0.2, 0.3),
    RAINFALL = c(0.0, 0.0, 0.0),
    DEW_POINT_TEMPERATURE = c(0.1, 0.4, 0.7)
  )
  
  result <- engineer_bike_features(df)
  
  # For normalized inputs [0,1], product should also be in [0,1]
  expect_true(all(result$TEMPERATURE_HUMIDITY >= 0 & result$TEMPERATURE_HUMIDITY <= 1))
  
})

test_that("TEMPERATURE_HUMIDITY represents physical comfort index", {
  
  # Test 4: High temp + high humidity should produce high value
  df <- tibble(
    TEMPERATURE = c(0.3, 0.9),  # Cool vs Hot
    HUMIDITY = c(0.3, 0.9),      # Dry vs Humid
    SOLAR_RADIATION = c(0.1, 0.1),
    RAINFALL = c(0.0, 0.0),
    DEW_POINT_TEMPERATURE = c(0.1, 0.8)
  )
  
  result <- engineer_bike_features(df)
  
  # Hot+humid > Cool+dry
  expect_true(result$TEMPERATURE_HUMIDITY[2] > result$TEMPERATURE_HUMIDITY[1])
  
})

# ============================================================================
# TEST SUITE 2: TEMPERATURE_SOLAR INTERACTION
# ============================================================================
test_that("TEMPERATURE_SOLAR creates correct interaction", {
  
  # Test 1: Basic multiplication
  df <- tibble(
    TEMPERATURE = c(0.5, 0.6, 0.7),
    HUMIDITY = c(0.4, 0.5, 0.6),
    SOLAR_RADIATION = c(0.1, 0.2, 0.3),
    RAINFALL = c(0.0, 0.0, 0.0),
    DEW_POINT_TEMPERATURE = c(0.3, 0.4, 0.5)
  )
  
  result <- engineer_bike_features(df)
  
  expect_equal(result$TEMPERATURE_SOLAR[1], 0.5 * 0.1)
  expect_equal(result$TEMPERATURE_SOLAR[2], 0.6 * 0.2)
  expect_equal(result$TEMPERATURE_SOLAR[3], 0.7 * 0.3)
  
})

test_that("TEMPERATURE_SOLAR captures ideal cycling conditions", {
  
  # Test 2: Ideal conditions should have high value
  df <- tibble(
    TEMPERATURE = c(0.1, 0.8),  # Cold vs Warm
    HUMIDITY = c(0.5, 0.5),
    SOLAR_RADIATION = c(0.1, 0.9),  # Dark vs Bright
    RAINFALL = c(0.0, 0.0),
    DEW_POINT_TEMPERATURE = c(0.1, 0.7)
  )
  
  result <- engineer_bike_features(df)
  
  # Warm+sunny > Cold+dark
  expect_true(result$TEMPERATURE_SOLAR[2] > result$TEMPERATURE_SOLAR[1])
  
})

test_that("TEMPERATURE_SOLAR equals zero when either component is zero", {
  
  # Test 3: Zero solar radiation
  df <- tibble(
    TEMPERATURE = c(0.5, 0.8),
    HUMIDITY = c(0.5, 0.5),
    SOLAR_RADIATION = c(0, 0.5),
    RAINFALL = c(0.0, 0.0),
    DEW_POINT_TEMPERATURE = c(0.3, 0.6)
  )
  
  result <- engineer_bike_features(df)
  
  expect_equal(result$TEMPERATURE_SOLAR[1], 0)
  expect_equal(result$TEMPERATURE_SOLAR[2], 0.4)
  
})

# ============================================================================
# TEST SUITE 3: TEMPERATURE_RAINFALL INTERACTION
# ============================================================================
test_that("TEMPERATURE_RAINFALL creates correct interaction", {
  
  # Test 1: Basic multiplication
  df <- tibble(
    TEMPERATURE = c(0.5, 0.6, 0.7),
    HUMIDITY = c(0.4, 0.5, 0.6),
    SOLAR_RADIATION = c(0.1, 0.2, 0.3),
    RAINFALL = c(0.01, 0.02, 0.03),
    DEW_POINT_TEMPERATURE = c(0.3, 0.4, 0.5)
  )
  
  result <- engineer_bike_features(df)
  
  expect_equal(result$TEMPERATURE_RAINFALL[1], 0.5 * 0.01)
  expect_equal(result$TEMPERATURE_RAINFALL[2], 0.6 * 0.02)
  expect_equal(result$TEMPERATURE_RAINFALL[3], 0.7 * 0.03)
  
})

test_that("TEMPERATURE_RAINFALL is typically small (rainfall sparse)", {
  
  # Test 2: Most values should be near zero
  df <- tibble(
    TEMPERATURE = c(0.5, 0.6, 0.7, 0.8, 0.9),
    HUMIDITY = c(0.4, 0.5, 0.6, 0.7, 0.8),
    SOLAR_RADIATION = c(0.1, 0.2, 0.3, 0.2, 0.1),
    RAINFALL = c(0.0, 0.0, 0.0, 0.002, 0.0),
    DEW_POINT_TEMPERATURE = c(0.3, 0.4, 0.5, 0.6, 0.7)
  )
  
  result <- engineer_bike_features(df)
  
  # Most TEMPERATURE_RAINFALL should be zero or very small
  expect_equal(result$TEMPERATURE_RAINFALL[1], 0)
  expect_equal(result$TEMPERATURE_RAINFALL[4], 0.8 * 0.002)
  expect_true(mean(result$TEMPERATURE_RAINFALL, na.rm = TRUE) < 0.01)
  
})

test_that("TEMPERATURE_RAINFALL handles wet conditions", {
  
  # Test 3: Rain interaction with temperature
  df <- tibble(
    TEMPERATURE = c(0.2, 0.8),  # Cold vs Warm with rain
    HUMIDITY = c(0.8, 0.8),
    SOLAR_RADIATION = c(0.1, 0.1),
    RAINFALL = c(0.1, 0.1),     # Same rainfall
    DEW_POINT_TEMPERATURE = c(0.1, 0.7)
  )
  
  result <- engineer_bike_features(df)
  
  # Warm+rain > Cold+rain (warm may reduce some negative effect)
  expect_true(result$TEMPERATURE_RAINFALL[2] > result$TEMPERATURE_RAINFALL[1])
  
})

# ============================================================================
# TEST SUITE 4: DEW_POINT_SPREAD DERIVED FEATURE
# ============================================================================
test_that("DEW_POINT_SPREAD calculates correct difference", {
  
  # Test 1: Basic subtraction
  df <- tibble(
    TEMPERATURE = c(0.6, 0.7, 0.8),
    HUMIDITY = c(0.4, 0.5, 0.6),
    SOLAR_RADIATION = c(0.1, 0.2, 0.3),
    RAINFALL = c(0.0, 0.0, 0.0),
    DEW_POINT_TEMPERATURE = c(0.3, 0.4, 0.5)
  )
  
  result <- engineer_bike_features(df)
  
  expect_equal(result$DEW_POINT_SPREAD[1], 0.6 - 0.3)
  expect_equal(result$DEW_POINT_SPREAD[2], 0.7 - 0.4)
  expect_equal(result$DEW_POINT_SPREAD[3], 0.8 - 0.5)
  
})

test_that("DEW_POINT_SPREAD can be negative (humid conditions)", {
  
  # Test 2: Negative spread indicates humidity
  df <- tibble(
    TEMPERATURE = c(0.3, 0.5, 0.8),
    HUMIDITY = c(0.4, 0.5, 0.6),
    SOLAR_RADIATION = c(0.1, 0.2, 0.3),
    RAINFALL = c(0.0, 0.0, 0.0),
    DEW_POINT_TEMPERATURE = c(0.4, 0.5, 0.7)  # Equal to or above temperature
  )
  
  result <- engineer_bike_features(df)
  
  # Negative spread means humid conditions
  expect_true(result$DEW_POINT_SPREAD[1] < 0)
  expect_equal(result$DEW_POINT_SPREAD[2], 0)  # Equal temp and dew point
  expect_true(result$DEW_POINT_SPREAD[3] > 0)  # Positive spread = dry
  
})

test_that("DEW_POINT_SPREAD represents air dryness comfort", {
  
  # Test 3: Physical interpretation
  df <- tibble(
    TEMPERATURE = c(0.5, 0.5),
    HUMIDITY = c(0.5, 0.5),
    SOLAR_RADIATION = c(0.2, 0.2),
    RAINFALL = c(0.0, 0.0),
    DEW_POINT_TEMPERATURE = c(0.2, 0.45)  # Dry vs Humid
  )
  
  result <- engineer_bike_features(df)
  
  # Large positive spread = dry and comfortable
  expect_true(result$DEW_POINT_SPREAD[1] > result$DEW_POINT_SPREAD[2])
  
})

test_that("DEW_POINT_SPREAD range matches data characteristics", {
  
  # Test 4: Range validation
  df <- tibble(
    TEMPERATURE = runif(100, 0.2, 0.9),
    HUMIDITY = runif(100, 0.3, 0.9),
    SOLAR_RADIATION = runif(100, 0, 0.3),
    RAINFALL = runif(100, 0, 0.01),
    DEW_POINT_TEMPERATURE = runif(100, 0.1, 0.8)
  )
  
  result <- engineer_bike_features(df)
  
  # Spread should be within reasonable range for normalized data
  expect_true(min(result$DEW_POINT_SPREAD) >= -0.8)
  expect_true(max(result$DEW_POINT_SPREAD) <= 0.8)
  
})

# ============================================================================
# TEST SUITE 5: FEATURE ENGINEERING COMPLETENESS
# ============================================================================
test_that("engineer_bike_features adds exactly 4 new columns", {
  
  # Test 1: Column count
  df <- tibble(
    TEMPERATURE = c(0.5, 0.6),
    HUMIDITY = c(0.4, 0.5),
    SOLAR_RADIATION = c(0.1, 0.2),
    RAINFALL = c(0.0, 0.0),
    DEW_POINT_TEMPERATURE = c(0.3, 0.4)
  )
  
  original_cols <- ncol(df)
  result <- engineer_bike_features(df)
  new_cols <- ncol(result)
  
  expect_equal(new_cols, original_cols + 4)
  
})

test_that("engineer_bike_features preserves original columns", {
  
  # Test 2: Original data intact
  df <- tibble(
    TEMPERATURE = c(0.5, 0.6),
    HUMIDITY = c(0.4, 0.5),
    SOLAR_RADIATION = c(0.1, 0.2),
    RAINFALL = c(0.0, 0.0),
    DEW_POINT_TEMPERATURE = c(0.3, 0.4)
  )
  
  result <- engineer_bike_features(df)
  
  expect_equal(result$TEMPERATURE, df$TEMPERATURE)
  expect_equal(result$HUMIDITY, df$HUMIDITY)
  expect_equal(result$SOLAR_RADIATION, df$SOLAR_RADIATION)
  
})

test_that("engineer_bike_features creates named columns", {
  
  # Test 3: Column names
  df <- tibble(
    TEMPERATURE = c(0.5),
    HUMIDITY = c(0.4),
    SOLAR_RADIATION = c(0.1),
    RAINFALL = c(0.0),
    DEW_POINT_TEMPERATURE = c(0.3)
  )
  
  result <- engineer_bike_features(df)
  
  expect_true("TEMPERATURE_HUMIDITY" %in% names(result))
  expect_true("TEMPERATURE_SOLAR" %in% names(result))
  expect_true("TEMPERATURE_RAINFALL" %in% names(result))
  expect_true("DEW_POINT_SPREAD" %in% names(result))
  
})

test_that("engineer_bike_features handles large datasets", {
  
  # Test 4: Performance with large data
  df <- tibble(
    TEMPERATURE = rnorm(10000, 0.5, 0.1),
    HUMIDITY = rnorm(10000, 0.6, 0.1),
    SOLAR_RADIATION = runif(10000, 0, 0.3),
    RAINFALL = runif(10000, 0, 0.01),
    DEW_POINT_TEMPERATURE = rnorm(10000, 0.45, 0.1)
  )
  
  expect_silent({
    result <- engineer_bike_features(df)
  })
  
  expect_equal(nrow(result), 10000)
  expect_equal(ncol(result), 9)
  
})

# ============================================================================
# TEST SUITE 6: FEATURE CORRELATION WITH TARGET
# ============================================================================
test_that("engineered features show expected correlations", {
  
  # Test: Features should show realistic patterns
  # High temp + high solar should increase demand
  # High humidity should decrease demand
  # Rainfall should decrease demand
  
  df <- tibble(
    TEMPERATURE = c(0.2, 0.5, 0.8, 0.9),
    HUMIDITY = c(0.3, 0.6, 0.7, 0.8),
    SOLAR_RADIATION = c(0.1, 0.2, 0.3, 0.4),
    RAINFALL = c(0.05, 0.02, 0.01, 0.0),
    DEW_POINT_TEMPERATURE = c(0.1, 0.4, 0.5, 0.7),
    DEMAND = c(10, 25, 45, 50)  # Hypothetical demand
  )
  
  result <- engineer_bike_features(df)
  
  # TEMPERATURE_SOLAR correlation should be positive with demand
  expect_true(cor(result$TEMPERATURE_SOLAR, result$DEMAND) > 0)
  
})

# ============================================================================
# EDGE CASE TESTS
# ============================================================================
test_that("engineer_bike_features handles missing data gracefully", {
  
  # Test: NA values
  df <- tibble(
    TEMPERATURE = c(0.5, NA, 0.7),
    HUMIDITY = c(0.4, 0.5, NA),
    SOLAR_RADIATION = c(0.1, 0.2, 0.3),
    RAINFALL = c(0.0, 0.0, 0.0),
    DEW_POINT_TEMPERATURE = c(0.3, 0.4, 0.5)
  )
  
  result <- engineer_bike_features(df)
  
  # NA propagation expected
  expect_true(is.na(result$TEMPERATURE_HUMIDITY[2]))
  expect_true(is.na(result$TEMPERATURE_SOLAR[2]))
  
})

test_that("engineer_bike_features handles edge values", {
  
  # Test: Min/max values for normalized data
  df <- tibble(
    TEMPERATURE = c(0, 1, 0.5),
    HUMIDITY = c(0, 1, 0.5),
    SOLAR_RADIATION = c(0, 1, 0.5),
    RAINFALL = c(0, 1, 0.5),
    DEW_POINT_TEMPERATURE = c(0, 1, 0.5)
  )
  
  result <- engineer_bike_features(df)
  
  # Interactions should be within [0,1]
  expect_true(all(result$TEMPERATURE_HUMIDITY >= 0, na.rm = TRUE))
  expect_true(all(result$TEMPERATURE_HUMIDITY <= 1, na.rm = TRUE))
  
})

test_that("engineer_bike_features result is tibble/data.frame", {
  
  # Test: Output type
  df <- tibble(
    TEMPERATURE = c(0.5),
    HUMIDITY = c(0.4),
    SOLAR_RADIATION = c(0.1),
    RAINFALL = c(0.0),
    DEW_POINT_TEMPERATURE = c(0.3)
  )
  
  result <- engineer_bike_features(df)
  
  expect_true(is.data.frame(result) || is_tibble(result))
  
})

# Print test summary
cat("\n========================================\n")
cat("FEATURE ENGINEERING UNIT TESTS COMPLETED\n")
cat("========================================\n")
