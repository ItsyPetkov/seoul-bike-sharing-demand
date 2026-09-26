library("tidymodels")
library("tidyverse")
library("stringr")

# Building a linear regression model using only weather variables
fit_lm_model_weather <- function(train_data){
    lm_model_weather <- linear_reg() %>% 
    set_engine("lm") %>% set_mode("regression") %>%
    fit(
      RENTED_BIKE_COUNT ~ TEMPERATURE + HUMIDITY + WIND_SPEED + 
        VISIBILITY + DEW_POINT_TEMPERATURE + SOLAR_RADIATION + 
        RAINFALL,
      data = train_data)

    return(lm_model_weather)
}

# Building a linear regression model using only weather variables and polynomial terms.
fit_lm_model_weather_poly <- function(train_data){
    lm_model_weather_poly <- linear_reg() %>% 
    set_engine("lm") %>% set_mode("regression") %>%
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

    return(lm_model_weather_poly)
}

# Building a linear regression model using only weather variables and engineered terms
fit_lm_model_weather_interactions <- function(train_data){
    lm_model_weather_poly_interaction <- linear_reg() %>% 
    set_engine("lm") %>% set_mode("regression") %>% 
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
        data = train_data)

    return(lm_model_weather_poly_interaction)
}

# Building a linear regression model using all variables
fit_lm_model_all <- function(train_data) {
    lm_model_all <- linear_reg() %>% 
    set_engine("lm") %>% set_mode("regression") %>% 
    fit(RENTED_BIKE_COUNT ~ ., data = train_data)
    return(lm_model_all)
}

# Building a linear regression model using all variables and polynomial terms.
fit_lm_model_all_poly <- function(train_data) {
    lm_model_all_poly <- linear_reg() %>% 
    set_engine("lm") %>% set_mode("regression") %>%
    fit(
      RENTED_BIKE_COUNT ~ . -
          TEMPERATURE - HUMIDITY +
          poly(TEMPERATURE, 2, raw = TRUE) +
          poly(HUMIDITY, 2, raw = TRUE),
      data = train_data)

  return(lm_model_all_poly)
}

# Building a linear regression model using all variables and additional interaction terms
fit_lm_model_all_poly_interactions <- function(train_data) {
    lm_model_all_poly_interaction <- linear_reg() %>% 
    set_engine("lm") %>% set_mode("regression") %>%
    fit(
      RENTED_BIKE_COUNT ~ . -
          TEMPERATURE - HUMIDITY +
          poly(TEMPERATURE, 2, raw = TRUE) +
          poly(HUMIDITY, 2, raw = TRUE) +
          TEMPERATURE:HUMIDITY +
          RAINFALL:HUMIDITY +
            EMPERATURE:RAINFALL,
      data = train_data)

    return(lm_model_all_poly_interaction)
}

# XGBoost using weather variables
fit_xgb_model_weather <- function(train_data) {
  xgb_model_weather <- boost_tree(mode = "regression") %>% set_engine("xgboost")
  xgb_model_weather <- xgb_model_weather %>%
    fit(
      RENTED_BIKE_COUNT ~ TEMPERATURE + HUMIDITY + WIND_SPEED +
        VISIBILITY + DEW_POINT_TEMPERATURE + SOLAR_RADIATION +
        RAINFALL,
      data = train_data)

    return(xgb_model_weather)
}

# XGBoost using weather variables + polynomial terms
fit_xgb_model_weather_poly <- function(train_data) {
  
  train_data$TEMPERATURE <- train_data$TEMPERATURE^2
  train_data$HUMIDITY <- train_data$HUMIDITY^2
  
  xgb_model_weather_poly <- boost_tree(mode = "regression") %>% set_engine("xgboost")
  xgb_model_weather_poly <- xgb_model_weather_poly %>%
    fit(
      RENTED_BIKE_COUNT ~ TEMPERATURE + HUMIDITY + WIND_SPEED +
        VISIBILITY + DEW_POINT_TEMPERATURE + SOLAR_RADIATION +
        RAINFALL,
      data = train_data
    )

    return(xgb_model_weather_poly)
}

# XGBoost using weather variables + polynomial and intercation terms
fit_xgb_model_weather_poly_interactions <- function(train_data) {
  
  train_data$TEMPERATURE <- train_data$TEMPERATURE^2
  train_data$HUMIDITY <- train_data$HUMIDITY^2
  
  xgb_model_weather_poly_interaction <- boost_tree(mode = "regression") %>% set_engine("xgboost")
  xgb_model_weather_poly_interaction <- xgb_model_weather_poly_interaction %>%
    fit(
      RENTED_BIKE_COUNT ~ TEMPERATURE + HUMIDITY + WIND_SPEED +
        VISIBILITY + DEW_POINT_TEMPERATURE + SOLAR_RADIATION +
        RAINFALL + 
        TEMPERATURE_HUMIDITY + TEMPERATURE_SOLAR +
        TEMPERATURE_RAINFALL + DEW_POINT_SPREAD,
      data = train_data
    )

    return(xgb_model_weather_poly_interaction)
}

# XGBoost using all variables
fit_xgb_model_all <- function(train_data) {
  xgb_model_all <- boost_tree(mode = "regression") %>% set_engine("xgboost")
  xgb_model_all <- xgb_model_all %>% fit(RENTED_BIKE_COUNT ~ ., data = train_data)
  return(xgb_model_all)
}

# XGBoost using all variables + polynomial terms
fit_xgb_model_all_poly <- function(train_data) {
  
  train_data$TEMPERATURE <- train_data$TEMPERATURE^2
  train_data$HUMIDITY <- train_data$HUMIDITY^2
  
  xgb_model_all_poly <- boost_tree(mode = "regression") %>% set_engine("xgboost")
  xgb_model_all_poly <- xgb_model_all_poly %>% fit(RENTED_BIKE_COUNT ~ ., data = train_data)

  return(xgb_model_all_poly)
}

# XGBoost using all variables + polynomial + interaction terms
fit_xgb_model_all_poly_interactions <- function(train_data) {
  
  train_data$TEMPERATURE <- train_data$TEMPERATURE^2
  train_data$HUMIDITY <- train_data$HUMIDITY^2
  
  train_data$TEMP_HUMIDITY <- 
    train_data$TEMPERATURE * train_data$HUMIDITY
  
  train_data$RAINFALL_HUMIDITY <- 
    train_data$RAINFALL * train_data$HUMIDITY
  
  train_data$TEMP_RAINFALL <- 
    train_data$TEMPERATURE * train_data$RAINFALL
  
  xgb_model_all_poly_interaction <- boost_tree(mode = "regression") %>% set_engine("xgboost")
  xgb_model_all_poly_interaction <- xgb_model_all_poly_interaction %>% fit(RENTED_BIKE_COUNT ~ ., data = train_data)

  return(xgb_model_all_poly_interaction)
}