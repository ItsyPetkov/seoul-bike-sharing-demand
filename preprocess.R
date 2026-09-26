library(tidyverse)
library(fastDummies)

standardize_column_names <- function(dataset, dest_path, dataset_name){

  # Convert all columns names to uppercase
  names(dataset) <- toupper(names(dataset))

  # Replace any white space separators by underscore, using str_replace_all function
  names(dataset) <- str_replace_all(names(dataset), " ", "_")

  # Save the dataset back
  write.csv(dataset, file.path(dest_path, dataset_name), row.names=FALSE)
}

remove_refference_links_regex <- function(strings) {
    # Replace all matched substrings with a white space using str_replace_all()
    ref_pattern <- "\\[[^]]+\\]"
    strings <- str_replace_all(strings, ref_pattern, " ")

    # Trim the result string
    result <- trimws(strings, which = "both")
    
    return(result)
}

extract_numeric_data_regex <- function(columns){
    # Define a digital pattern for the first integer
    digitals_pattern <- "\\d+"
    
    # Find the first match using str_extract
    num <- str_extract(columns, digitals_pattern)
    
    # Convert the result to numeric using the as.numeric() function
    num <- as.numeric(num)

    return(num)
}

handle_missing_values <- function(dataset, column_name, style) {
  
  if (style == "drop") {
    # Drop rows with missing values
    clean_df <- dataset %>% drop_na(all_of(column_name))
    
  } else if (style == "fill_down") {
    # Fill missing values with the previous known value
    clean_df <- dataset %>% fill(all_of(column_name), .direction = "down")
    
  } else if (style == "fill_up") {
    # Fill missing values with the next known value
    clean_df <- dataset %>% fill(all_of(column_name), .direction = "up")
    
  } else {
    stop("Invalid style. Use 'drop', 'fill_down' or 'fill_up'.")
  }
  
  return(clean_df)
}

create_dummy_variables <- function(dataset, columns) {
    # Create dummy variables for multiple columns
    clean_df <- dummy_cols(dataset, select_columns = columns)
    return(clean_df)
}

normalize_data <- function(x) {
    # Perform min-max normalization on numeric data
    return((x - min(x)) / (max(x) - min(x)))
}

preporecessing_pipeline <- function(source_path, dest_path, dataset_list, normalized = FALSE){
  for (dataset_name in dataset_list){
    if (file.path(source_path, dataset_name) == "data_raw/raw_bike_sharing_systems.csv"){

      # Read dataset
      dataset <- read_csv(file.path(source_path, dataset_name))
      
      # Select the four relevant columns (COUNTRY, City, SYSTEM, BICYCLES)
      # The others are not relevant or containing too many missing values to fix or remove
      # 1) The irrelevant data will jeoperdize the prediction quality of machine learning models
      # 2) The relevant data containing a majority of missing values cannot be properly imputated
      # 2.1) This data cannot be removed either because droping rows will jeoperdize the data quality of the dataset
      # Thus these columns are just filtered out entirely
      sub_bike_sharing_df <- dataset %>% select(COUNTRY, City, SYSTEM, BICYCLES)
      
      # Using dplyr::mutate() to apply the remove_refference_links_regex function to the City and SYSTEM columns
      sub_bike_sharing_df <- sub_bike_sharing_df %>% mutate(City=remove_refference_links_regex(City), SYSTEM=remove_refference_links_regex(SYSTEM))

      # Using dplyr::mutate() to apply the extract_numeric_data_regex function to the BICYCLES column
      sub_bike_sharing_df <- sub_bike_sharing_df %>% mutate(BICYCLES=extract_numeric_data_regex(BICYCLES))

      # Standardized the columns of the final dataset and export it to CSV:
      standardize_column_names(sub_bike_sharing_df, dest_path, "processed_bike_sharing_systems.csv")

    } else if(file.path(source_path, dataset_name) == "data_raw/raw_seoul_bike_sharing.csv"){
      
      # Read dataset
      dataset <- read_csv(file.path(source_path, dataset_name))

      # Drop rows with `RENTED_BIKE_COUNT` column == NA
      clean_df <- dataset %>% handle_missing_values("RENTED_BIKE_COUNT", "drop")

      # Calculate the summer average temperature
      filtered_df <- dataset %>% filter(!is.na(TEMPERATURE) & SEASONS == "Summer")
      avg_temp <- mean(filtered_df$TEMPERATURE)

      # Impute missing values for TEMPERATURE column with summer average temperature
      clean_df <- clean_df %>% mutate(TEMPERATURE = replace_na(TEMPERATURE, round(avg_temp, 1)))

      # Using mutate() function to convert HOUR column into character type
      clean_df <- clean_df %>% mutate(Hour=as.character(Hour))

      # Convert SEASONS, HOLIDAY, and HOUR columns into indicator (dummy) columns.
      clean_df <- clean_df %>% create_dummy_variables(c("SEASONS", "HOLIDAY", "Hour"))

      if(normalized){
        # Using the `mutate()` function to apply min-max normalization on columns 
        # `RENTED_BIKE_COUNT`, `TEMPERATURE`, `HUMIDITY`, `WIND_SPEED`, `Visibility`, `DEW_POINT_TEMPERATURE`, `SOLAR_RADIATION`, `RAINFALL`, `Snowfall`
        clean_df <- clean_df %>% mutate(RENTED_BIKE_COUNT = normalize_data(RENTED_BIKE_COUNT),
                                 TEMPERATURE = normalize_data(TEMPERATURE),
                                 HUMIDITY = normalize_data(HUMIDITY),
                                 WIND_SPEED = normalize_data(WIND_SPEED),
                                 Visibility = normalize_data(Visibility),
                                 DEW_POINT_TEMPERATURE = normalize_data(DEW_POINT_TEMPERATURE),
                                 SOLAR_RADIATION = normalize_data(SOLAR_RADIATION),
                                 RAINFALL = normalize_data(RAINFALL),
                                 Snowfall = normalize_data(Snowfall))

        # Standardized the columns of the final dataset and export it to CSV:
        standardize_column_names(clean_df, dest_path, "processed_seoul_bike_sharing_normalized.csv")                      
      } else {
        # Standardized the columns of the final dataset and export it to CSV:
        standardize_column_names(clean_df, dest_path, "processed_seoul_bike_sharing.csv")
      }

    } else if(file.path(source_path, dataset_name) == "data_raw/raw_worldcities.csv"){

      # Read dataset
      dataset <- read_csv(file.path(source_path, dataset_name))

      # Standardized the columns of the final dataset and export it to CSV:
      standardize_column_names(dataset, dest_path, "processed_worldcities.csv")

    } else if(file.path(source_path, dataset_name) == "data_raw/raw_cities_weather_forecast.csv"){

      # Read dataset
      dataset <- read_csv(file.path(source_path, dataset_name))

      # Standardized the columns of the final dataset and export it to CSV:
      standardize_column_names(dataset, dest_path, "processed_cities_weather_forecast.csv")
      
    }
  }
}

preporecessing_pipeline(source_path="data_raw", dest_path="data_preprocessed", 
                        dataset_list=c("raw_bike_sharing_systems.csv", "raw_seoul_bike_sharing.csv", "raw_cities_weather_forecast.csv", "raw_worldcities.csv"))

preporecessing_pipeline(source_path="data_raw", dest_path="data_preprocessed", 
                        dataset_list=c("raw_bike_sharing_systems.csv", "raw_seoul_bike_sharing.csv", "raw_cities_weather_forecast.csv", "raw_worldcities.csv"),
                        normalized = TRUE)