library(rvest)

webscraping_from_wiki <- function(url, path, name){

    # Get the root HTML node by calling the `read_html()` method with URL
    root_html_node <- read_html(url)
    table_nodes <- html_nodes(root_html_node, "table")

    # I used a for loop to print each table, and then I saw the actual the bike sharing table is the first element table_nodes[[1]].
    # for (i in seq_along(table_nodes)) {
    #     print(table_nodes[[i]])
    # }

    # Convert the bike-sharing system table into a dataframe
    df <- html_table(table_nodes[[1]], fill = TRUE)

    # Summarize the dataframe
    print(summary(df))

    # Export the dataframe into a csv file
    write.csv(df, file.path(path, name), row.names = FALSE)
}

webscraping_from_wiki("https://en.wikipedia.org/wiki/List_of_bicycle-sharing_systems", "../data_raw", "raw_bike_sharing_systems_depricated.csv")