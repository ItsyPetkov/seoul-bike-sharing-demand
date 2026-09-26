# Master Test Runner
# File: run_all_tests.R
# Purpose: Execute all unit and integration tests with reporting

library(testthat)
library(tidyverse)

# ============================================================================
# CONFIGURATION
# ============================================================================
# Test file locations (adjust paths as needed)
TEST_DIR <- "."  # Current directory or specify path to test files
OUTPUT_DIR <- "./test_results"
TIMESTAMP <- format(Sys.time(), "%Y%m%d_%H%M%S")

# Create output directory
if (!dir.exists(OUTPUT_DIR)) {
  dir.create(OUTPUT_DIR, recursive = TRUE)
}

# ============================================================================
# TEST SUITE DEFINITIONS
# ============================================================================
test_suites <- list(
  list(
    name = "Preprocessing Functions",
    file = "test_preprocess.R",
    description = "Tests for data preprocessing and cleaning functions"
  ),
  list(
    name = "Feature Engineering",
    file = "test_features.R",
    description = "Tests for feature engineering and interaction terms"
  ),
  list(
    name = "Model Training",
    file = "test_train_model.R",
    description = "Tests for linear regression and XGBoost model training"
  ),
  list(
    name = "Model Evaluation",
    file = "test_evaluate_model.R",
    description = "Tests for performance metrics calculation and evaluation"
  ),
  list(
    name = "Utility Functions",
    file = "test_utils.R",
    description = "Tests for logging, saving, and loading utilities"
  ),
  list(
    name = "Integration Tests",
    file = "test_integration.R",
    description = "End-to-end pipeline integration tests"
  )
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

#' Print section header
#' @param title Title of section
print_header <- function(title) {
  cat("\n")
  cat(strrep("=", 80), "\n")
  cat(title, "\n")
  cat(strrep("=", 80), "\n")
}

#' Print subsection header
#' @param title Title of subsection
print_subheader <- function(title) {
  cat("\n")
  cat(strrep("-", 60), "\n")
  cat(title, "\n")
  cat(strrep("-", 60), "\n")
}

#' Run a single test file
#' @param test_file Path to test file
#' @param suite_name Name of test suite
#' @return Test results
run_test_file <- function(test_file, suite_name) {
  
  cat(sprintf("\n📋 Running: %s\n", suite_name))
  cat(sprintf("   File: %s\n", test_file))
  cat(sprintf("   Time: %s\n", format(Sys.time(), "%H:%M:%S")))
  
  tryCatch({
    # Run tests with reporter
    test_results <- test_file(
      test_file,
      reporter = SummaryReporter$new(),
      stop_on_failure = FALSE
    )
    
    return(test_results)
    
  }, error = function(e) {
    cat(sprintf("❌ ERROR in %s: %s\n", suite_name, e$message))
    return(NULL)
  })
}

#' Generate test report
#' @param results List of test results
#' @param output_file Path to output file
generate_report <- function(results, output_file) {
  
  report <- file(output_file, "w")
  
  writeLines(c(
    "=" %*% 80,
    "SEOUL BIKE-SHARING TEST REPORT",
    "=" %*% 80,
    "",
    paste("Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
    paste("System:", R.version$platform),
    paste("R Version:", R.version$version.string),
    "",
    "TEST SUITES EXECUTED",
    "-" %*% 80
  ), report)
  
  close(report)
}

# ============================================================================
# MAIN TEST EXECUTION
# ============================================================================

print_header("SEOUL BIKE-SHARING TEST SUITE")
cat("\n📊 Test Execution Summary\n")
cat(sprintf("   Total Suites: %d\n", length(test_suites)))
cat(sprintf("   Start Time: %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
cat(sprintf("   Output Directory: %s\n", OUTPUT_DIR))

# Track results
all_results <- list()
test_summary <- tibble(
  Suite = character(),
  File = character(),
  Status = character(),
  Timestamp = character()
)

# Run each test suite
for (suite in test_suites) {
  
  print_subheader(suite$name)
  cat(sprintf("Description: %s\n", suite$description))
  
  # Construct full path to test file
  test_file_path <- file.path(TEST_DIR, suite$file)
  
  # Check if file exists
  if (!file.exists(test_file_path)) {
    cat(sprintf("⚠️  WARNING: Test file not found: %s\n", test_file_path))
    
    test_summary <- add_row(test_summary,
      Suite = suite$name,
      File = suite$file,
      Status = "NOT FOUND",
      Timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    )
    
    next
  }
  
  # Run tests
  start_time <- Sys.time()
  
  tryCatch({
    # Source the test file
    source(test_file_path, local = TRUE)
    
    end_time <- Sys.time()
    elapsed <- as.numeric(end_time - start_time)
    
    cat(sprintf("✅ PASSED\n"))
    cat(sprintf("   Duration: %.2f seconds\n", elapsed))
    
    test_summary <- add_row(test_summary,
      Suite = suite$name,
      File = suite$file,
      Status = "PASSED",
      Timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    )
    
  }, error = function(e) {
    end_time <- Sys.time()
    elapsed <- as.numeric(end_time - start_time)
    
    cat(sprintf("❌ FAILED\n"))
    cat(sprintf("   Error: %s\n", e$message))
    cat(sprintf("   Duration: %.2f seconds\n", elapsed))
    
    test_summary <<- add_row(test_summary,
      Suite = suite$name,
      File = suite$file,
      Status = "FAILED",
      Timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    )
  })
}

# ============================================================================
# SUMMARY AND REPORTING
# ============================================================================

print_header("TEST EXECUTION SUMMARY")

# Print summary table
cat("\n📊 Test Results by Suite:\n\n")
print(test_summary)

# Statistics
total_suites <- nrow(test_summary)
passed_suites <- sum(test_summary$Status == "PASSED")
failed_suites <- sum(test_summary$Status == "FAILED")
not_found_suites <- sum(test_summary$Status == "NOT FOUND")

cat("\n📈 Statistics:\n")
cat(sprintf("   Total Suites: %d\n", total_suites))
cat(sprintf("   ✅ Passed: %d\n", passed_suites))
cat(sprintf("   ❌ Failed: %d\n", failed_suites))
cat(sprintf("   ⚠️  Not Found: %d\n", not_found_suites))

# Pass rate
if (total_suites > 0) {
  pass_rate <- (passed_suites / (total_suites - not_found_suites)) * 100
  cat(sprintf("   Pass Rate: %.1f%%\n", pass_rate))
}

# ============================================================================
# SAVE RESULTS
# ============================================================================

# Save summary to CSV
results_file <- file.path(OUTPUT_DIR, sprintf("test_results_%s.csv", TIMESTAMP))
write_csv(test_summary, results_file)
cat(sprintf("\n💾 Results saved to: %s\n", results_file))

# Create detailed report
report_file <- file.path(OUTPUT_DIR, sprintf("test_report_%s.txt", TIMESTAMP))
report_text <- sprintf(
  "SEOUL BIKE-SHARING PROJECT - TEST EXECUTION REPORT\n\n%s\n\nGenerated: %s\nSystem: %s\nR Version: %s\n\nTEST SUMMARY\n============\nTotal Test Suites: %d\nPassed: %d\nFailed: %d\nNot Found: %d\n\nDETAILS\n=======\n%s",
  strrep("=", 60),
  format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
  R.version$platform,
  R.version$version.string,
  total_suites,
  passed_suites,
  failed_suites,
  not_found_suites,
  paste(capture.output(print(test_summary)), collapse = "\n")
)

writeLines(report_text, report_file)
cat(sprintf("📄 Report saved to: %s\n", report_file))

# ============================================================================
# RECOMMENDATIONS
# ============================================================================

print_header("RECOMMENDATIONS")

if (failed_suites > 0) {
  cat("\n⚠️  FAILED SUITES DETECTED\n")
  failed_tests <- filter(test_summary, Status == "FAILED")
  cat("   Please review the following:\n")
  for (i in 1:nrow(failed_tests)) {
    cat(sprintf("   • %s (%s)\n", failed_tests$Suite[i], failed_tests$File[i]))
  }
  cat("\n   Actions:\n")
  cat("   1. Check test output for specific failures\n")
  cat("   2. Review source code for bugs\n")
  cat("   3. Run individual test files for debugging\n")
  cat("   4. Consult test documentation (test_documentation.R)\n")
}

if (not_found_suites > 0) {
  cat("\n⚠️  MISSING TEST FILES DETECTED\n")
  not_found_tests <- filter(test_summary, Status == "NOT FOUND")
  cat("   Please create the following test files:\n")
  for (i in 1:nrow(not_found_tests)) {
    cat(sprintf("   • %s\n", not_found_tests$File[i]))
  }
}

if (passed_suites == total_suites && not_found_suites == 0) {
  cat("\n✅ ALL TESTS PASSED!\n")
  cat("\n   Your codebase is in excellent shape.\n")
  cat("   Continue to maintain these tests as you develop new features.\n")
}

# ============================================================================
# FINAL SUMMARY
# ============================================================================

print_header("TEST EXECUTION COMPLETE")
cat(sprintf("\nEnd Time: %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
cat("\nFor detailed information, see:\n")
cat(sprintf("  • Results CSV: %s\n", results_file))
cat(sprintf("  • Full Report: %s\n", report_file))
cat(sprintf("  • Test Output Directory: %s\n", OUTPUT_DIR))

# Return results invisibly
invisible(test_summary)
