library(dplyr)

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