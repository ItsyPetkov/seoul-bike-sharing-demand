library(httr)

# Download several aggregated datasets from cloud storage
cloud_datasets_download <- function(url, path, list){
    for (i in seq_along(list)){
        download.file(file.path(url, list[i]), destfile = file.path(path, list[i]))
    }
}

cloud_datasets_download(url = "https://cf-courses-data.s3.us.cloud-object-storage.appdomain.cloud/IBMDeveloperSkillsNetwork-RP0321EN-SkillsNetwork/labs/datasets",
                        path = "../data_raw", list = c("raw_bike_sharing_systems.csv", "raw_worldcities.csv", "raw_seoul_bike_sharing.csv"))