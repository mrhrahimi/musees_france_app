
source("libraries.R")
source("global.R")

ui <- fluidPage(
  theme = shinytheme("flatly"),
  titlePanel("🏛️ Musées de France"),
  tabsetPanel(
    tabPanel("🗺️ Carte",
             sidebarLayout(
               sidebarPanel(
                 selectInput("region", "Filtrer par région :", choices = c("Toutes", sort(unique(musees$region)))),
                 uiOutput("departement_ui")
               ),
               mainPanel(
                 leafletOutput("musee_map", height = 550)
               )
             )
    ),
    tabPanel("📋 Liste des musées",
             DTOutput("musee_table"),
             downloadButton("download_csv", "📥 Exporter en CSV")
    ),
    tabPanel("🔍 Recherche par nom",
             textInput("search", "Nom contient :", value = ""),
             DTOutput("search_table")
    ),
    tabPanel("📊 Statistiques",
             fluidRow(
               column(6, plotOutput("bar_region")),
               column(6, plotOutput("bar_dept"))
             )
    ),
    tabPanel("📍 Musées à proximité",
             sidebarLayout(
               sidebarPanel(
                 textInput("address", "Entrez une adresse (ex: 8 rue de Rivoli, Paris)", ""),
                 sliderInput("radius", "Rayon (km)", min = 1, max = 50, value = 10),
                 actionButton("go", "Rechercher"),
                 downloadButton("download_prox", "📥 Export proximité")
               ),
               mainPanel(
                 leafletOutput("prox_map", height = 500),
                 DTOutput("prox_table")
               )
             )
    )
  )
)

server <- function(input, output, session) {
  observe({
    req(input$region)
    if (input$region == "Toutes") {
      updateSelectInput(session, "dept", choices = c("Tous", sort(unique(musees$departement))))
    } else {
      choix <- musees %>% filter(region == input$region) %>% pull(departement) %>% unique() %>% sort()
      updateSelectInput(session, "dept", choices = c("Tous", choix))
    }
  })
  
  output$departement_ui <- renderUI({
    choix <- if (input$region == "Toutes") {
      sort(unique(musees$departement))
    } else {
      sort(unique(musees[musees$region == input$region, "departement"]))
    }
    selectInput("dept", "Filtrer par département :", choices = c("Tous", choix))
  })
  
  filtered_data <- reactive({
    df <- musees
    if (input$region != "Toutes") df <- df %>% filter(region == input$region)
    if (input$dept != "Tous") df <- df %>% filter(departement == input$dept)
    df
  })
  
  output$musee_map <- renderLeaflet({
    leaflet(data = filtered_data()) %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      addCircleMarkers(
        lng = ~longitude, lat = ~latitude,
        radius = 5, color = "darkblue",
        popup = ~paste0(
          "<b>", nom, "</b><br>",
          adresse, "<br>", ville, " (", cp, ")<br>",
          ifelse(!is.na(telephone), paste0("📞 ", telephone, "<br>"), ""),
          ifelse(!is.na(url), paste0("🔗 <a href='http://", url, "' target='_blank'>Site web</a><br>"), "")
        )
      )
  })
  
  output$musee_table <- renderDT({
    musees %>%
      select(nom, adresse, ville, cp, telephone, url, departement, region) %>%
      datatable(options = list(pageLength = 10))
  })
  
  output$download_csv <- downloadHandler(
    filename = function() {"musees_france.csv"},
    content = function(file) {
      write.csv(musees, file, row.names = FALSE)
    }
  )
  
  output$search_table <- renderDT({
    if (input$search == "") {
      return(datatable(data.frame(Message = "Tapez un mot-clé pour lancer la recherche")))
    }
    
    musees %>%
      filter(str_detect(str_to_lower(nom), str_to_lower(input$search))) %>%
      select(nom, adresse, ville, cp, telephone, url, departement, region) %>%
      datatable()
  })
  
  output$bar_region <- renderPlot({
    musees %>%
      count(region, sort = TRUE) %>%
      top_n(10) %>%
      ggplot(aes(x = reorder(region, n), y = n)) +
      geom_col(fill = "steelblue") +
      coord_flip() +
      labs(x = "Région", y = "Nombre de musées", title = "Top 10 régions")
  })
  
  output$bar_dept <- renderPlot({
    musees %>%
      count(departement, sort = TRUE) %>%
      top_n(10) %>%
      ggplot(aes(x = reorder(departement, n), y = n)) +
      geom_col(fill = "darkgreen") +
      coord_flip() +
      labs(x = "Département", y = "Nombre de musées", title = "Top 10 départements")
  })
  
  prox_data <- reactiveVal()
  
  observeEvent(input$go, {
    req(input$address)
    result <- tryCatch({
      geocode_OSM(input$address)
    }, error = function(e) NULL)
    
    if (is.null(result)) return(NULL)
    
    user_lat <- result$coords["y"]
    user_lon <- result$coords["x"]
    
    nearby <- musees %>%
      mutate(dist_km = geosphere::distHaversine(cbind(longitude, latitude), c(user_lon, user_lat)) / 1000) %>%
      filter(dist_km <= input$radius) %>%
      arrange(dist_km)
    
    prox_data(nearby)
    
    output$prox_map <- renderLeaflet({
      icons_musee <- awesomeIcons(
        icon = 'university', library = 'fa',
        markerColor = 'blue'
      )
      leaflet(data = nearby) %>%
        addTiles() %>%
        addAwesomeMarkers(lng = user_lon, lat = user_lat, popup = "📍 Votre adresse", icon = awesomeIcons(icon = 'home', markerColor = 'red')) %>%
        addAwesomeMarkers(
          lng = ~longitude, lat = ~latitude, icon = icons_musee,
          popup = ~paste0("<b>", nom, "</b><br>", adresse, "<br>", ville, "<br>", round(dist_km, 2), " km")
        )
    })
    
    output$prox_table <- renderDT({
      nearby %>%
        select(nom, adresse, ville, cp, telephone, url, dist_km) %>%
        datatable(options = list(pageLength = 10))
    })
  })
  
  output$download_prox <- downloadHandler(
    filename = function() {"musees_proximite.csv"},
    content = function(file) {
      write.csv(prox_data(), file, row.names = FALSE)
    }
  )
}

shinyApp(ui, server)
