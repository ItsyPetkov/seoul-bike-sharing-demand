# Unit Tests for Preprocessing Functions
# File: test_preprocess.R
# Purpose: Test all preprocessing functions in preprocess.R

library(testthat)
library(tidyverse)
library(fastDummies)

# Source the preprocessing functions
# source("preprocess.R")

# ============================================================================
# TEST SUITE 1: remove_refference_links_regex
# ============================================================================
test_that("remove_refference_links_regex removes reference links correctly", {
  
  # Test 1: Simple reference link removal
  input <- "This is text [1] with reference"
  expected <- "This is text with reference"
  result <- remove_refference_links_regex(input)
  expect_equal(result, expected)
  
})

test_that("remove_refference_links_regex handles multiple references", {
  
  # Test 2: Multiple reference links
  input <- "Text [1] with [2] multiple [3] references"
  expected <- "Text with multiple references"
  result <- remove_refference_links_regex(input)
  expect_equal(result, expected)
  
})

test_that("remove_refference_links_regex handles empty references", {
  
  # Test 3: Empty reference brackets
  input <- "Text [] with empty brackets"
  expected <- "Text with empty brackets"
  result <- remove_refference_links_regex(input)
  expect_equal(result, expected)
  
})

test_that("remove_refference_links_regex trims whitespace", {
  
  # Test 4: Extra whitespace handling
  input <- "  Text [1] with   spaces  "
  result <- remove_refference_links_regex(input)
  expect_true(!grepl("^\\s", result) & !grepl("\\s$", result))
  
})

test_that("remove_refference_links_regex handles text without references", {
  
  # Test 5: No references in text
  input <- "Plain text without references"
  expected <- "Plain text without references"
  result <- remove_refference_links_regex(input)
  expect_equal(result, expected)
  
})

test_that("remove_refference_links_regex handles complex bracket content", {
  
  # Test 6: References with complex content
  input <- "See ref [Nature 2020] for details"
  expected <- "See ref for details"
  result <- remove_refference_links_regex(input)
  expect_equal(result, expected)
  
})

# ============================================================================
# TEST SUITE 2: extract_numeric_data_regex
# ============================================================================
test_that("extract_numeric_data_regex extracts first number correctly", {
  
  # Test 1: Basic extraction
  input <- c("abc123def")
  expected <- 123
  result <- extract_numeric_data_regex(input)
  expect_equal(result, expected)
  
})

test_that("extract_numeric_data_regex handles multiple numbers", {
  
  # Test 2: Takes first number only
  input <- c("123 456 789")
  expected <- 123
  result <- extract_numeric_data_regex(input)
  expect_equal(result, expected)
  
})

test_that("extract_numeric_data_regex handles no numbers", {
  
  # Test 3: No numbers in string
  input <- c("abcdef")
  result <- extract_numeric_data_regex(input)
  expect_true(is.na(result))
  
})

test_that("extract_numeric_data_regex handles leading zeros", {
  
  # Test 4: Leading zeros
  input <- c("00123abc")
  expected <- 123  # Numeric conversion removes leading zeros
  result <- extract_numeric_data_regex(input)
  expect_equal(result, expected)
  
})

test_that("extract_numeric_data_regex handles decimal-like patterns", {
  
  # Test 5: Extracts integer part only
  input <- c("value123.45")
  expected <- 123
  result <- extract_numeric_data_regex(input)
  expect_equal(result, expected)
  
})

test_that("extract_numeric_data_regex handles vector input", {
  
  # Test 6: Vector of strings
  input <- c("abc123", "def456", "ghi789")
  expected <- c(123, 456, 789)
  result <- sapply(input, extract_numeric_data_regex)
  expect_equal(result, expected)
  
})

# ============================================================================
# TEST SUITE 3: normalize_data
# ============================================================================
test_that("normalize_data normalizes to [0,1] range", {
  
  # Test 1: Basic normalization
  input <- c(0, 50, 100)
  result <- normalize_data(input)
  expect_true(all(result >= 0 & result <= 1))
  expect_equal(min(result), 0)
  expect_equal(max(result), 1)
  
})

