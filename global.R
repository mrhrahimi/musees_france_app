
source("libraries.R")

url <- "https://opendata.paris.fr/api/explore/v2.1/catalog/datasets/velib-disponibilite-en-temps-reel/exports/csv?lang=fr&timezone=Europe%2FBerlin&use_labels=true&delimiter=%3B"

velib_data <- suppressWarnings(read_delim(url, delim = ";", escape_double = FALSE, trim_ws = TRUE))

velib_data <- velib_data %>%
  rename(Commune = `Nom communes équipées`) %>%
  separate(`Coordonnées géographiques`, into = c("latitude", "longitude"), sep = ",", convert = TRUE) %>%
  mutate(
    latitude = as.numeric(latitude),
    longitude = as.numeric(longitude)
  ) %>%
  filter(!is.na(latitude), !is.na(longitude), !is.na(Commune))

velib <- velib_data
