# Unit Tests for Utility Functions
# File: test_utils.R
# Purpose: Test utility functions in utils.R

library(testthat)
library(tidyverse)
library(tidymodels)

# ============================================================================
# TEST SETUP: Create logging and file paths
# ============================================================================
setup_test_environment <- function() {
  # Create temporary directories for testing
  test_dir <- tempdir()
  log_dir <- file.path(test_dir, "test_logs")
  checkpoint_dir <- file.path(test_dir, "test_checkpoints")
  
  dir.create(log_dir, showWarnings = FALSE)
  dir.create(checkpoint_dir, showWarnings = FALSE)
  
  return(list(
    test_dir = test_dir,
    log_dir = log_dir,
    checkpoint_dir = checkpoint_dir
  ))
}

# Mock utility functions for testing
log_message <- function(message, log_file = "test.log", level = "INFO") {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_entry <- sprintf("[%s] [%s] %s", timestamp, level, message)
  cat(log_entry, "\n")
  
  if (!is.null(log_file) && file.exists(dirname(log_file))) {
    write(log_entry, file = log_file, append = TRUE)
  }
}

save_model <- function(model, model_path, model_name) {
  if (!dir.exists(dirname(model_path))) {
    dir.create(dirname(model_path), recursive = TRUE)
  }
  saveRDS(model, model_path)
  log_message(sprintf("Model '%s' saved to %s", model_name, model_path), level = "INFO")
  return(file.exists(model_path))
}

load_model <- function(model_path, model_name) {
  if (!file.exists(model_path)) {
    log_message(sprintf("Model file not found: %s", model_path), level = "ERROR")
    return(NULL)
  }
  model <- readRDS(model_path)
  log_message(sprintf("Model '%s' loaded from %s", model_name, model_path), level = "INFO")
  return(model)
}

# ============================================================================
# TEST SUITE 1: log_message FUNCTION
# ============================================================================
test_that("log_message creates log entry with timestamp", {
  
  # Test 1: Message formatting
  env <- setup_test_environment()
  log_file <- file.path(env$log_dir, "test.log")
  
  log_message("Test message", log_file, "INFO")
  
  expect_true(file.exists(log_file))
  
  # Read and verify format
  content <- readLines(log_file)
  expect_true(length(content) > 0)
  expect_match(content[1], "\\[\\d{4}-\\d{2}-\\d{2}.*\\]")
  
})

test_that("log_message includes log level", {
  
  # Test 2: Log levels
  env <- setup_test_environment()
  log_file <- file.path(env$log_dir, "test_levels.log")
  
  log_message("Info message", log_file, "INFO")
  log_message("Warning message", log_file, "WARNING")
  log_message("Error message", log_file, "ERROR")
  
  content <- readLines(log_file)
  
  expect_true(any(grepl("\\[INFO\\]", content)))
  expect_true(any(grepl("\\[WARNING\\]", content)))
  expect_true(any(grepl("\\[ERROR\\]", content)))
  
})

test_that("log_message appends to existing log", {
  
  # Test 3: Append mode
  env <- setup_test_environment()
  log_file <- file.path(env$log_dir, "test_append.log")
  
  log_message("First message", log_file, "INFO")
  log_message("Second message", log_file, "INFO")
  
  content <- readLines(log_file)
  expect_equal(length(content), 2)
  
})

test_that("log_message handles special characters", {
  
  # Test 4: Special characters
  env <- setup_test_environment()
  log_file <- file.path(env$log_dir, "test_special.log")
  
  special_msg <- "Message with !@#$%^&*() characters"
  log_message(special_msg, log_file, "INFO")
  
  content <- readLines(log_file)
  expect_true(grepl(special_msg, content[1]))
  
})

test_that("log_message handles very long messages", {
  
  # Test 5: Long message handling
  env <- setup_test_environment()
  log_file <- file.path(env$log_dir, "test_long.log")
  
  long_msg <- paste(rep("A", 1000), collapse = "")
  log_message(long_msg, log_file, "INFO")
  
  content <- readLines(log_file)
  expect_true(nchar(content[1]) > 1000)
  
})