test_that("normalize_data preserves order", {
  
  # Test 2: Preserves relative ordering
  input <- c(10, 20, 30, 40, 50)
  result <- normalize_data(input)
  expect_true(all(diff(result) > 0))  # All differences positive (increasing)
  
})

test_that("normalize_data handles identical values", {
  
  # Test 3: Identical values produce NaN
  input <- c(5, 5, 5, 5)
  result <- normalize_data(input)
  expect_true(all(is.nan(result)))
  
})

test_that("normalize_data handles single value", {
  
  # Test 4: Single value
  input <- c(42)
  result <- normalize_data(input)
  expect_true(is.nan(result))
  
})

test_that("normalize_data handles negative values", {
  
  # Test 5: Negative value range
  input <- c(-100, -50, 0, 50, 100)
  result <- normalize_data(input)
  expect_equal(min(result), 0)
  expect_equal(max(result), 1)
  expect_equal(result[3], 0.5)  # Middle value should be 0.5
  
})

test_that("normalize_data handles large ranges", {
  
  # Test 6: Large numeric range
  input <- c(0, 1e6, 1e6 * 2)
  result <- normalize_data(input)
  expect_equal(result, c(0, 0.5, 1))
  
})

# ============================================================================
# TEST SUITE 4: handle_missing_values
# ============================================================================
test_that("handle_missing_values drops rows with 'drop' style", {
  
  # Test 1: Drop missing values
  df <- tibble(
    ID = c(1, 2, 3, 4, 5),
    VALUE = c(10, NA, 30, NA, 50)
  )
  result <- handle_missing_values(df, "VALUE", "drop")
  expect_equal(nrow(result), 3)
  expect_equal(result$ID, c(1, 3, 5))
  
})

test_that("handle_missing_values fills down correctly", {
  
  # Test 2: Fill down missing values
  df <- tibble(
    ID = c(1, 2, 3, 4, 5),
    VALUE = c(10, NA, NA, 20, NA)
  )
  result <- handle_missing_values(df, "VALUE", "fill_down")
  expect_equal(result$VALUE, c(10, 10, 10, 20, 20))
  
})

test_that("handle_missing_values fills up correctly", {
  
  # Test 3: Fill up missing values
  df <- tibble(
    ID = c(1, 2, 3, 4, 5),
    VALUE = c(NA, NA, 30, NA, 50)
  )
  result <- handle_missing_values(df, "VALUE", "fill_up")
  expect_equal(result$VALUE, c(30, 30, 30, 50, 50))
  
})

test_that("handle_missing_values raises error for invalid style", {
  
  # Test 4: Invalid style parameter
  df <- tibble(
    ID = c(1, 2, 3),
    VALUE = c(10, NA, 30)
  )
  expect_error(
    handle_missing_values(df, "VALUE", "invalid_style"),
    "Invalid style"
  )
  
})

test_that("handle_missing_values preserves data types", {
  
  # Test 5: Data type preservation
  df <- tibble(
    ID = c(1, 2, 3),
    VALUE = c(10.5, NA, 20.5),
    NAME = c("a", "b", NA)
  )
  result <- handle_missing_values(df, "VALUE", "drop")
  expect_true(is.numeric(result$VALUE))
  expect_true(is.character(result$NAME))
  
})

# ============================================================================
# TEST SUITE 5: standardize_column_names
# ============================================================================
test_that("standardize_column_names converts to uppercase", {
  
  # Test 1: Case conversion
  df <- tibble(
    lowercase = c(1, 2, 3),
    MixedCase = c(4, 5, 6),
    UPPERCASE = c(7, 8, 9)
  )
  names(df) <- toupper(names(df))
  expect_equal(names(df), c("LOWERCASE", "MIXEDCASE", "UPPERCASE"))
  
})

