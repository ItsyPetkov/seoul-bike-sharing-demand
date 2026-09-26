source("RSQLite_config.R")

con <- RSQlite_config("../data_preprocessed", 
                      c("processed_bike_sharing_systems.csv", "processed_seoul_bike_sharing.csv",
                        "processed_cities_weather_forecast.csv", "processed_worldcities.csv"))

eda_world_cities <- function(con){

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Count total cities\n")
  cat("--------------------------------------------------\n")

  # Count total cities.
  print(dbGetQuery(con, "SELECT COUNT(CITY) AS CITY_COUNT FROM PROCESSED_WORLDCITIES;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Count unique countries\n")
  cat("--------------------------------------------------\n")

  # Count unique countries.
  print(dbGetQuery(con, "SELECT COUNT(DISTINCT COUNTRY) AS UNIQUE_COUNTRY_COUNT FROM PROCESSED_WORLDCITIES;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Count unique ISO2 codes\n")
  cat("--------------------------------------------------\n")

  # Count unique ISO2 codes.
  print(dbGetQuery(con, "SELECT COUNT(DISTINCT ISO2) AS UNIQUE_ISO2_CODES_COUNT FROM PROCESSED_WORLDCITIES;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Count unique ISO3 codes\n")
  cat("--------------------------------------------------\n")

  # Count unique ISO3 codes.
  print(dbGetQuery(con, "SELECT COUNT(DISTINCT ISO3) AS UNIQUE_ISO3_CODES_COUNT FROM PROCESSED_WORLDCITIES;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Count missing population values\n")
  cat("--------------------------------------------------\n")

  # Count missing population values.
  print(dbGetQuery(con, "SELECT COUNT(CASE WHEN POPULATION IS NULL THEN 1 END) AS MISSING_POPULATION_VALUES_COUNT FROM PROCESSED_WORLDCITIES;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Count cities with population = 0\n")
  cat("--------------------------------------------------\n")

  # Count cities with population = 0.
  print(dbGetQuery(con, "SELECT COUNT(CITY) AS ZERO_POPULATION_CITIES_COUNT FROM PROCESSED_WORLDCITIES WHERE POPULATION = 0;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Check for duplicate CITY + COUNTRY combinations\n")
  cat("--------------------------------------------------\n")

  # Check for duplicate CITY + COUNTRY combinations.
  print(dbGetQuery(con, "SELECT CITY, COUNTRY, COUNT(*) AS DUPLICATE_COMBINATIONS_COUNT FROM PROCESSED_WORLDCITIES
                         GROUP BY CITY, COUNTRY
                         HAVING COUNT(*) > 1;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Find the largest 10 cities by population\n")
  cat("--------------------------------------------------\n")

  # Find the largest 10 cities by population.
  print(dbGetQuery(con, "SELECT CITY, SUM(POPULATION) AS LARGEST_POPULATION FROM PROCESSED_WORLDCITIES
                         GROUP BY CITY
                         ORDER BY LARGEST_POPULATION DESC
                         LIMIT 10"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Find the smallest 10 non-zero cities by population\n")
  cat("--------------------------------------------------\n")

  # Find the smallest 10 non-zero cities by population.
  print(dbGetQuery(con, "SELECT CITY, SUM(POPULATION) AS SMALLEST_POPULATION FROM PROCESSED_WORLDCITIES
                         WHERE POPULATION <> 0
                         GROUP BY CITY
                         ORDER BY SMALLEST_POPULATION 
                         LIMIT 10"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Calculate average population\n")
  cat("--------------------------------------------------\n")

  # Calculate average population.
  print(dbGetQuery(con, "SELECT AVG(POPULATION) AS AVERAGE_POPULATION FROM PROCESSED_WORLDCITIES;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Calculate median population\n")
  cat("--------------------------------------------------\n")

  # Calculate median population.
  print(dbGetQuery(con, "SELECT MEDIAN(POPULATION) AS MEDIAN_POPULATION FROM PROCESSED_WORLDCITIES;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Count cities with population above 100,000\n")
  cat("--------------------------------------------------\n")

  # Count cities with population above 100,000.
  print(dbGetQuery(con, "SELECT COUNT(CITY) AS CITIES_ABOVE_HUNDRED_THOUSAND FROM PROCESSED_WORLDCITIES WHERE POPULATION > 100000;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Count cities with population above 1 million\n")
  cat("--------------------------------------------------\n")

  # Count cities with population above 1 million.
  print(dbGetQuery(con, "SELECT COUNT(CITY) AS CITIES_ABOVE_ONE_MILLION FROM PROCESSED_WORLDCITIES WHERE POPULATION > 1000000;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Count cities with population above 5 million\n")
  cat("--------------------------------------------------\n")

  # Count cities with population above 5 million.
  print(dbGetQuery(con, "SELECT COUNT(CITY) AS CITIES_ABOVE_FIVE_MILLION FROM PROCESSED_WORLDCITIES WHERE POPULATION > 5000000;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Find the largest city in each country\n")
  cat("--------------------------------------------------\n")

  # Find the largest city in each country.
  print(dbGetQuery(con, "SELECT COUNTRY, CITY, POPULATION
                         FROM ( SELECT COUNTRY, CITY, POPULATION,
                                MAX(POPULATION) OVER (PARTITION BY COUNTRY) AS LARGEST_POPULATION
                                FROM PROCESSED_WORLDCITIES)
                         WHERE POPULATION = LARGEST_POPULATION;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Count cities per country\n")
  cat("--------------------------------------------------\n")

  # Count cities per country.
  print(dbGetQuery(con, "SELECT COUNTRY, COUNT(CITY) AS CITY_COUNT FROM PROCESSED_WORLDCITIES
                         GROUP BY COUNTRY;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Find the 20 countries with the most cities\n")
  cat("--------------------------------------------------\n")

  # Find the 20 countries with the most cities.
  print(dbGetQuery(con, "SELECT COUNTRY, COUNT(CITY) AS CITY_COUNT FROM PROCESSED_WORLDCITIES
                         GROUP BY COUNTRY
                         ORDER BY CITY_COUNT DESC
                         LIMIT 20;"))
                        
  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Calculate average city population by country\n")
  cat("--------------------------------------------------\n")

  # Calculate average city population by country.
  print(dbGetQuery(con, "SELECT COUNTRY, AVG(POPULATION) AS AVERAGE_CITY_POPULATION FROM PROCESSED_WORLDCITIES
                         GROUP BY COUNTRY;"))

  cat("\n")
  cat("----------------------------------------------------------------------\n")
  cat("Calculate total population represented by cities in each country\n")
  cat("----------------------------------------------------------------------\n")

  # Calculate total population represented by cities in each country.
  print(dbGetQuery(con, "SELECT COUNTRY, SUM(POPULATION) AS TOTAL_POPULATION FROM PROCESSED_WORLDCITIES
                         GROUP BY COUNTRY;"))

  cat("\n")
  cat("------------------------------------------------------------------\n")
  cat("Find countries whose largest city has the highest population\n")
  cat("------------------------------------------------------------------\n")

  # Find countries whose largest city has the highest population.
  print(dbGetQuery(con, "SELECT COUNTRY, CITY, POPULATION
                         FROM ( SELECT COUNTRY, CITY, POPULATION,
                         MAX(POPULATION) OVER (PARTITION BY COUNTRY) AS LARGEST_CITY_POPULATION
                         FROM PROCESSED_WORLDCITIES)
                         WHERE POPULATION = LARGEST_CITY_POPULATION
                         ORDER BY COUNTRY;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Find the northernmost city\n")
  cat("--------------------------------------------------\n")

  # Find the northernmost city.
  print(dbGetQuery(con, "SELECT COUNTRY, CITY, LAT, LNG FROM PROCESSED_WORLDCITIES
                         WHERE LAT = (SELECT MAX(LAT) FROM PROCESSED_WORLDCITIES);"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Find the southernmost city\n")
  cat("--------------------------------------------------\n")

  # Find the southernmost city.
  print(dbGetQuery(con, "SELECT COUNTRY, CITY, LAT, LNG FROM PROCESSED_WORLDCITIES
                         WHERE LAT = (SELECT MIN(LAT) FROM PROCESSED_WORLDCITIES);"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Find the easternmost city\n")
  cat("--------------------------------------------------\n")

  # Find the easternmost city.
  print(dbGetQuery(con, "SELECT COUNTRY, CITY, LAT, LNG FROM PROCESSED_WORLDCITIES
                         WHERE LNG = (SELECT MAX(LNG) FROM PROCESSED_WORLDCITIES);"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Find the westernmost city\n")
  cat("--------------------------------------------------\n")

  # Find the westernmost city.
  print(dbGetQuery(con, "SELECT COUNTRY, CITY, LAT, LNG FROM PROCESSED_WORLDCITIES
                         WHERE LNG = (SELECT MIN(LNG) FROM PROCESSED_WORLDCITIES);"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Count cities north/south of the equator\n")
  cat("--------------------------------------------------\n")

  # Count cities north/south of the equator.
  print(dbGetQuery(con, "SELECT (SELECT COUNT(CITY) FROM PROCESSED_WORLDCITIES WHERE LAT > 0) AS NORTH_EQUATOR_COUNT,
                         (SELECT COUNT(CITY) FROM PROCESSED_WORLDCITIES WHERE LAT < 0) AS SOUTH_EQUATOR_COUNT FROM PROCESSED_WORLDCITIES
                         LIMIT 1;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Find cities closest to the equator\n")
  cat("--------------------------------------------------\n")

  # Find cities closest to the equator.
  print(dbGetQuery(con, "SELECT COUNTRY, CITY, LAT, LNG FROM PROCESSED_WORLDCITIES
                         ORDER BY ABS(LAT)
                         LIMIT 10;"))

}

eda_cities_weather_forecast <- function(con){

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Count total records\n")
  cat("--------------------------------------------------\n")

  # Count total records.
  print(dbGetQuery(con, "SELECT COUNT(*) AS RECORD_COUNT FROM PROCESSED_CITIES_WEATHER_FORECAST;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Count unique cities\n")
  cat("--------------------------------------------------\n")

  # Count unique cities.
  print(dbGetQuery(con, "SELECT COUNT(DISTINCT CITY) AS UNIQUE_CITIES_COUNT FROM PROCESSED_CITIES_WEATHER_FORECAST;")) 

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Count unique weather conditions\n")
  cat("--------------------------------------------------\n")

  # Count unique weather conditions.
  print(dbGetQuery(con, "SELECT COUNT(DISTINCT WEATHER) AS UNIQUE_WATHER_CONDITION_COUNT FROM PROCESSED_CITIES_WEATHER_FORECAST;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Find the earliest and latest forecast datetime\n")
  cat("--------------------------------------------------\n")

  # Find the earliest and latest forecast datetime.
  print(dbGetQuery(con, "SELECT DATETIME(MIN(FORECAST_DATETIME), 'unixepoch') AS FIRST_DATE,
                         DATETIME(MAX(FORECAST_DATETIME), 'unixepoch') AS LAST_DATE
                         FROM PROCESSED_CITIES_WEATHER_FORECAST;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Find the warmest city\n")
  cat("--------------------------------------------------\n")

  # Find the warmest city.
  print(dbGetQuery(con, "SELECT CITY AS WARMEST_CITY, DATETIME(FORECAST_DATETIME, 'unixepoch') AS DATETIME, TEMP FROM PROCESSED_CITIES_WEATHER_FORECAST
                         ORDER BY TEMP DESC
                         LIMIT 1;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Find the coolest city\n")
  cat("--------------------------------------------------\n")

  # Find the coolest city.
  print(dbGetQuery(con, "SELECT CITY AS COOLEST_CITY, DATETIME(FORECAST_DATETIME, 'unixepoch') AS DATETIME, TEMP FROM PROCESSED_CITIES_WEATHER_FORECAST
                         ORDER BY TEMP
                         LIMIT 1;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Find city with largest temperature amplitude\n")
  cat("--------------------------------------------------\n")

  # Find city with largest temperature amplitude.
  print(dbGetQuery(con, "SELECT CITY, TEMP_MAX - TEMP_MIN AS AMPLITUDE FROM PROCESSED_CITIES_WEATHER_FORECAST
                         ORDER BY AMPLITUDE DESC
                         LIMIT 1;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Find the highest and lowest temperature\n")
  cat("--------------------------------------------------\n")

  # Find the highest and lowest temperature.
  print(dbGetQuery(con, "SELECT MAX(TEMP) AS MAXIMUM_TEMPERATURE, MIN(TEMP) AS MINIMUM_TEMPERATURE FROM PROCESSED_CITIES_WEATHER_FORECAST;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Calculate average temperature by city\n")
  cat("--------------------------------------------------\n")

  # Calculate average temperature by city.
  print(dbGetQuery(con, "SELECT CITY, AVG(TEMP) AS AVERAGE_TEMEPRATURE FROM PROCESSED_CITIES_WEATHER_FORECAST
                         GROUP BY CITY;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Find the most humid cities\n")
  cat("--------------------------------------------------\n")

  # Find the most humid cities.
  print(dbGetQuery(con, "SELECT CITY AS MOST_HUMID_CITIES, AVG(HUMIDITY) AS AVERAGE_HUMIDITY FROM PROCESSED_CITIES_WEATHER_FORECAST
                         GROUP BY CITY
                         ORDER BY AVERAGE_HUMIDITY DESC;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Find the least humid cities\n")
  cat("--------------------------------------------------\n")

  # Find the least humid cities.
  print(dbGetQuery(con, "SELECT CITY AS LEAST_HUMID_CITIES, AVG(HUMIDITY) AS AVERAGE_HUMIDITY FROM PROCESSED_CITIES_WEATHER_FORECAST
                         GROUP BY CITY
                         ORDER BY AVERAGE_HUMIDITY;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Find cities with the highest wind speeds\n")
  cat("--------------------------------------------------\n")

  # Find cities with the highest wind speeds.
  print(dbGetQuery(con, "SELECT CITY, AVG(WIND_SPEED) AS AVERAGE_WIND_SPEED FROM PROCESSED_CITIES_WEATHER_FORECAST
                         GROUP BY CITY
                         ORDER BY AVERAGE_WIND_SPEED DESC;"))

  cat("\n")
  cat("-----------------------------------------------------------------\n")
  cat("Calculate average pressure, humidity and wind speed by city\n")
  cat("-----------------------------------------------------------------\n")

  # Calculate average pressure, humidity and wind speed by city.
  print(dbGetQuery(con, "SELECT CITY, AVG(PRESSURE) AS AVERAGE_PRESSURE, AVG(HUMIDITY) AS AVERAGE_HUMIDITY, AVG(WIND_SPEED) AS AVERAGE_WIND_SPEED
                         FROM PROCESSED_CITIES_WEATHER_FORECAST
                         GROUP BY CITY;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Count each unique weather condition\n")
  cat("--------------------------------------------------\n")

  # Count each unique weather condition.
  print(dbGetQuery(con, "SELECT COUNT(DISTINCT WEATHER) AS UNIQUE_WEATHER_CONDITIONS FROM PROCESSED_CITIES_WEATHER_FORECAST;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Count weather conditions by city\n")
  cat("--------------------------------------------------\n")

  # Count weather conditions by city.
  print(dbGetQuery(con, "SELECT CITY, COUNT(WEATHER) AS WEATHER_CONDITIONS_COUNT FROM PROCESSED_CITIES_WEATHER_FORECAST
                         GROUP BY CITY;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Count weather conditions by season\n")
  cat("--------------------------------------------------\n")

  # Count weather conditions by season.
  print(dbGetQuery(con, "SELECT SEASON, COUNT(WEATHER) AS WEATHER_CONDITIONS_COUNT FROM PROCESSED_CITIES_WEATHER_FORECAST
                         GROUP BY SEASON;"))

  cat("\n")
  cat("----------------------------------------------------------\n")
  cat("Find the most common weather condition for each city\n")
  cat("----------------------------------------------------------\n")

  # Find the most common weather condition for each city.
  print(dbGetQuery(con, "SELECT CITY, WEATHER, WEATHER_CONDITION_COUNT
                         FROM (SELECT CITY, WEATHER, COUNT(*) AS WEATHER_CONDITION_COUNT,
                               DENSE_RANK() OVER (PARTITION BY CITY ORDER BY COUNT(*) DESC) AS RN
                               FROM PROCESSED_CITIES_WEATHER_FORECAST
                               GROUP BY CITY, WEATHER
                               )
                         WHERE RN = 1
                         ORDER BY WEATHER_CONDITION_COUNT DESC;"))

  cat("\n")
  cat("--------------------------------------------------------------------\n")
  cat("Query the the weather forecast for Seoul over the next 3 hours\n")
  cat("--------------------------------------------------------------------\n")

  # Query the the weather forecast for Seoul over the next 3 hours.
  print(dbGetQuery(con, "SELECT * FROM PROCESSED_CITIES_WEATHER_FORECAST WHERE CITY = 'Seoul' LIMIT 1;"))

}

eda_seoul_bike_sharing <- function(con){

  cat("\n")
  cat("----------------------------------------------------------------------\n")
  cat("Determine how many records are in the seoul_bike_sharing dataset\n")
  cat("----------------------------------------------------------------------\n")

  # Determine how many records are in the seoul_bike_sharing dataset.
  print(dbGetQuery(con, "SELECT COUNT(*) AS RECORD_COUNT FROM PROCESSED_SEOUL_BIKE_SHARING;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Count unique dates\n")
  cat("--------------------------------------------------\n")

  # Count unique dates.
  print(dbGetQuery(con, "SELECT COUNT(DISTINCT DATE) AS UNIQUE_DATE_COUNT FROM PROCESSED_SEOUL_BIKE_SHARING;"))

  cat("\n")
  cat("-------------------------------------------------------------\n")
  cat("Determine how many hours had non-zero rented bike count\n")
  cat("-------------------------------------------------------------\n")

  # Determine how many hours had non-zero rented bike count.
  print(dbGetQuery(con, "SELECT COUNT(HOUR) AS OPERATIONAL_HOURS FROM PROCESSED_SEOUL_BIKE_SHARING WHERE RENTED_BIKE_COUNT <> 0;"))

  cat("\n")
  cat("-----------------------------------------------------------------------\n")
  cat("Find which seasons are included in the seoul bike sharing dataset\n")
  cat("-----------------------------------------------------------------------\n")

  # Find which seasons are included in the seoul bike sharing dataset.
  print(dbGetQuery(con, "SELECT DISTINCT SEASONS FROM PROCESSED_SEOUL_BIKE_SHARING;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Count observations per season\n")
  cat("--------------------------------------------------\n")

  # Count observations per season.
  print(dbGetQuery(con, "SELECT SEASONS, COUNT(*) FROM PROCESSED_SEOUL_BIKE_SHARING GROUP BY SEASONS;"))

  cat("\n")
  cat("------------------------------------------------------------------------\n")
  cat("Calculate average, median, maximum, and minimum rentals per season\n")
  cat("------------------------------------------------------------------------\n")

  # Calculate average, median, maximum, and minimum rentals per season.
  print(dbGetQuery(con, "SELECT SEASONS, AVG(RENTED_BIKE_COUNT) AS AVERAGE_RENTALS, MEDIAN(RENTED_BIKE_COUNT) AS MEDIAN_RENTALS,
                         MAX(RENTED_BIKE_COUNT) AS MAXIMUM_RENTALS, MIN(RENTED_BIKE_COUNT) AS MINIMUM_RENTALS
                         FROM PROCESSED_SEOUL_BIKE_SHARING
                         GROUP BY SEASONS"))

  cat("\n")
  cat("------------------------------------------------------------------------\n")
  cat("Find the first and last dates in the Seoul Bike Sharing dataset\n")
  cat("------------------------------------------------------------------------\n")

  # Find the first and last dates in the Seoul Bike Sharing dataset.
  print(dbGetQuery(con, "SELECT MIN(date(substr(DATE, 7, 4) || '-' || substr(DATE, 4, 2) || '-' || substr(DATE, 1, 2))) AS FIRST_DATE,
                         MAX(date(substr(DATE, 7, 4) || '-' || substr(DATE, 4, 2) || '-' || substr(DATE, 1, 2))) AS LAST_DATE
                         FROM PROCESSED_SEOUL_BIKE_SHARING;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Find the average rented bike count\n")
  cat("--------------------------------------------------\n")

  # Find the average rented bike count.
  print(dbGetQuery(con, "SELECT AVG(RENTED_BIKE_COUNT) AS AVERAGE_RENTED_BIKE_COUNT FROM PROCESSED_SEOUL_BIKE_SHARING;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Find the minimum and maximum rental count\n")
  cat("--------------------------------------------------\n")

  # Find the minimum and maximum rental count.
  print(dbGetQuery(con, "SELECT MIN(RENTED_BIKE_COUNT) AS MINIMUM_RENTAL_COUNT, MAX(RENTED_BIKE_COUNT) AS MAXIMUM_RENTAL_COUNT FROM PROCESSED_SEOUL_BIKE_SHARING;"))

  cat("\n")
  cat("-------------------------------------------------------------\n")
  cat("Determine which date and hour had the most bike rentals\n")
  cat("-------------------------------------------------------------\n")

  # Determine which date and hour had the most bike rentals.
  print(dbGetQuery(con, "SELECT DATE, HOUR, RENTED_BIKE_COUNT AS MAX_RENTED_BIKE_COUNT FROM PROCESSED_SEOUL_BIKE_SHARING
                         WHERE RENTED_BIKE_COUNT = (SELECT MAX(RENTED_BIKE_COUNT) AS MAX_BIKE_COUNT FROM PROCESSED_SEOUL_BIKE_SHARING);"))

  cat("\n")
  cat("--------------------------------------------------------------\n")
  cat("Determine which date and hour had the least bike rentals\n")
  cat("--------------------------------------------------------------\n")

  # Determine which date and hour had the least bike rentals.
  print(dbGetQuery(con, "SELECT DATE, HOUR, RENTED_BIKE_COUNT AS MIN_RENTED_BIKE_COUNT FROM PROCESSED_SEOUL_BIKE_SHARING
                         WHERE RENTED_BIKE_COUNT = (SELECT MIN(RENTED_BIKE_COUNT) AS MIN_BIKE_COUNT FROM PROCESSED_SEOUL_BIKE_SHARING);"))

  cat("\n")
  cat("----------------------------------------------------------------------\n")
  cat("Calculate average, median and maximum bike rentals for each hour\n")
  cat("----------------------------------------------------------------------\n")

  # Calculate average, median and maximum bike rentals for each hour.
  print(dbGetQuery(con, "SELECT HOUR, AVG(RENTED_BIKE_COUNT) AS AVERAGE_BIKE_RENTALS, 
                         MEDIAN(RENTED_BIKE_COUNT) AS MEDIAN_BIKE_RENTALS,
                         MAX(RENTED_BIKE_COUNT) AS MAX_BIKE_COUNT FROM PROCESSED_SEOUL_BIKE_SHARING
                         GROUP BY HOUR;"))

  cat("\n")
  cat("---------------------------------------------------------\n")
  cat("Find the five busiest hours based on average demand\n")
  cat("---------------------------------------------------------\n")

  # Find the five busiest hours based on average demand.
  print(dbGetQuery(con, "SELECT HOUR, AVG(RENTED_BIKE_COUNT) AS AVERAGE_DEMAND FROM PROCESSED_SEOUL_BIKE_SHARING
                         GROUP BY HOUR
                         ORDER BY AVERAGE_DEMAND DESC
                         LIMIT 5;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Find the five quietest hours\n")
  cat("--------------------------------------------------\n")

  # Find the five quietest hours.
  print(dbGetQuery(con, "SELECT HOUR, AVG(RENTED_BIKE_COUNT) AS AVERAGE_DEMAND FROM PROCESSED_SEOUL_BIKE_SHARING
                         GROUP BY HOUR
                         ORDER BY AVERAGE_DEMAND 
                         LIMIT 5;"))

  cat("\n")
  cat("---------------------------------------------------------\n")
  cat("Compare total rentals between daytime and nighttime\n")
  cat("---------------------------------------------------------\n")

  # Compare total rentals between daytime and nighttime.
  print(dbGetQuery(con, "SELECT SUM(CASE WHEN TIME_OF_DAY = 'Daytime' THEN RENTED_BIKE_COUNT END) AS TOTAL_DAYTIME_RENTALS,
                         SUM(CASE WHEN TIME_OF_DAY = 'Nighttime' THEN RENTED_BIKE_COUNT END) AS TOTAL_NIGHTTIME_RENTALS
                         FROM (SELECT *, CASE WHEN HOUR BETWEEN 6 AND 17 THEN 'Daytime' ELSE 'Nighttime' END AS TIME_OF_DAY FROM PROCESSED_SEOUL_BIKE_SHARING);"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Find the hour with the highest average demand\n")
  cat("--------------------------------------------------\n")

  # Find the hour with the highest average demand.
  print(dbGetQuery(con, "SELECT MAX(AVERAGE_DEMAND_PER_HOUR) AS HIGHEST_AVERAGE_DEMAND FROM 
                         (SELECT *, AVG(RENTED_BIKE_COUNT) OVER(PARTITION BY HOUR) AS AVERAGE_DEMAND_PER_HOUR FROM PROCESSED_SEOUL_BIKE_SHARING);"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Calculate average and total rentals by month\n")
  cat("--------------------------------------------------\n")

  # Calculate average and total rentals by month.
  print(dbGetQuery(con, "SELECT substr(DATE, 4, 2) AS MONTH, AVG(RENTED_BIKE_COUNT) AS AVG_RENTALS, SUM(RENTED_BIKE_COUNT) AS TOTAL_RENTALS 
                         FROM PROCESSED_SEOUL_BIKE_SHARING
                         GROUP BY MONTH
                         ORDER BY MONTH;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Find the busiest month\n")
  cat("--------------------------------------------------\n")

  # Find the busiest month.
  print(dbGetQuery(con, "SELECT substr(DATE, 4, 2) AS MONTH, SUM(RENTED_BIKE_COUNT) AS TOTAL_RENTALS FROM PROCESSED_SEOUL_BIKE_SHARING
                         GROUP BY MONTH
                         ORDER BY TOTAL_RENTALS DESC
                         LIMIT 1;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Find the quietest month\n")
  cat("--------------------------------------------------\n")
  
  # Find the quietest month.
  print(dbGetQuery(con, "SELECT substr(DATE, 4, 2) AS MONTH, SUM(RENTED_BIKE_COUNT) AS TOTAL_RENTALS FROM PROCESSED_SEOUL_BIKE_SHARING
                         GROUP BY MONTH
                         ORDER BY TOTAL_RENTALS 
                         LIMIT 1;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Calculate average rentals by year/month\n")
  cat("--------------------------------------------------\n")

  # Calculate average rentals by year/month.
  print(dbGetQuery(con, "SELECT substr(DATE, 7, 4) AS YEAR, substr(DATE, 4, 2) AS MONTH, AVG(RENTED_BIKE_COUNT) AS AVERAGE_RENTED_BIKE_COUNT
                         FROM PROCESSED_SEOUL_BIKE_SHARING
                         GROUP BY YEAR, MONTH;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Find the busiest and quietest individual date\n")
  cat("--------------------------------------------------\n")

  # Find the busiest and quietest individual date.
  print(dbGetQuery(con, "SELECT DATE, RENTED_BIKE_COUNT FROM PROCESSED_SEOUL_BIKE_SHARING
                         WHERE RENTED_BIKE_COUNT = (SELECT MAX(RENTED_BIKE_COUNT) AS MAX_BIKE_COUNT FROM PROCESSED_SEOUL_BIKE_SHARING LIMIT 1)
                         GROUP BY DATE
                         UNION
                         SELECT DATE, RENTED_BIKE_COUNT FROM PROCESSED_SEOUL_BIKE_SHARING
                         WHERE RENTED_BIKE_COUNT = (SELECT MIN(RENTED_BIKE_COUNT) AS MIN_BIKE_COUNT FROM PROCESSED_SEOUL_BIKE_SHARING LIMIT 1)
                         GROUP BY DATE
                         ORDER BY RENTED_BIKE_COUNT;"))

  cat("\n")
  cat("---------------------------------------------------------------------------------------------------------------\n")
  cat("Determine the average hourly temperature and the average number of bike rentals per hour over each season\n")
  cat("---------------------------------------------------------------------------------------------------------------\n")
  cat(" List the top ten results by average bike count\n")
  cat("---------------------------------------------------------------------------------------------------------------\n")

  # Determine the average hourly temperature and the average number of bike rentals per hour over each season. List the top ten results by average bike count.
  print(dbGetQuery(con, "SELECT SEASONS, HOUR, AVG(TEMPERATURE) AS AVG_TEMPERATURE, AVG(RENTED_BIKE_COUNT) AS AVG_RENTED_BIKE_COUNT FROM PROCESSED_SEOUL_BIKE_SHARING
                         GROUP BY SEASONS, HOUR
                         ORDER BY AVG_RENTED_BIKE_COUNT DESC
                         LIMIT 10;"))

  cat("\n")
  cat("---------------------------------------------------------------------------------------------------------------------------------------------------------------\n")
  cat("Find the average hourly bike count during each season. Also include the minimum, maximum, and standard deviation of the hourly bike count for each season\n")
  cat("---------------------------------------------------------------------------------------------------------------------------------------------------------------\n")

  # Find the average hourly bike count during each season. Also include the minimum, maximum, and standard deviation of the hourly bike count for each season. 
  print(dbGetQuery(con, "SELECT SEASONS, HOUR, AVG(RENTED_BIKE_COUNT) AS AVG_RENTED_BIKE_COUNT, MIN(RENTED_BIKE_COUNT) AS MIN_RENTED_BIKE_COUNT,
                         MAX(RENTED_BIKE_COUNT) AS MAX_RENTED_BIKE_COUNT, SQRT(AVG(RENTED_BIKE_COUNT*RENTED_BIKE_COUNT) - AVG(RENTED_BIKE_COUNT)*AVG(RENTED_BIKE_COUNT)) AS STD_RENTED_BIKE_COUNT
                         FROM PROCESSED_SEOUL_BIKE_SHARING
                         GROUP BY SEASONS, HOUR;"))

  cat("\n")
  cat("--------------------------------------------------------------------------------------------------------------------------------------------------------\n")
  cat("On average, what were the TEMPERATURE, HUMIDITY, WIND_SPEED, VISIBILITY, DEW_POINT_TEMPERATURE, SOLAR_RADIATION, RAINFALL, and SNOWFALL per season\n")
  cat("--------------------------------------------------------------------------------------------------------------------------------------------------------\n")

  # On average, what were the TEMPERATURE, HUMIDITY, WIND_SPEED, VISIBILITY, DEW_POINT_TEMPERATURE, SOLAR_RADIATION, RAINFALL, and SNOWFALL per season?
  print(dbGetQuery(con, " SELECT SEASONS, AVG(TEMPERATURE) AS AVG_TEMPERATURE, AVG(HUMIDITY) AS AVG_HUMIDITY, AVG(WIND_SPEED) AS AVG_WIND_SPEED, AVG(VISIBILITY) AS AVG_VISIBILITY,
                          AVG(DEW_POINT_TEMPERATURE) AS AVG_DEW_POINT_TEMPERATURE, AVG(SOLAR_RADIATION) AS AVG_SOLAR_RADIATION, AVG(RAINFALL) AS AVG_RAINFALL,
                          AVG(SNOWFALL) AS AVG_SNOWFALL, AVG(RENTED_BIKE_COUNT) AS AVG_RENTED_BIKE_COUNT FROM PROCESSED_SEOUL_BIKE_SHARING
                          GROUP BY SEASONS
                          ORDER BY AVG_RENTED_BIKE_COUNT DESC;"))

  cat("\n")
  cat("--------------------------------------------------------------------\n")
  cat("Find the busiest hour and the quietest hour within each season\n")
  cat("--------------------------------------------------------------------\n")

  # Find the busiest hour and the quietest hour within each season.
  print(dbGetQuery(con, "SELECT SEASONS, HOUR, RENTED_BIKE_COUNT FROM PROCESSED_SEOUL_BIKE_SHARING
                         WHERE RENTED_BIKE_COUNT = (SELECT MAX(RENTED_BIKE_COUNT) AS MAX_BIKE_COUNT FROM PROCESSED_SEOUL_BIKE_SHARING)
                         UNION
                         SELECT SEASONS, HOUR, RENTED_BIKE_COUNT FROM PROCESSED_SEOUL_BIKE_SHARING
                         WHERE RENTED_BIKE_COUNT = (SELECT MIN(RENTED_BIKE_COUNT) AS MIN_BIKE_COUNT FROM PROCESSED_SEOUL_BIKE_SHARING);"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Count holidays vs non-holidays\n")
  cat("--------------------------------------------------\n")

  # Count holidays vs non-holidays.
  print(dbGetQuery(con, "SELECT COUNT(CASE WHEN HOLIDAY = 'Holiday' THEN 1 END) AS HOLIDAY_COUNT, 
                         COUNT(CASE WHEN HOLIDAY = 'No Holiday' THEN 1 END) AS NO_HOLIDAY_COUNT 
                         FROM PROCESSED_SEOUL_BIKE_SHARING;"))

  cat("\n")
  cat("------------------------------------------------------------\n")
  cat("Calculate average rentals on holidays and non-holidays\n")
  cat("------------------------------------------------------------\n")

  # Calculate average rentals on holidays and non-holidays.
  print(dbGetQuery(con, "SELECT AVG(CASE WHEN HOLIDAY = 'Holiday' THEN RENTED_BIKE_COUNT END) AS AVERAGE_HOLIDAY_RENTALS,
                         AVG(CASE WHEN HOLIDAY = 'No Holiday' THEN RENTED_BIKE_COUNT END) AS AVERAGE_NON_HOLIDAY_RENTALS
                         FROM PROCESSED_SEOUL_BIKE_SHARING;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Find the maximum rental count on holidays\n")
  cat("--------------------------------------------------\n")

  # Find the maximum rental count on holidays.
  print(dbGetQuery(con, "SELECT MAX(CASE WHEN HOLIDAY = 'Holiday' THEN RENTED_BIKE_COUNT END) AS MAXIMUM_RENTAL_COUNT FROM PROCESSED_SEOUL_BIKE_SHARING;"))

  cat("\n")
  cat("--------------------------------------------------------\n")
  cat("Find the busiest hour on holidays and non-holidays\n")
  cat("--------------------------------------------------------\n")

  # Find the busiest hour on holidays and non-holidays.
  print(dbGetQuery(con, "SELECT HOUR, RENTED_BIKE_COUNT FROM PROCESSED_SEOUL_BIKE_SHARING
                         WHERE RENTED_BIKE_COUNT = (SELECT MAX(CASE WHEN HOLIDAY = 'Holiday' THEN RENTED_BIKE_COUNT END) AS MAX_RENTAL_BIKE_DEMAND FROM PROCESSED_SEOUL_BIKE_SHARING)
                         GROUP BY HOUR
                         UNION
                         SELECT HOUR, RENTED_BIKE_COUNT FROM PROCESSED_SEOUL_BIKE_SHARING
                         WHERE RENTED_BIKE_COUNT = (SELECT MAX(CASE WHEN HOLIDAY = 'No Holiday' THEN RENTED_BIKE_COUNT END) AS MAX_RENTAL_BIKE_DEMAND FROM PROCESSED_SEOUL_BIKE_SHARING)
                         GROUP BY HOUR;"))

  cat("\n")
  cat("-----------------------------------------------------------------------\n")
  cat("Compare average rental demand between temperature ranges\n")
  cat("-----------------------------------------------------------------------\n")
  cat("Find the highest rental count under different temperature ranges\n")
  cat("-----------------------------------------------------------------------\n")

  # Compare average rental demand between temperature ranges.
  # Find the highest rental count under different temperature ranges.
  print(dbGetQuery(con, "SELECT CASE
                                  WHEN TEMPERATURE < 0 THEN '< 0°C'
                                  WHEN TEMPERATURE < 10 THEN '0–10°C'
                                  WHEN TEMPERATURE < 20 THEN '10–20°C'
                                  WHEN TEMPERATURE < 30 THEN '20–30°C'
                                  ELSE '30°C+'
                                END AS TEMP_GROUP,
                        COUNT(*) AS RECORDS, AVG(RENTED_BIKE_COUNT) AS AVERAGE_RENTAL_DEMAND,
                        MAX(RENTED_BIKE_COUNT) AS MAXIMUM_RENTAL_DEMAND
                        FROM PROCESSED_SEOUL_BIKE_SHARING
                        GROUP BY TEMP_GROUP
                        ORDER BY AVERAGE_RENTAL_DEMAND DESC, MAXIMUM_RENTAL_DEMAND DESC;"))

  cat("\n")
  cat("-----------------------------------------------------------------------\n")
  cat("Compare average rental demand between rainfall ranges\n")
  cat("-----------------------------------------------------------------------\n")
  cat("Find the highest rental count under different rainfall ranges\n")
  cat("-----------------------------------------------------------------------\n")

  # Compare average rental demand between rainfall ranges.
  # Find the highest rental count under different rainfall ranges.
  print(dbGetQuery(con, "SELECT CASE
                                  WHEN RAINFALL = 0 THEN 'No rain'
                                  WHEN RAINFALL <= 1 THEN '>0–1 mm'
                                  WHEN RAINFALL <= 5 THEN '>1–5 mm'
                                  ELSE '>5 mm'
                                END AS RAIN_GROUP,
                         COUNT(*) AS RECORDS,
                         AVG(RENTED_BIKE_COUNT) AS AVERAGE_RENTAL_DEMAND,
                         MAX(RENTED_BIKE_COUNT) AS MAXIMUM_RENTAL_DEMAND
                         FROM PROCESSED_SEOUL_BIKE_SHARING
                         GROUP BY RAIN_GROUP
                         ORDER BY AVERAGE_RENTAL_DEMAND DESC, MAXIMUM_RENTAL_DEMAND DESC;"))

  cat("\n")
  cat("-----------------------------------------------------------------------\n")
  cat("Compare average rental demand between snowfall ranges\n")
  cat("-----------------------------------------------------------------------\n")
  cat("Find the highest rental count under different snowfall ranges\n")
  cat("-----------------------------------------------------------------------\n")

  # Compare average rental demand between snowfall ranges.
  # Find the highest rental count under different snowfall ranges.
  print(dbGetQuery(con, "SELECT CASE
                                  WHEN SNOWFALL = 0 THEN 'No snow'
                                  WHEN SNOWFALL <= 1 THEN '>0–1'
                                  WHEN SNOWFALL <= 3 THEN '>1–3'
                                  ELSE '>3'
                                END AS SNOW_GROUP,
                         COUNT(*) AS RECORDS,
                         AVG(RENTED_BIKE_COUNT) AS AVERAGE_RENTAL_DEMAND,
                         MAX(RENTED_BIKE_COUNT) AS MAXIMUM_RENTAL_DEMAND
                         FROM PROCESSED_SEOUL_BIKE_SHARING
                         GROUP BY SNOW_GROUP
                         ORDER BY AVERAGE_RENTAL_DEMAND DESC, MAXIMUM_RENTAL_DEMAND DESC;"))

  cat("\n")
  cat("-----------------------------------------------------------------------\n")
  cat("Compare average rental demand between humidity ranges\n")
  cat("-----------------------------------------------------------------------\n")
  cat("Find the highest rental count under different humidity ranges\n")
  cat("-----------------------------------------------------------------------\n")

  # Compare average rental demand between humidity ranges.
  # Find the highest rental count under different humidity ranges.
  print(dbGetQuery(con, "SELECT CASE
                                  WHEN HUMIDITY < 30 THEN '< 30%'
                                  WHEN HUMIDITY < 50 THEN '30–49%'
                                  WHEN HUMIDITY < 70 THEN '50–69%'
                                  WHEN HUMIDITY < 90 THEN '70–89%'
                                  ELSE '90%+'
                                END AS HUMIDITY_GROUP,
                         COUNT(*) AS RECORDS,
                         AVG(RENTED_BIKE_COUNT) AS AVERAGE_RENTAL_DEMAND,
                         MAX(RENTED_BIKE_COUNT) AS MAXIMUM_RENTAL_DEMAND
                         FROM PROCESSED_SEOUL_BIKE_SHARING
                         GROUP BY HUMIDITY_GROUP
                         ORDER BY AVERAGE_RENTAL_DEMAND DESC, MAXIMUM_RENTAL_DEMAND DESC;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Count observations with and without rain\n")
  cat("--------------------------------------------------\n")

  # Count observations with and without rain.
  print(dbGetQuery(con, "SELECT COUNT(CASE WHEN RAINFALL = 0 THEN 1 END) AS RECORD_COUNT_WITHOUT_RAIN,
                         COUNT(CASE WHEN RAINFALL <> 0 THEN 1 END) AS RECORD_COUNT_WITH_RAIN 
                         FROM PROCESSED_SEOUL_BIKE_SHARING;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Compare average rentals with and without rain\n")
  cat("--------------------------------------------------\n")

  # Compare average rentals with and without rain.
  print(dbGetQuery(con, "SELECT AVG(CASE WHEN RAINFALL = 0 THEN RENTED_BIKE_COUNT END) AS AVERAGE_RENTAL_DEMAND_WITHOUT_RAIN,
                         AVG(CASE WHEN RAINFALL <> 0 THEN RENTED_BIKE_COUNT END) AS AVERAGE_RENTAL_DEMAND_WITH_RAIN 
                         FROM PROCESSED_SEOUL_BIKE_SHARING;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Compare maximum rentals with and without rain\n")
  cat("--------------------------------------------------\n")

  # Compare maximum rentals with and without rain.
  print(dbGetQuery(con, "SELECT MAX(CASE WHEN RAINFALL = 0 THEN RENTED_BIKE_COUNT END) AS MAXIMUM_RENTAL_DEMAND_WITHOUT_RAIN,
                         MAX(CASE WHEN RAINFALL <> 0 THEN RENTED_BIKE_COUNT END) AS MAXIMUM_RENTAL_DEMAND_WITH_RAIN 
                         FROM PROCESSED_SEOUL_BIKE_SHARING;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Count observations with and without snow\n")
  cat("--------------------------------------------------\n")

  # Count observations with and without snow.
  print(dbGetQuery(con, "SELECT COUNT(CASE WHEN SNOWFALL = 0 THEN 1 END) AS RECORD_COUNT_WITHOUT_SNOW,
                         COUNT(CASE WHEN SNOWFALL <> 0 THEN 1 END) AS RECORD_COUNT_WITH_SNOW 
                         FROM PROCESSED_SEOUL_BIKE_SHARING;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Compare average rentals with and without snow\n")
  cat("--------------------------------------------------\n")

  # Compare average rentals with and without snow.
  print(dbGetQuery(con, "SELECT AVG(CASE WHEN SNOWFALL = 0 THEN RENTED_BIKE_COUNT END) AS AVERAGE_RENTAL_DEMAND_WITHOUT_SNOW,
                         AVG(CASE WHEN SNOWFALL <> 0 THEN RENTED_BIKE_COUNT END) AS AVERAGE_RENTAL_DEMAND_WITH_SNOW 
                         FROM PROCESSED_SEOUL_BIKE_SHARING;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Compare maximum rentals with and without snow\n")
  cat("--------------------------------------------------\n")
  
  # Compare maximum rentals with and without snow.
  print(dbGetQuery(con, "SELECT MAX(CASE WHEN SNOWFALL = 0 THEN RENTED_BIKE_COUNT END) AS MAXIMUM_RENTAL_DEMAND_WITHOUT_SNOW,
                         MAX(CASE WHEN SNOWFALL <> 0 THEN RENTED_BIKE_COUNT END) AS MAXIMUM_RENTAL_DEMAND_WITH_SNOW 
                         FROM PROCESSED_SEOUL_BIKE_SHARING;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Compare snowfall effects by season\n")
  cat("--------------------------------------------------\n")

  # Compare snowfall effects by season.
  print(dbGetQuery(con, "SELECT SEASONS,
                         CASE
                           WHEN SNOWFALL = 0 THEN 'No snow'
                           WHEN SNOWFALL <= 1 THEN 'Light snow'
                           WHEN SNOWFALL <= 3 THEN 'Moderate snow'
                           ELSE 'Heavy snow'
                         END AS SNOWFALL_CATEGORY,
                         COUNT(*) AS RECORDS,
                         AVG(RENTED_BIKE_COUNT) AS AVERAGE_RENTAL_DEMAND,
                         MAX(RENTED_BIKE_COUNT) AS MAXIMUM_RENTAL_DEMAND
                         FROM PROCESSED_SEOUL_BIKE_SHARING
                         GROUP BY SEASONS, SNOWFALL_CATEGORY
                         ORDER BY SEASONS, AVERAGE_RENTAL_DEMAND DESC, MAXIMUM_RENTAL_DEMAND DESC;"))

}

eda_bike_sharing_systems <- function(con){

  cat("\n")
  cat("----------------------------------------------------\n")
  cat("Count the total number of bike-sharing records\n")
  cat("----------------------------------------------------\n")
  
  # Count the total number of bike-sharing records.
  print(dbGetQuery(con, "SELECT COUNT(*) AS RECORD_COUNT FROM PROCESSED_BIKE_SHARING_SYSTEMS;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Count the number of unique countries\n")
  cat("--------------------------------------------------\n")

  # Count the number of unique countries.
  print(dbGetQuery(con, "SELECT COUNT(DISTINCT COUNTRY) AS UNIQUE_COUNTRIES_COUNT FROM PROCESSED_BIKE_SHARING_SYSTEMS;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Count the number of unique cities\n")
  cat("--------------------------------------------------\n")

  # Count the number of unique cities.
  print(dbGetQuery(con, "SELECT COUNT(DISTINCT CITY) AS UNIQUE_CITIES_COUNT FROM PROCESSED_BIKE_SHARING_SYSTEMS;"))

  cat("\n")
  cat("-----------------------------------------------------\n")
  cat("Count the number of unique bike-sharing systems\n")
  cat("-----------------------------------------------------\n")

  # Count the number of unique bike-sharing systems.
  print(dbGetQuery(con, "SELECT COUNT(DISTINCT SYSTEM) AS UNIQUE_SYSTEMS_COUNT FROM PROCESSED_BIKE_SHARING_SYSTEMS;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Count missing BICYCLES\n")
  cat("--------------------------------------------------\n")

  # Count missing BICYCLES.
  print(dbGetQuery(con, "SELECT COUNT(CASE WHEN BICYCLES IS NULL THEN 1 END) AS MISSING_BICYCLES_COUNT FROM PROCESSED_BIKE_SHARING_SYSTEMS;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Count records with BICYCLES = 0\n")
  cat("--------------------------------------------------\n")

  # Count records with BICYCLES = 0.
  print(dbGetQuery(con, "SELECT COUNT(CASE WHEN BICYCLES = 0 THEN 1 END) AS ZERO_BICYCLES_COUNT FROM PROCESSED_BIKE_SHARING_SYSTEMS;"))

  cat("\n")
  cat("----------------------------------------------------\n")
  cat("Check for duplicate CITY + SYSTEM combinations\n")
  cat("----------------------------------------------------\n")

  # Check for duplicate CITY + SYSTEM combinations.
  print(dbGetQuery(con, "SELECT CITY, SYSTEM, COUNT(*) AS DUPLICATE_COUNT FROM PROCESSED_BIKE_SHARING_SYSTEMS
                         GROUP BY CITY, SYSTEM
                         HAVING COUNT(*) > 1;"))

  cat("\n")
  cat("----------------------------------------------------------------------\n")
  cat("Find the minimum, maximum, average and median number of bicycles\n")
  cat("----------------------------------------------------------------------\n")

  # Find the minimum, maximum, average and median number of bicycles.
  print(dbGetQuery(con, "SELECT MIN(BICYCLES) AS MIN_BICYCLES_COUNT, MAX(BICYCLES) AS MAX_BICYCLES_COUNT, AVG(BICYCLES) AS AVG_BICYCLES_COUNT,
                         MEDIAN(BICYCLES) AS MEDIAN_BICYCLES_COUNT FROM PROCESSED_BIKE_SHARING_SYSTEMS;")) 

  cat("\n")
  cat("----------------------------------------------------------\n")
  cat("Find the 10 largest bike-sharing systems by BICYCLES\n")
  cat("----------------------------------------------------------\n")

  # Find the 10 largest bike-sharing systems by BICYCLES.
  print(dbGetQuery(con, "SELECT SYSTEM, COUNT(BICYCLES) AS BICYCLES_COUNT FROM PROCESSED_BIKE_SHARING_SYSTEMS
                         GROUP BY SYSTEM
                         ORDER BY BICYCLES_COUNT DESC
                         LIMIT 10;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Find the 10 smallest systems by BICYCLES\n")
  cat("--------------------------------------------------\n")

  # Find the 10 smallest systems by BICYCLES.
  print(dbGetQuery(con, "SELECT SYSTEM, COUNT(BICYCLES) AS BICYCLES_COUNT FROM PROCESSED_BIKE_SHARING_SYSTEMS
                         GROUP BY SYSTEM
                         ORDER BY BICYCLES_COUNT 
                         LIMIT 10;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Find the total number of bicycles by country\n")
  cat("--------------------------------------------------\n")

  # Find the total number of bicycles by country.
  print(dbGetQuery(con, "SELECT COUNTRY, SUM(BICYCLES) AS TOTAL_BICYCLES FROM PROCESSED_BIKE_SHARING_SYSTEMS
                         GROUP BY COUNTRY;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Find the average fleet size by country\n")
  cat("--------------------------------------------------\n")

  # Find the average fleet size by country.
  print(dbGetQuery(con, "SELECT COUNTRY, AVG(BICYCLES) AS AVERAGE_FLEET_SIZE FROM PROCESSED_BIKE_SHARING_SYSTEMS
                         GROUP BY COUNTRY;"))

  cat("\n")
  cat("--------------------------------------------------------------\n")
  cat("Find top 10 countries with the most bike-sharing systems\n")
  cat("--------------------------------------------------------------\n")

  # Find top 10 countries with the most bike-sharing systems.
  print(dbGetQuery(con, "SELECT COUNTRY, COUNT(SYSTEM) AS BIKE_SHARING_SYSTEMS_COUNT FROM PROCESSED_BIKE_SHARING_SYSTEMS
                         GROUP BY COUNTRY
                         ORDER BY BIKE_SHARING_SYSTEMS_COUNT DESC
                         LIMIT 10;"))

  cat("\n")
  cat("---------------------------------------------------------------\n")
  cat("Find top 10 countries with the largest average fleet size\n")
  cat("---------------------------------------------------------------\n")

  # Find top 10 countries with the largest average fleet size.
  print(dbGetQuery(con, "SELECT COUNTRY, AVG(BICYCLES) AS AVERAGE_FLEET_SIZE FROM PROCESSED_BIKE_SHARING_SYSTEMS
                         GROUP BY COUNTRY
                         ORDER BY AVERAGE_FLEET_SIZE DESC
                         LIMIT 10;"))

  cat("\n")
  cat("--------------------------------------------------------------\n")
  cat("Find cities that have multiple bike-sharing systems\n")
  cat("--------------------------------------------------------------\n")

  # Find cities that have multiple bike-sharing systems.
  print(dbGetQuery(con, "SELECT CITY, COUNT(SYSTEM) AS BIKE_SHARING_SYSTEM_COUNT FROM PROCESSED_BIKE_SHARING_SYSTEMS
                        GROUP BY CITY
                        HAVING COUNT(SYSTEM) > 1;"))

  cat("\n")
  cat("--------------------------------------------------------------\n")
  cat("Find the total bicycle fleet for those cities\n")
  cat("--------------------------------------------------------------\n")

  # Find the total bicycle fleet for those cities.
  print(dbGetQuery(con, "SELECT CITY, COUNT(SYSTEM) AS BIKE_SHARING_SYSTEM_COUNT, SUM(BICYCLES) AS TOTAL_BICYCLE_FLEET FROM PROCESSED_BIKE_SHARING_SYSTEMS
                        GROUP BY CITY
                        HAVING COUNT(SYSTEM) > 1;"))

  cat("\n")
  cat("----------------------------------------------------------------\n")
  cat("Find the percentage of records with missing bicycle counts\n")
  cat("----------------------------------------------------------------\n")

  # Find the percentage of records with missing bicycle counts.
  print(dbGetQuery(con, "SELECT (SELECT COUNT(CASE WHEN BICYCLES IS NULL THEN 1 END) AS MISSING_BICYCLES_COUNT FROM PROCESSED_BIKE_SHARING_SYSTEMS)*100.0/COUNT(*) AS PROPORTION_MISSING_BICYCLES
                         FROM PROCESSED_BIKE_SHARING_SYSTEMS;"))

  cat("\n")
  cat("--------------------------------------------------------------\n")
  cat("Identify extremely large systems, e.g. BICYCLES > 30,000\n")
  cat("--------------------------------------------------------------\n")

  # Identify extremely large systems, e.g. BICYCLES > 30,000.
  print(dbGetQuery(con, "SELECT SYSTEM, SUM(BICYCLES) AS TOTAL_BICYCLE_COUNT FROM PROCESSED_BIKE_SHARING_SYSTEMS
                         GROUP BY SYSTEM
                         HAVING SUM(BICYCLES) > 30000
                         ORDER BY TOTAL_BICYCLE_COUNT DESC;"))

}

advanced_eda <- function(con){

  cat("\n")
  cat("------------------------------------------------------------------------\n")
  cat("Count how many bike-sharing cities successfully match a world city\n")
  cat("------------------------------------------------------------------------\n")

  # Count how many bike-sharing cities successfully match a world city.
  print(dbGetQuery(con, "SELECT COUNT(DISTINCT BSS.CITY) AS MATCHING_CITIES_COUNT FROM PROCESSED_BIKE_SHARING_SYSTEMS AS BSS
                         LEFT JOIN PROCESSED_WORLDCITIES AS WC ON BSS.CITY = WC.CITY
                         WHERE WC.CITY IS NOT NULL;"))

  cat("\n")
  cat("--------------------------------------------------------------\n")
  cat("Identify bike-sharing cities that don't match\n")
  cat("--------------------------------------------------------------\n")

  # Identify bike-sharing cities that don't match.
  print(dbGetQuery(con, "SELECT COUNT(DISTINCT BSS.CITY) AS NOT_MATCHING_CITIES_COUNT FROM PROCESSED_BIKE_SHARING_SYSTEMS AS BSS
                         LEFT JOIN PROCESSED_WORLDCITIES AS WC ON BSS.CITY = WC.CITY
                         WHERE WC.CITY IS NULL;"))

  cat("\n")
  cat("--------------------------------------------------------------\n")
  cat("Identify world-city matches that produce multiple rows\n")
  cat("--------------------------------------------------------------\n")

  # Identify world-city matches that produce multiple rows.
  print(dbGetQuery(con, "SELECT BSS.CITY, COUNT(*) AS MULTIPLE_MATCHES FROM PROCESSED_BIKE_SHARING_SYSTEMS AS BSS, PROCESSED_WORLDCITIES AS WC
                         WHERE BSS.CITY = WC.CITY
                         GROUP BY BSS.CITY
                         HAVING COUNT(*) > 1
                         ORDER BY MULTIPLE_MATCHES DESC;"))

  cat("\n")
  cat("--------------------------------------------------------------\n")
  cat("Find the largest cities with bike-sharing systems\n")
  cat("--------------------------------------------------------------\n")

  # Find the largest cities with bike-sharing systems.
  print(dbGetQuery(con, "SELECT BSS.CITY AS BIKE_SHARING_CITIES, WC.POPULATION FROM PROCESSED_BIKE_SHARING_SYSTEMS AS BSS, PROCESSED_WORLDCITIES AS WC
                         WHERE BSS.CITY = WC.CITY AND BSS.BICYCLES IS NOT NULL
                         GROUP BY BSS.CITY
                         ORDER BY WC.POPULATION DESC
                         LIMIT 5;"))

  cat("\n")
  cat("--------------------------------------------------------------\n")
  cat("Compare population and bicycle fleet size\n")
  cat("--------------------------------------------------------------\n")

  # Compare population and bicycle fleet size.
  print(dbGetQuery(con, "SELECT BSS.CITY AS BIKE_SHARING_CITIES, WC.POPULATION, BSS.BICYCLES FROM PROCESSED_BIKE_SHARING_SYSTEMS AS BSS, PROCESSED_WORLDCITIES AS WC
                         WHERE BSS.CITY = WC.CITY AND BSS.BICYCLES IS NOT NULL
                         GROUP BY BSS.CITY
                         ORDER BY WC.POPULATION DESC
                         LIMIT 5;"))

  cat("\n")
  cat("--------------------------------------------------------------\n")
  cat("Calculate bicycles per 1,000 population\n")
  cat("--------------------------------------------------------------\n")

  # Calculate bicycles per 1,000 population.
  print(dbGetQuery(con, "SELECT BSS.CITY, BSS.BICYCLES, WC.POPULATION,
                         ROUND(BSS.BICYCLES * 1000.0 / WC.POPULATION, 2) AS BICYCLES_PER_1000
                         FROM PROCESSED_BIKE_SHARING_SYSTEMS BSS
                         JOIN PROCESSED_WORLDCITIES WC
                          ON BSS.CITY = WC.CITY
                         WHERE BSS.BICYCLES IS NOT NULL AND WC.POPULATION > 0
                         ORDER BY BICYCLES_PER_1000 DESC;"))

  cat("\n")
  cat("--------------------------------------------------------------------\n")
  cat("Find cities with large populations but relatively small fleets\n")
  cat("--------------------------------------------------------------------\n")

  # Find cities with large populations but relatively small fleets.
  print(dbGetQuery(con, "SELECT BSS.CITY, BSS.COUNTRY, BSS.BICYCLES, WC.POPULATION,
                         ROUND(BSS.BICYCLES * 1000.0 / WC.POPULATION, 2) AS BICYCLES_PER_1000
                         FROM PROCESSED_BIKE_SHARING_SYSTEMS BSS
                         JOIN PROCESSED_WORLDCITIES WC
                           ON BSS.CITY = WC.CITY AND BSS.COUNTRY = WC.COUNTRY
                         WHERE WC.POPULATION >= 500000
                           AND BSS.BICYCLES IS NOT NULL
                           AND WC.POPULATION > 0
                           AND BSS.BICYCLES * 1000.0 / WC.POPULATION < 2
                         ORDER BY WC.POPULATION DESC;"))

  cat("\n")
  cat("--------------------------------------------------------------------\n")
  cat("Find cities with small populations but relatively large fleets\n")
  cat("--------------------------------------------------------------------\n")

  # Find cities with small populations but relatively large fleets.
  print(dbGetQuery(con, "SELECT BSS.CITY, BSS.COUNTRY, BSS.BICYCLES, WC.POPULATION,
                         ROUND(BSS.BICYCLES * 1000.0 / WC.POPULATION, 2) AS BICYCLES_PER_1000
                         FROM PROCESSED_BIKE_SHARING_SYSTEMS BSS
                         JOIN PROCESSED_WORLDCITIES WC
                           ON BSS.CITY = WC.CITY AND BSS.COUNTRY = WC.COUNTRY
                         WHERE WC.POPULATION < 100000
                           AND WC.POPULATION > 0
                           AND BSS.BICYCLES IS NOT NULL
                           AND BSS.BICYCLES * 1000.0 / WC.POPULATION > 10
                         ORDER BY BICYCLES_PER_1000 DESC;"))

  cat("\n")
  cat("--------------------------------------------------\n")
  cat("Count successful city matches\n")
  cat("--------------------------------------------------\n")

  # Count successful city matches.
  print(dbGetQuery(con, "SELECT COUNT(DISTINCT CWF.CITY) AS MATCHING_RECORDS FROM PROCESSED_CITIES_WEATHER_FORECAST AS CWF, PROCESSED_WORLDCITIES AS WC
                         WHERE CWF.CITY = WC.CITY;"))

  cat("\n")
  cat("----------------------------------------------------\n")
  cat("Find the largest cities with weather forecasts\n")
  cat("----------------------------------------------------\n")

  # Find the largest cities with weather forecasts.
  print(dbGetQuery(con, "SELECT CWF.CITY, AVG(WC.POPULATION) AS AVERAGE_POPULATION FROM PROCESSED_CITIES_WEATHER_FORECAST AS CWF, PROCESSED_WORLDCITIES AS WC
                         WHERE CWF.CITY = WC.CITY
                         GROUP BY CWF.CITY
                         ORDER BY AVERAGE_POPULATION DESC;"))

  cat("\n")
  cat("--------------------------------------------------------------------\n")
  cat("Compare population with temperature, humidity and wind speed\n")
  cat("--------------------------------------------------------------------\n")

  # Compare population with temperature, humidity and wind speed.
  print(dbGetQuery(con, " SELECT WC.CITY, WC.POPULATION, CWF.TEMP, CWF.HUMIDITY, CWF.WIND_SPEED FROM PROCESSED_WORLDCITIES AS WC, PROCESSED_CITIES_WEATHER_FORECAST AS CWF
                          WHERE WC.CITY = CWF.CITY
                          GROUP BY WC.CITY
                          ORDER BY WC.POPULATION DESC;"))

  cat("\n")
  cat("--------------------------------------------------------\n")
  cat("Find the largest city under each weather condition\n")
  cat("--------------------------------------------------------\n")

  # Find the largest city under each weather condition.
  print(dbGetQuery(con, "WITH CTE AS(
                          SELECT CWF.CITY, WC.POPULATION, CAST(CWF.TEMP AS TEXT) || ' (TEMPERATURE)' AS WEATHER_CONDITION,
                          ROW_NUMBER() OVER(ORDER BY WC.POPULATION DESC) AS RN
                          FROM PROCESSED_WORLDCITIES AS WC, PROCESSED_CITIES_WEATHER_FORECAST AS CWF
                          WHERE WC.CITY = CWF.CITY
                          GROUP BY WC.CITY
                          UNION
                          SELECT CWF.CITY, WC.POPULATION, CAST(CWF.HUMIDITY AS TEXT) || ' (HUMIDITY)' AS WEATHER_CONDITION,
                          ROW_NUMBER() OVER(ORDER BY WC.POPULATION DESC) AS RN
                          FROM PROCESSED_WORLDCITIES AS WC, PROCESSED_CITIES_WEATHER_FORECAST AS CWF
                          WHERE WC.CITY = CWF.CITY
                          GROUP BY WC.CITY
                          UNION 
                          SELECT CWF.CITY, WC.POPULATION, CAST(CWF.WIND_SPEED AS TEXT) || ' (WIND_SPEED)' AS WEATHER_CONDITION,
                          ROW_NUMBER() OVER(ORDER BY WC.POPULATION DESC) AS RN
                          FROM PROCESSED_WORLDCITIES AS WC, PROCESSED_CITIES_WEATHER_FORECAST AS CWF
                          WHERE WC.CITY = CWF.CITY
                          GROUP BY WC.CITY
                         )
                         SELECT CITY, POPULATION, WEATHER_CONDITION FROM CTE WHERE RN = 1;"))

  cat("\n")
  cat("--------------------------------------------------------------------\n")
  cat("Find bike-sharing cities with available weather forecasts\n")
  cat("--------------------------------------------------------------------\n")

  # Find bike-sharing cities with available weather forecasts.
  print(dbGetQuery(con, "SELECT COUNT(DISTINCT BSS.CITY) AS BIKE_SHARING_CITIES_COUNT FROM PROCESSED_BIKE_SHARING_SYSTEMS AS BSS, PROCESSED_CITIES_WEATHER_FORECAST AS CWF
                         WHERE BSS.CITY = CWF.CITY;"))

  cat("\n")
  cat("--------------------------------------------------------------------\n")
  cat("Compare fleet size with temperature, humidity, wind_speed\n")
  cat("--------------------------------------------------------------------\n")

  # Compare fleet size with temperature, humidity, wind_speed.
  print(dbGetQuery(con, "SELECT BSS.CITY, BSS.BICYCLES AS FLEET_SIZE, AVG(CWF.TEMP) AS AVERAGE_TEMPERATURE,
                         AVG(CWF.HUMIDITY) AS AVERAGE_HUMIDITY, AVG(CWF.WIND_SPEED) AS AVERAGE_WIND_SPEED
                         FROM PROCESSED_BIKE_SHARING_SYSTEMS AS BSS, PROCESSED_CITIES_WEATHER_FORECAST AS CWF
                         WHERE BSS.CITY = CWF.CITY
                         GROUP BY BSS.CITY, BSS.BICYCLES
                         ORDER BY BSS.BICYCLES DESC;"))

  cat("\n")
  cat("----------------------------------------------------------------------\n")
  cat("Find cities with large fleets and unfavorable weather conditions\n")
  cat("----------------------------------------------------------------------\n")

  # Find cities with large fleets and unfavorable weather conditions.
  print(dbGetQuery(con, "SELECT DISTINCT BSS.CITY, BSS.BICYCLES AS FLEET_SIZE, CWF.TEMP, CWF.HUMIDITY, CWF.WIND_SPEED
                         FROM PROCESSED_BIKE_SHARING_SYSTEMS BSS, PROCESSED_CITIES_WEATHER_FORECAST CWF
                         WHERE BSS.CITY = CWF.CITY AND BSS.BICYCLES >= 10000 AND (CWF.TEMP < 10 OR CWF.HUMIDITY > 80 OR CWF.WIND_SPEED > 4)
                         ORDER BY BSS.BICYCLES DESC;"))

  cat("\n")
  cat("----------------------------------------------------------------------\n")
  cat("Find cities with large fleets and favorable weather conditions\n")
  cat("----------------------------------------------------------------------\n")

  # Find cities with large fleets and favorable weather conditions.
  print(dbGetQuery(con, " SELECT DISTINCT BSS.CITY, BSS.BICYCLES AS FLEET_SIZE, CWF.TEMP, CWF.HUMIDITY, CWF.WIND_SPEED
                          FROM PROCESSED_BIKE_SHARING_SYSTEMS BSS ,PROCESSED_CITIES_WEATHER_FORECAST CWF
                          WHERE BSS.CITY = CWF.CITY AND BSS.BICYCLES >= 10000 AND CWF.TEMP BETWEEN 10 AND 25
                          AND CWF.HUMIDITY BETWEEN 30 AND 70 AND CWF.WIND_SPEED <= 4
                          ORDER BY BSS.BICYCLES DESC;"))

  cat("\n")
  cat("--------------------------------------------------------\n")
  cat("Compare bike infrastructure with forecast weather\n")
  cat("--------------------------------------------------------\n")

  # Compare bike infrastructure with forecast weather.
  print(dbGetQuery(con, " SELECT BSS.CITY, BSS.BICYCLES AS FLEET_SIZE, WC.POPULATION,
                          AVG(CWF.TEMP) AS AVERAGE_TEMPERATURE, AVG(CWF.HUMIDITY) AS AVERAGE_HUMIDITY,
                          AVG(CWF.WIND_SPEED) AS AVERAGE_WIND_SPEED
                          FROM PROCESSED_BIKE_SHARING_SYSTEMS BSS
                          JOIN PROCESSED_WORLDCITIES WC
                            ON BSS.CITY = WC.CITY
                          JOIN PROCESSED_CITIES_WEATHER_FORECAST CWF
                            ON BSS.CITY = CWF.CITY
                          WHERE BSS.BICYCLES IS NOT NULL
                            AND WC.POPULATION IS NOT NULL
                            AND WC.POPULATION > 0
                          GROUP BY
                            BSS.CITY,
                            BSS.BICYCLES,
                            WC.POPULATION
                          ORDER BY BSS.BICYCLES DESC;"))

  cat("\n")
  cat("------------------------------------------------------------------------------------------------------------------------------------------------\n")
  cat("Use an implicit join across the WORLD_CITIES and the BIKE_SHARING_SYSTEMS tables to determine the total number of bikes avaialble in Seoul\n")
  cat("------------------------------------------------------------------------------------------------------------------------------------------------\n")
  cat("plus the following city information about Seoul: CITY, COUNTRY, LAT, LON, POPULATION, in a single view\n")
  cat("------------------------------------------------------------------------------------------------------------------------------------------------\n")

  # Use an implicit join across the WORLD_CITIES and the BIKE_SHARING_SYSTEMS tables to determine the total number of bikes avaialble in Seoul,
  # plus the following city information about Seoul: CITY, COUNTRY, LAT, LON, POPULATION, in a single view.
  print(dbGetQuery(con, " SELECT WC.CITY, WC.COUNTRY, WC.LAT, WC.LNG, WC.POPULATION, SUM(BSS.BICYCLES) AS TOTAL_BICYCLES FROM PROCESSED_BIKE_SHARING_SYSTEMS AS BSS, PROCESSED_WORLDCITIES AS WC
                          WHERE BSS.CITY = WC.CITY AND BSS.CITY = 'Seoul'
                          GROUP BY WC.CITY, WC.COUNTRY, WC.LAT, WC.LNG, POPULATION;"))

  cat("\n")
  cat("------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n")
  cat("Find all cities with total bike counts between 15000 and 20000. Return the city and country names, plus the coordinates (LAT, LNG), population, and number of bicycles for each city\n")
  cat("------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n")

  # Find all cities with total bike counts between 15000 and 20000. Return the city and country names, plus the coordinates (LAT, LNG), population, and number of bicycles for each city.
  print(dbGetQuery(con, " SELECT WC.CITY, WC.COUNTRY, WC.LAT, WC.LNG, WC.POPULATION, SUM(BSS.BICYCLES) AS TOTAL_BICYCLES FROM PROCESSED_WORLDCITIES AS WC, PROCESSED_BIKE_SHARING_SYSTEMS AS BSS
                          WHERE BSS.CITY = WC.CITY
                          GROUP BY WC.CITY, WC.COUNTRY, WC.LAT, WC.LNG, WC.POPULATION
                          HAVING SUM(BSS.BICYCLES) BETWEEN 15000 AND 20000;"))

}

sql_based_eda_pipieline <- function(con, dest_path, filename){

  sink(file.path(dest_path, filename), append = FALSE, split = TRUE)

  cat("============================================================\n")
  cat("SQL EDA QUERY OUTPUT DUMP\n")
  cat("============================================================\n")

  eda_world_cities(con)
  eda_cities_weather_forecast(con)
  eda_seoul_bike_sharing(con)
  eda_bike_sharing_systems(con)
  advanced_eda(con)
  DBI::dbDisconnect(con)

  cat("\n")
  cat(strrep("=", 60), "\n")
  cat("END OF OUTPUT DUMP\n")
  cat(strrep("=", 60), "\n")

  sink()
}

sql_based_eda_pipieline(con, "../logs", "queries_output.log")