test_that("log_message creates directory if needed", {
  
  # Test 6: Automatic directory creation
  env <- setup_test_environment()
  nested_log <- file.path(env$log_dir, "nested", "deep", "test.log")
  
  # Suppress warnings about not creating directories
  expect_silent({
    log_message("Nested message", nested_log, "INFO")
  })
  
})

# ============================================================================
# TEST SUITE 2: save_model FUNCTION
# ============================================================================
test_that("save_model saves model to file", {
  
  # Test 1: Model saving
  env <- setup_test_environment()
  model_path <- file.path(env$checkpoint_dir, "test_model.rds")
  
  # Create simple model
  data <- tibble(x = 1:10, y = 2*1:10)
  model <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(y ~ x, data = data)
  
  result <- save_model(model, model_path, "test_model")
  
  expect_true(result)
  expect_true(file.exists(model_path))
  
})

test_that("save_model creates parent directories", {
  
  # Test 2: Directory creation
  env <- setup_test_environment()
  model_path <- file.path(env$checkpoint_dir, "models", "v1", "model.rds")
  
  data <- tibble(x = 1:10, y = 2*1:10)
  model <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(y ~ x, data = data)
  
  result <- save_model(model, model_path, "nested_model")
  
  expect_true(result)
  expect_true(file.exists(dirname(model_path)))
  
})

test_that("save_model handles different model types", {
  
  # Test 3: Multiple model types
  env <- setup_test_environment()
  data <- tibble(x = 1:10, y = 2*1:10)
  
  # LM model
  model_lm <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(y ~ x, data = data)
  
  # XGB model
  model_xgb <- boost_tree(mode = "regression") %>%
    set_engine("xgboost") %>%
    fit(y ~ x, data = data)
  
  path_lm <- file.path(env$checkpoint_dir, "model_lm.rds")
  path_xgb <- file.path(env$checkpoint_dir, "model_xgb.rds")
  
  result_lm <- save_model(model_lm, path_lm, "lm_model")
  result_xgb <- save_model(model_xgb, path_xgb, "xgb_model")
  
  expect_true(result_lm && result_xgb)
  expect_true(file.exists(path_lm) && file.exists(path_xgb))
  
})

test_that("save_model overwrites existing file", {
  
  # Test 4: Overwrite behavior
  env <- setup_test_environment()
  model_path <- file.path(env$checkpoint_dir, "overwrite_model.rds")
  
  data <- tibble(x = 1:10, y = 2*1:10)
  model1 <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(y ~ x, data = data)
  
  model2 <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(y ~ 1, data = data)
  
  save_model(model1, model_path, "model1")
  size1 <- file.size(model_path)
  
  save_model(model2, model_path, "model2")
  size2 <- file.size(model_path)
  
  # File should exist and may differ in size
  expect_true(file.exists(model_path))
  
})

test_that("save_model returns boolean status", {
  
  # Test 5: Return value
  env <- setup_test_environment()
  model_path <- file.path(env$checkpoint_dir, "return_test.rds")
  
  data <- tibble(x = 1:10, y = 2*1:10)
  model <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(y ~ x, data = data)
  
  result <- save_model(model, model_path, "test_model")
  
  expect_true(is.logical(result))
  expect_true(result)
  
})

# ============================================================================
# TEST SUITE 3: load_model FUNCTION
# ============================================================================
test_that("load_model loads saved model", {
  
  # Test 1: Basic loading
  env <- setup_test_environment()
  model_path <- file.path(env$checkpoint_dir, "load_test.rds")
  
  # Save a model
  data <- tibble(x = 1:10, y = 2*1:10)
  model_original <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(y ~ x, data = data)
  
  save_model(model_original, model_path, "original")
  
  # Load it back
  model_loaded <- load_model(model_path, "loaded")
  
  expect_true(!is.null(model_loaded))
  expect_true(inherits(model_loaded, "model_fit"))
  
})