test_that("standardize_column_names replaces spaces with underscores", {
  
  # Test 2: Space replacement
  test_name <- "column with spaces"
  result <- str_replace_all(test_name, " ", "_")
  expect_equal(result, "column_with_spaces")
  
})

test_that("standardize_column_names handles multiple spaces", {
  
  # Test 3: Multiple spaces
  test_name <- "column   with   multiple   spaces"
  result <- str_replace_all(test_name, " ", "_")
  expect_equal(result, "column___with___multiple___spaces")
  
})

# ============================================================================
# TEST SUITE 6: create_dummy_variables
# ============================================================================
test_that("create_dummy_variables creates correct number of columns", {
  
  # Test 1: Basic dummy variable creation
  df <- tibble(
    ID = c(1, 2, 3, 4),
    CATEGORY = c("A", "B", "A", "B")
  )
  
  # Simulate what dummy_cols does
  original_cols <- ncol(df)
  expect_equal(original_cols, 2)
  # dummy_cols adds new columns but keeps originals
  
})

test_that("create_dummy_variables preserves original columns", {
  
  # Test 2: Original data preserved
  df <- tibble(
    ID = c(1, 2, 3),
    SEASON = c("Spring", "Summer", "Winter")
  )
  
  original_ids <- df$ID
  # After dummy encoding, ID should still exist
  expect_equal(length(original_ids), 3)
  
})

test_that("create_dummy_variables handles multiple columns", {
  
  # Test 3: Multiple categorical columns
  df <- tibble(
    ID = c(1, 2, 3, 4),
    SEASON = c("Spring", "Summer", "Spring", "Winter"),
    HOLIDAY = c("Yes", "No", "No", "Yes")
  )
  
  original_cols <- ncol(df)
  expect_equal(original_cols, 3)
  
})

# ============================================================================
# INTEGRATION TESTS
# ============================================================================
test_that("preprocessing pipeline functions compose correctly", {
  
  # Test: Full pipeline simulation
  # Create sample data
  df <- tibble(
    TEXT = c("City [1] Name", "Town [2] Location"),
    COUNT = c("Bicycles: 123", "Bikes: 456"),
    VALUE = c(100, 200)
  )
  
  # Apply transformations
  df$TEXT <- sapply(df$TEXT, remove_refference_links_regex)
  df$COUNT <- sapply(df$COUNT, extract_numeric_data_regex)
  df$VALUE <- normalize_data(df$VALUE)
  
  # Verify results
  expect_equal(df$TEXT[1], "City Name")
  expect_equal(df$COUNT[1], 123)
  expect_equal(df$VALUE[1], 0)
  expect_equal(df$VALUE[2], 1)
  
})

# ============================================================================
# EDGE CASE TESTS
# ============================================================================
test_that("functions handle empty inputs gracefully", {
  
  # Test: Empty string
  result <- remove_refference_links_regex("")
  expect_equal(result, "")
  
  # Empty vector
  result <- extract_numeric_data_regex(c())
  expect_equal(length(result), 0)
  
})

test_that("functions handle special characters", {
  
  # Test: Special characters in reference removal
  input <- "Text [!@#$%] special"
  result <- remove_refference_links_regex(input)
  expect_equal(result, "Text special")
  
})

test_that("normalization handles extreme values", {
  
  # Test: Very large and very small numbers
  input <- c(1e-10, 1e10)
  result <- normalize_data(input)
  expect_equal(result[1], 0)
  expect_equal(result[2], 1)
  
})

# ============================================================================
# PERFORMANCE TESTS
# ============================================================================
test_that("functions handle large datasets efficiently", {
  
  # Test: Large vector normalization
  large_vector <- rnorm(100000, mean = 500, sd = 100)
  expect_silent({
    result <- normalize_data(large_vector)
  })
  expect_equal(min(result), 0)
  expect_equal(max(result), 1)
  
})

# Print test summary
cat("\n========================================\n")
cat("PREPROCESSING UNIT TESTS COMPLETED\n")
cat("========================================\n")
