library("RSQLite")
library("tidyverse")

RSQlite_config <- function(source_path, dataset_list){
    con <- dbConnect(RSQLite::SQLite(),"TestDB.sqlite")

    for(dataset_name in dataset_list){
        dataset <- read_csv(file.path(source_path, dataset_name))
        dbWriteTable(con, toupper(substr(dataset_name, 1, nchar(dataset_name) - 4)), dataset, overwrite = TRUE)
    }
    
    return(con)
}