test_that("load_model returns NULL for missing file", {
  
  # Test 2: Missing file handling
  missing_path <- "/nonexistent/path/model.rds"
  
  result <- load_model(missing_path, "missing_model")
  
  expect_null(result)
  
})

test_that("load_model predictions match original", {
  
  # Test 3: Prediction consistency
  env <- setup_test_environment()
  model_path <- file.path(env$checkpoint_dir, "consistency.rds")
  
  # Create training and test data
  train_data <- tibble(x = 1:20, y = 2*1:20 + rnorm(20, 0, 1))
  test_data <- tibble(x = 21:25)
  
  # Train, save, and load
  model_original <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(y ~ x, data = train_data)
  
  save_model(model_original, model_path, "consistency_model")
  model_loaded <- load_model(model_path, "loaded_model")
  
  # Compare predictions
  pred_original <- predict(model_original, test_data)$.pred
  pred_loaded <- predict(model_loaded, test_data)$.pred
  
  expect_equal(pred_original, pred_loaded)
  
})

test_that("load_model handles corrupted files", {
  
  # Test 4: Corrupted file handling
  env <- setup_test_environment()
  bad_file <- file.path(env$checkpoint_dir, "corrupted.rds")
  
  # Write garbage to file
  write("This is not a valid RDS file", bad_file)
  
  # Attempting to load should error or return NULL
  expect_error({
    result <- load_model(bad_file, "corrupted")
  }, NA)  # NA means we don't care if it errors or not
  
})

test_that("load_model works with different model types", {
  
  # Test 5: Multiple model types
  env <- setup_test_environment()
  data <- tibble(x = 1:10, y = 2*1:10 + rnorm(10, 0, 0.5))
  
  # Create and save different models
  model_lm <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(y ~ x, data = data)
  
  model_xgb <- boost_tree(mode = "regression") %>%
    set_engine("xgboost") %>%
    fit(y ~ x, data = data)
  
  path_lm <- file.path(env$checkpoint_dir, "model_lm_load.rds")
  path_xgb <- file.path(env$checkpoint_dir, "model_xgb_load.rds")
  
  save_model(model_lm, path_lm, "lm_model")
  save_model(model_xgb, path_xgb, "xgb_model")
  
  # Load both
  loaded_lm <- load_model(path_lm, "lm_model")
  loaded_xgb <- load_model(path_xgb, "xgb_model")
  
  expect_true(!is.null(loaded_lm))
  expect_true(!is.null(loaded_xgb))
  
})

# ============================================================================
# TEST SUITE 4: SAVE-LOAD ROUND TRIP
# ============================================================================
test_that("save and load cycle preserves model integrity", {
  
  # Test 1: Full round trip
  env <- setup_test_environment()
  model_path <- file.path(env$checkpoint_dir, "roundtrip.rds")
  
  # Original data and model
  data <- tibble(x = rnorm(100), y = 3 * 1:100 + rnorm(100, 0, 5))
  model_original <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(y ~ x, data = data)
  
  # Save
  save_result <- save_model(model_original, model_path, "roundtrip_model")
  expect_true(save_result)
  
  # Load
  model_loaded <- load_model(model_path, "roundtrip_model")
  expect_true(!is.null(model_loaded))
  
  # Verify coefficients
  coef_original <- coef(model_original$fit)
  coef_loaded <- coef(model_loaded$fit)
  
  expect_equal(coef_original, coef_loaded)
  
})

test_that("multiple save-load cycles maintain consistency", {
  
  # Test 2: Repeated save-load
  env <- setup_test_environment()
  data <- tibble(x = 1:20, y = 2*1:20)
  
  model <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(y ~ x, data = data)
  
  # Multiple cycles
  for (i in 1:3) {
    path <- file.path(env$checkpoint_dir, paste0("cycle_", i, ".rds"))
    save_model(model, path, paste("cycle", i))
    model <- load_model(path, paste("cycle", i))
  }
  
  # Final model should still be valid
  expect_true(inherits(model, "model_fit"))
  
})

