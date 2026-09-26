library(tidymodels)
source("utils.R")

evaluate_model <- function(model, test_data, model_name = "Model", dest_path= "logs",
                           log_file_name = "model_evaluation.log") {
  
  log_message("-----------------------------------", dest_path, log_file_name)
  log_message(paste("Starting evaluation:", model_name), dest_path, log_file_name)
  log_message("Generating predictions...", dest_path, log_file_name)
  
  predictions <- predict(model, new_data = test_data) %>% bind_cols(test_data %>% select(RENTED_BIKE_COUNT))
  
  log_message("Calculating R-squared...", dest_path, log_file_name)
  
  rsq_value <- rsq(predictions, truth = RENTED_BIKE_COUNT, estimate = .pred) %>% pull(.estimate)
  
  log_message("Calculating RMSE...", dest_path, log_file_name)
  
  rmse_value <- rmse(predictions, truth = RENTED_BIKE_COUNT, estimate = .pred) %>% pull(.estimate)
  
  log_message("Calculating MAE...", dest_path, log_file_name)
  
  mae_value <- mae(predictions, truth = RENTED_BIKE_COUNT, estimate = .pred) %>% pull(.estimate)
  
  log_message("Calculating MAPE...", dest_path, log_file_name)
  
  mape_value <- mape(predictions, truth = RENTED_BIKE_COUNT, estimate = .pred) %>% pull(.estimate)
  
  log_message(paste("Completed evaluation:", model_name), dest_path, log_file_name)
  
  # Return results
  tibble(Model = model_name, RSQ = rsq_value, RMSE = rmse_value, MAE = mae_value, MAPE = mape_value)
}

