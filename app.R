
source("libraries.R")
source("global.R")

ui <- fluidPage(
  theme = shinytheme("flatly"),
  titlePanel("🚲 Vélib"),
  tabsetPanel(
    tabPanel("🗺️ Carte",
             br(),
             leafletOutput("map", height = 600)
    ),
    tabPanel("🏙️ Par commune",
             br(),
             selectInput("commune", "Choisir une commune", choices = sort(unique(velib$Commune))),
             DTOutput("table")
    ),
    tabPanel("📍 Recherche par adresse",
             br(),
             textInput("address", "Entrez une adresse en Île-de-France :"),
             actionButton("search", "🔍 Rechercher"),
             leafletOutput("near_map", height = 500),
             DTOutput("near_table")
    ),
    tabPanel("📊 Statistiques",
             br(),
             plotOutput("hist_commune"),
             br(),
             plotOutput("bike_type_ratio")
    )
  )
)

server <- function(input, output, session) {

  color_pal <- colorNumeric(palette = "Dark2", domain = velib$`Nombre total vélos disponibles`)

  output$map <- renderLeaflet({
    leaflet(data = velib) %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      addCircleMarkers(
        lng = ~longitude,
        lat = ~latitude,
        radius = 6,
        color = ~color_pal(`Nombre total vélos disponibles`),
        popup = ~paste0(
          "<b>", `Nom station`, "</b><br>",
          "Commune : ", Commune, "<br>",
          "🚲 Total vélos : ", `Nombre total vélos disponibles`, "<br>",
          "⚡ Vélos électriques : ", `Vélos électriques disponibles`, "<br>",
          "🔲 Bornettes libres : ", `Nombre bornettes libres`
        ),
        clusterOptions = markerClusterOptions()
      )
  })

  output$table <- renderDT({
    req(input$commune)
    velib %>%
      filter(Commune == input$commune) %>%
      select(`Nom station`, Commune, `Nombre total vélos disponibles`,
             `Vélos mécaniques disponibles`, `Vélos électriques disponibles`, `Nombre bornettes libres`) %>%
      datatable(options = list(pageLength = 10))
  })

  observeEvent(input$search, {
    req(input$address)

    coords <- tryCatch({
      tibble(address = input$address) %>%
        geocode(address = address, method = "osm", lat = latitude, long = longitude, limit = 1)
    }, error = function(e) {
      showNotification("Erreur géocodage : " %+% e$message, type = "error")
      return(NULL)
    })

    if (is.null(coords) || is.na(coords$longitude)) {
      showNotification("Adresse introuvable ou mal formatée.", type = "warning")
      return()
    }

    user_point <- c(coords$longitude, coords$latitude)
    velib$distance <- distHaversine(matrix(c(as.numeric(velib$longitude), as.numeric(velib$latitude)), ncol = 2), user_point)

    nearest <- velib %>% filter(distance <= 500)

    output$near_map <- renderLeaflet({
      leaflet(data = nearest) %>%
        addProviderTiles(providers$CartoDB.Positron) %>%
        setView(lng = coords$longitude, lat = coords$latitude, zoom = 16) %>%
        addCircleMarkers(lng = ~longitude, lat = ~latitude,
                         popup = ~paste0("<b>", `Nom station`, "</b><br>Distance : ", round(distance), " m<br>",
                                         "⚡ Vélos électriques : ", `Vélos électriques disponibles`),
                         color = "red") %>%
        addCircleMarkers(lng = coords$longitude, lat = coords$latitude, color = "blue", radius = 6,
                         popup = "📍 Adresse recherchée")
    })

    output$near_table <- renderDT({
      nearest %>%
        select(`Nom station`, Commune, distance, `Nombre total vélos disponibles`, `Vélos électriques disponibles`) %>%
        arrange(distance) %>%
        datatable()
    })
  })

  output$hist_commune <- renderPlot({
    velib %>%
      group_by(Commune) %>%
      summarise(total = sum(`Nombre total vélos disponibles`, na.rm = TRUE)) %>%
      top_n(10, total) %>%
      arrange(total) %>%
      ggplot(aes(x = reorder(Commune, total), y = total)) +
      geom_col(fill = "steelblue") +
      coord_flip() +
      labs(x = "Commune", y = "Vélos disponibles", title = "Top 10 communes avec le plus de vélos")
  })

  output$bike_type_ratio <- renderPlot({
    velib %>%
      summarise(
        `Vélos mécaniques` = sum(`Vélos mécaniques disponibles`, na.rm = TRUE),
        `Vélos électriques` = sum(`Vélos électriques disponibles`, na.rm = TRUE)
      ) %>%
      pivot_longer(cols = everything(), names_to = "Type", values_to = "Nombre") %>%
      ggplot(aes(x = Type, y = Nombre, fill = Type)) +
      geom_col(show.legend = FALSE) +
      labs(title = "Répartition des types de vélos", x = "", y = "Nombre") +
      theme_minimal()
  })
}

shinyApp(ui, server)
