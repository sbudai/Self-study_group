# LOADING LIBRARIES
suppressPackageStartupMessages(library(shiny))
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(DT))
suppressPackageStartupMessages(library(jsonlite))

# READ SOURCE FILE 
geo_catalog <- fread('geo_catalog.csv')
geo_catalog[CityName == '', CityName := 'not related']


# DETECT USERS GEO LOCATION
MyLocation <- as.data.table(jsonlite::fromJSON('http://ipinfo.io/', simplifyDataFrame = TRUE))
MyLocation <- cbind(MyLocation, MyLocation[, tstrsplit(loc, ',')])
MyLocation[, ':=' (Lat = as.numeric(V1), Lon = as.numeric(V2))]
MyLocation[, ':=' (V1 = NULL, V2 = NULL)]


# COMPUTE PROXIMITY & SORT ORDER BY
geo_catalog[, Proximity := sqrt((AirportLat - MyLocation[1, Lat])^2 + (AirportLon - MyLocation[1, Lon])^2)]
geo_catalog <- geo_catalog[order(Proximity)]
setkey(geo_catalog, 'Proximity')

  
# ASSIGNING CLOSEST AIRPORT PARAMETERS TO VARIABLES
ClosestContinentName <- geo_catalog[1, ContinentName]
ClosestCountryName   <- geo_catalog[1, CountryName]
ClosestCityName      <- geo_catalog[1, CityName]
ClosestAirportName   <- geo_catalog[1, AirportName]


