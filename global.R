
source("libraries.R")

get_all_musees <- function(limit = 100) {
  base_url <- "https://data.culture.gouv.fr/api/explore/v2.1/catalog/datasets/liste-et-localisation-des-musees-de-france/records"
  all_data <- list()
  offset <- 0

  repeat {
    url <- paste0(base_url, "?limit=", limit, "&offset=", offset)
    response <- GET(url)
    if (response$status_code != 200) break

    json_data <- content(response, as = "text", encoding = "UTF-8")
    page_data <- fromJSON(json_data, flatten = TRUE)$results

    if (length(page_data) == 0) break

    all_data <- append(all_data, list(page_data))
    offset <- offset + limit
  }

  bind_rows(all_data)
}

musees_raw <- get_all_musees()

musees <- musees_raw %>%
  rename(
    nom = nom_officiel_du_musee,
    adresse = adresse,
    cp = code_postal,
    ville = commune,
    region = region_administrative,
    departement = departement
  ) %>%
  filter(!is.na(latitude) & !is.na(longitude))
