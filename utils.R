# Logging function
log_message <- function(message, dest_path, log_file_name, append_bool = TRUE) {
    cat(message, "\n\n", file = file.path(dest_path, log_file_name), append = append_bool)
}

# Save model weigths
save_model <- function(model, dest_path) {
  saveRDS(model, dest_path)
}

# Load model weights
load_model <- function(source_path) {
  readRDS(source_path)
}