shinyServer(function(input, output) {
      
  # ASSIGN CHOSEN SUBSETS TO VARIABLES 
  # In this case it is necessary to call result variables in filtering instead of the call of input method)
  FilteredCountryNames <- reactive({ return( geo_catalog[ContinentName == ContinentNameVar(), sort(unique(CountryName), decreasing = FALSE)] ) })
  FilteredCityNames    <- reactive({ return( geo_catalog[CountryName == CountryNameVar(), sort(unique(CityName), decreasing = FALSE)] ) })
  FilteredAirportNames <- reactive({ return( geo_catalog[CityName == CityNameVar(), sort(unique(AirportName), decreasing = FALSE)] ) })
  
  
  # RENDERING DATE RANGE SELECTOR UI OF DEPARTURE TIME
  output$DepDatesSelector       <- renderUI({ dateRangeInput(inputId = 'DepDates', 
                                                             label = h5('Date of departure should be somewhere between:'),
                                                             separator = 'and',
                                                             weekstart = 1,
                                                             min = Sys.Date(),
                                                             start = Sys.Date(),
                                                             end = Sys.Date() + 2)
                                             })
  # RENDERING NUMBER INPUT BOX UI OF DURATION DAYS
  output$DurationSelector       <- renderUI({ sliderInput(inputId = 'Duration', 
                                                          label = h5('Duration in days'), 
                                                          min = 0,
                                                          max = 21,
                                                          value = 3,
                                                          step = 1)
                                             })
  # RENDERING SET OF RADIO BUTTONS UI FOR ADJUST IF WEEKEND DAY SHOULD BE INCLUDED (FROM SERVER SIDE)
  output$IncWedSelector         <- renderUI({ radioButtons(inputId = 'IncWed', 
                                                           label = h5('Including weekend day(s)'),
                                                           choices = list('yes' = TRUE, 
                                                                          'no' = FALSE), 
                                                           selected = TRUE)
                                             })
  # RENDERING SELECT BOX UI FOR CHOOSING CONTINENT (FROM SERVER SIDE)
  output$ContinentNameSelector  <- renderUI({ selectInput(inputId = 'ContinentName', 
                                                          label = h5('Select continental area of departure'), 
                                                          choices = geo_catalog[, sort(unique(ContinentName), decreasing = FALSE)],
                                                          selected = ClosestContinentName,
                                                          selectize = TRUE)
                                             })   
  # RENDERING SELECT BOX UI FOR CHOOSING COUNTRY (FROM SERVER SIDE)
  output$CountryNameSelector    <- renderUI({ selectInput(inputId = 'CountryName', 
                                                          label = h5('Select country of departure'), 
                                                          choices = FilteredCountryNames(),
                                                          selected = ClosestCountryName,
                                                          selectize = TRUE)
                                             })
  # RENDERING SELECT BOX UI FOR CHOOSING CITY (FROM SERVER SIDE)
  output$CityNameSelector       <- renderUI({ selectInput(inputId = 'CityName', 
                                                          label = h5('Select city of departure'), 
                                                          choices = FilteredCityNames(),
                                                          selected = ClosestCityName,
                                                          selectize = TRUE)
                                             })
  # RENDERING SELECT BOX UI FOR CHOOSING AIRPORT (FROM SERVER SIDE)
  output$AirportNameSelector    <- renderUI({ selectInput(inputId = 'AirportName', 
                                                          label = h5('Select airport of departure'), 
                                                          choices = FilteredAirportNames(),
                                                          selected = ClosestAirportName,
                                                          selectize = TRUE)
                                             })
  # RENDERING SET OF RADIO BUTTONS UI FOR SETTING DISTANCE (FROM SERVER SIDE)
  output$DistanceSelector       <- renderUI({ radioButtons(inputId = 'Distance', 
                                                           label = h5('Distance'),
                                                           choices = list('national' = 1, 
                                                                          'international' = 2,
                                                                          'intercontinental' = 3), 
                                                           selected = 2)
                                             })
  # RENDERING SELECT BOX UI FOR CHOOSING AIRPORT (FROM SERVER SIDE)
  output$DirectionsSelector     <- renderUI({ selectInput(inputId = 'Directions', 
                                                          label = h5('Select travel direction(s)'), 
                                                          choices = c('North', 'South', 'East', 'West'),
                                                          multiple = TRUE,
                                                          selectize = TRUE)
                                             })
  
  
  # ASSIGN CHOSEN VALUES TO VARIABLES
  FromDepDateVar             <- reactive({ return(input$DepDates[1]) })
  ToDepDateVar               <- reactive({ return(input$DepDates[2]) })
  DurationVar                <- reactive({ return(input$Duration) }) # strictly speaking it is not necessary
  IncWedVar                  <- reactive({ return(input$IncWed) }) # strictly speaking it is not necessary
  ContinentNameVar           <- reactive({ return(input$ContinentName) }) # It is necessary!!!
  CountryNameVar             <- reactive({ return(input$CountryName) }) # It is necessary!!!
  CityNameVar                <- reactive({ return(input$CityName) }) # It is necessary!!!
  AirportNameVar             <- reactive({ return(input$AirportName) }) # strictly speaking it is not necessary
  AirportIdVar               <- reactive({ return(geo_catalog[ContinentName == ContinentNameVar()
                                                            & CountryName == CountryNameVar()
                                                            & CityName == CityNameVar()
                                                            & AirportName == AirportNameVar()
                                                            , AirportId][1]) })
  AirportLatitude            <- reactive({ return(geo_catalog[AirportId == AirportIdVar(), AirportLat]) })
  AirportLongitude           <- reactive({ return(geo_catalog[AirportId == AirportIdVar(), AirportLon]) })
  DistanceVar                <- reactive({ return(input$Distance) }) # strictly speaking it is not necessary
  NorthVar                   <- reactive({ return(as.numeric(if ('North' %in% input$Directions) {1} else {0})) })
  SouthVar                   <- reactive({ return(as.numeric(if ('South' %in% input$Directions) {1} else {0})) })
  PolesVar                   <- reactive({ return(as.numeric(NorthVar() + SouthVar())) })
  EastVar                    <- reactive({ return(as.numeric(if ('East'  %in% input$Directions) {1} else {0})) })
  WestVar                    <- reactive({ return(as.numeric(if ('West'  %in% input$Directions) {1} else {0})) })
  SunwalkVar                 <- reactive({ return(as.numeric(EastVar() + WestVar())) })
  DistanceFilteredGeoCatalog <- reactive({ return(if (input$Distance == 1) { geo_catalog[CountryName == CountryNameVar() & AirportId !=AirportIdVar(), ] } 
                                                  else { if (input$Distance == 3) { geo_catalog[ContinentName != ContinentNameVar() | AirportId == AirportIdVar(), ] } 
                                                         else { geo_catalog[ContinentName == ContinentNameVar() & AirportId != AirportIdVar(), ] } }) })
  NorthFilteredGeoCatalog    <- reactive({ return(if (NorthVar() == 1) { DistanceFilteredGeoCatalog()[AirportLat >= AirportLatitude(), ] } else { DistanceFilteredGeoCatalog()[0, ] }) })
  SouthFilteredGeoCatalog    <- reactive({ return(if (SouthVar() == 1) { DistanceFilteredGeoCatalog()[AirportLat <= AirportLatitude(), ] } else { DistanceFilteredGeoCatalog()[0, ] }) })
  EastFilteredGeoCatalog     <- reactive({ return(if (EastVar()  == 1) { DistanceFilteredGeoCatalog()[AirportLon >= AirportLongitude(), ] } else { DistanceFilteredGeoCatalog()[0, ] }) })
  WestFilteredGeoCatalog     <- reactive({ return(if (WestVar()  == 1) { DistanceFilteredGeoCatalog()[AirportLon <= AirportLongitude(), ] } else { DistanceFilteredGeoCatalog()[0, ] }) })
  FilteredGeoCatalog         <- reactive({ return(if (PolesVar() != 1 & SunwalkVar() != 1) { DistanceFilteredGeoCatalog()[, ] }
                                                  else { if (PolesVar() == 1 & SunwalkVar() != 1) { bind_rows(NorthFilteredGeoCatalog()[, ], SouthFilteredGeoCatalog()[, ]) }
                                                         else { if (PolesVar() != 1 & SunwalkVar() == 1) { bind_rows(EastFilteredGeoCatalog()[, ], WestFilteredGeoCatalog()[, ]) }
                                                                else { if (NorthVar() == 1 & EastVar() == 1) { merge(NorthFilteredGeoCatalog()[, ], EastFilteredGeoCatalog()[, ], by = 'AirportId', all = FALSE) } 
                                                                       else { if (NorthVar() == 1 & WestVar() == 1) { merge(NorthFilteredGeoCatalog()[, ], WestFilteredGeoCatalog()[, ], by = 'AirportId', all = FALSE) }
                                                                              else { if (SouthVar() == 1 & EastVar() == 1) { merge(SouthFilteredGeoCatalog()[, ], EastFilteredGeoCatalog()[, ], by = 'AirportId', all = FALSE) }
                                                                                     else { merge(SouthFilteredGeoCatalog()[, ], WestFilteredGeoCatalog()[, ], by = 'AirportId', all = FALSE) }}}}}}) })
                                                    


                                                        
  # RENDERING RESULT VARIABLES FOR VERIFICATION PURPOSES
  output$ChosenDepDates1    <- renderPrint({ input$goButton 
    isolate(paste('departure date - from: ', FromDepDateVar(), sep = '')) })
  output$ChosenDepDates2    <- renderPrint({ input$goButton
    isolate(paste('departure date - to: ', ToDepDateVar(), sep = '')) })
  output$ChosenDuration     <- renderPrint({ input$goButton 
    isolate(paste('duration in days: ', DurationVar(), sep = '')) })
  output$ChosenIncWed       <- renderPrint({ input$goButton 
    isolate(paste('including weekend day(s): ', IncWedVar(), sep = '')) })  
  output$ChosenContinent    <- renderPrint({ input$goButton 
    isolate(paste('chosen continental area of departure: ', ContinentNameVar(), sep = '')) })
  output$ChosenCountry      <- renderPrint({ input$goButton 
    isolate(paste('chosen country of departure: ', CountryNameVar(), sep = '')) })
  output$ChosenCity         <- renderPrint({ input$goButton 
    isolate(paste('chosen city of departure: ', CityNameVar(), sep = '')) })
  output$ChosenAirportName  <- renderPrint({ input$goButton 
    isolate(paste('chosen airport name of departure: ', AirportNameVar(), sep = '')) })
  output$ChosenAirportId    <- renderPrint({ input$goButton 
    isolate(paste('chosen airport id of departure: ', AirportIdVar(), sep = '')) })
  output$ChosenDistance     <- renderPrint({ input$goButton 
    isolate(paste('chosen distance: ', DistanceVar(), sep = '')) })
  output$ChosenNorth        <- renderPrint({ input$goButton 
    isolate(paste('to North: ', NorthVar(), sep = '')) })
  output$ChosenSouth        <- renderPrint({ input$goButton 
    isolate(paste('to South: ', SouthVar(), sep = '')) })
  output$ChosenEast         <- renderPrint({ input$goButton 
    isolate(paste('to East: ', EastVar(), sep = '')) })
  output$ChosenWest         <- renderPrint({ input$goButton 
    isolate(paste('to West: ', WestVar(), sep = '')) })
  output$FilteredGeoCatalog <- DT::renderDataTable({ input$goButton
    isolate(DT::datatable(FilteredGeoCatalog(), options = list(pageLength = 25))) })

})
