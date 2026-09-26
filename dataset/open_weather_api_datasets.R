library(httr)

get_weather_forecaset_by_cities <- function(url, api_key, path, name, city_names){

    # Initialize vectors
    city <- c()
    weather <- c()
    visibility <- c()
    temp <- c()
    temp_min <- c()
    temp_max <- c()
    pressure <- c()
    humidity <- c()
    wind_speed <- c()
    wind_deg <- c()
    forecast_datetime <- c()
    season <- c()

    # Initialize dataframe
    df <- data.frame()

    for (city_name in city_names){

        # Create query parameters
        forecast_query <- list(q = city_name, appid = api_key, units="metric")
        # Make HTTP GET call for the given city
        response <- GET(url, query=forecast_query)
        # Note that the 5-day forecast JSON result is a list of lists. 
        json_list <- content(response, as="parsed")
        results <- json_list$list
        
        # Loop the json result
        for(result in results) {
            city <- c(city, city_name)
            weather <- c(weather, result$weather[[1]]$main)
            visibility <- c(visibility, result$visibility)
            temp <- c(temp, result$main$temp)
            temp_min <- c(temp_min, result$main$temp_min)
            temp_max <- c(temp_max, result$main$temp_max)
            pressure <- c(pressure, result$main$pressure)
            humidity <- c(humidity, result$main$humidity)
            wind_speed <- c(wind_speed, result$wind$speed)
            wind_deg <- c(wind_deg, result$wind$deg)
            forecast_datetime <- c(forecast_datetime, result$dt)
            season <- c(season, ifelse(as.POSIXlt(as.POSIXct(result$dt, origin = "1970-01-01"))$mon + 1 %in% c(12, 1, 2), "Winter",
                    ifelse(as.POSIXlt(as.POSIXct(result$dt, origin = "1970-01-01"))$mon + 1 %in% c(3, 4, 5), "Spring",
                    ifelse(as.POSIXlt(as.POSIXct(result$dt, origin = "1970-01-01"))$mon + 1 %in% c(6, 7, 8), "Summer",
                    ifelse(as.POSIXlt(as.POSIXct(result$dt, origin = "1970-01-01"))$mon + 1 %in% c(9, 10, 11), "Autumn")))))
        }
        
        # Add the R Lists into a data frame
        df <- data.frame(city = city,
                            weather=weather, 
                            visibility=visibility, 
                            temp=temp, 
                            temp_min=temp_min, 
                            temp_max=temp_max, 
                            pressure=pressure, 
                            humidity=humidity, 
                            wind_speed=wind_speed, 
                            wind_deg=wind_deg,
                            forecast_datetime=forecast_datetime,
                            season = season)
    }
    
    # Export the dataframe to CSV
    write.csv(df, file.path(path, name), row.names=FALSE)
}

get_weather_forecaset_by_cities("https://api.openweathermap.org/data/2.5/forecast", "{your_api_key}", 
                                "../data_raw", "raw_cities_weather_forecast.csv", c("Seoul", "Washington, D.C.", "Paris", "Suzhou"))