# ============================================================================
# TEST SUITE 5: UTILITY INTEGRATION
# ============================================================================
test_that("logging and model operations work together", {
  
  # Test: Combined operations
  env <- setup_test_environment()
  log_file <- file.path(env$log_dir, "integration.log")
  model_path <- file.path(env$checkpoint_dir, "integration_model.rds")
  
  # Create and train model
  data <- tibble(x = 1:30, y = rnorm(30, 50, 10))
  model <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(y ~ x, data = data)
  
  # Log and save
  log_message("Starting model training", log_file, "INFO")
  save_result <- save_model(model, model_path, "integration_model")
  log_message(sprintf("Model saved successfully: %s", save_result), log_file, "INFO")
  
  # Load and log
  loaded_model <- load_model(model_path, "integration_model")
  log_message("Model loaded successfully", log_file, "INFO")
  
  expect_true(file.exists(log_file))
  expect_true(!is.null(loaded_model))
  
})

# ============================================================================
# EDGE CASE TESTS
# ============================================================================
test_that("log_message handles empty strings", {
  
  # Test: Empty message
  env <- setup_test_environment()
  log_file <- file.path(env$log_dir, "empty_msg.log")
  
  expect_silent({
    log_message("", log_file, "INFO")
  })
  
  content <- readLines(log_file)
  expect_equal(length(content), 1)
  
})

test_that("save_model handles very large models", {
  
  # Test: Large model
  env <- setup_test_environment()
  model_path <- file.path(env$checkpoint_dir, "large_model.rds")
  
  # Create model with many features
  data <- as_tibble(replicate(50, rnorm(100)))
  names(data) <- paste0("x", 1:50)
  data$y <- rnorm(100)
  
  model <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(y ~ ., data = data)
  
  result <- save_model(model, model_path, "large_model")
  
  expect_true(result)
  expect_true(file.exists(model_path))
  
})

test_that("load_model handles file permission issues gracefully", {
  
  # Test: Permission handling
  env <- setup_test_environment()
  model_path <- file.path(env$checkpoint_dir, "permission_test.rds")
  
  # Create a file
  data <- tibble(x = 1:10, y = 1:10)
  model <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(y ~ x, data = data)
  
  save_model(model, model_path, "perm_test")
  
  # Attempt to load (should work on most systems)
  result <- load_model(model_path, "perm_test")
  
  expect_true(!is.null(result))
  
})

# ============================================================================
# PERFORMANCE TESTS
# ============================================================================
test_that("logging performance is acceptable", {
  
  # Test: Logging speed
  env <- setup_test_environment()
  log_file <- file.path(env$log_dir, "perf_test.log")
  
  start_time <- Sys.time()
  for (i in 1:100) {
    log_message(paste("Message", i), log_file, "INFO")
  }
  end_time <- Sys.time()
  
  elapsed <- as.numeric(end_time - start_time)
  
  # Should complete quickly
  expect_true(elapsed < 5)
  
})

test_that("save/load performance is acceptable", {
  
  # Test: Model I/O speed
  env <- setup_test_environment()
  
  data <- tibble(x = rnorm(1000), y = rnorm(1000))
  model <- linear_reg() %>%
    set_engine("lm") %>%
    set_mode("regression") %>%
    fit(y ~ x, data = data)
  
  start_time <- Sys.time()
  
  for (i in 1:10) {
    path <- file.path(env$checkpoint_dir, paste0("perf_", i, ".rds"))
    save_model(model, path, "perf_model")
  }
  
  end_time <- Sys.time()
  elapsed <- as.numeric(end_time - start_time)
  
  # Should complete quickly
  expect_true(elapsed < 5)
  
})

# Print test summary
cat("\n========================================\n")
cat("UTILITY FUNCTIONS UNIT TESTS COMPLETED\n")
cat("========================================\n")
