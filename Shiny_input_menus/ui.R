# LOADING LIBRARIES
suppressPackageStartupMessages(library(shiny))
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(DT))

shinyUI(
  fluidPage(

    # ADDING APPLICATION TITLE TO UI
    titlePanel('Inspirational Flights'),
  
    fluidRow(
      
      # COMPOSING TIMING SECTION
      column(
        width = 4, 
        wellPanel(
        
          # SECTION HEADER
          h3('TIMING'),
          
          # DATE RANGE SELECTOR OF DEPARTURE TIME
          uiOutput('DepDatesSelector'), 

          # NUMBER INPUT BOX OF DURATION DAYS
          uiOutput('DurationSelector'), 

          # SET OF RADIO BUTTONS FOR ADJUST IF WEEKEND DAY SHOULD BE INCLUDED
          uiOutput('IncWedSelector')
          
          ) # wellPanel
      ), # column

      # COMPOSING FROM SECTION
      column(
        width = 3, 
        wellPanel(  
        
          # SECTION HEADER
          h3('FROM'),
          
          # DROP-DOWN SELECT BOX FOR CHOOSING CONTINENT
          uiOutput('ContinentNameSelector'),
      
          # DROP-DOWN SELECT BOX FOR CHOOSING COUNTRY
          uiOutput('CountryNameSelector'),
            
          # DROP-DOWN SELECT BOX FOR CHOOSING CITY
          uiOutput('CityNameSelector'),
      
          # DROP-DOWN SELECT BOX FOR CHOOSING AIRPORT
          uiOutput('AirportNameSelector')
        
        ) # wellPanel
      ), # column
      
      # COMPOSING TO SECTION
      column(
        width = 3, 
        wellPanel(
               
          # SECTION HEADER
          h3('TO'),
          
          # SET OF RADIO BUTTONS FOR SETTING DISTANCE
          uiOutput('DistanceSelector'),
          
          # SELECT BOX FOR CHOOSING AIRPORT
          uiOutput('DirectionsSelector')

        ) # wellPanel
      ), # column
      
      # COMPOSING TO SECTION
      column(
        width = 1,  
        offset = 0,

        # DISPLAYING GO BUTTON 
        # it may be placed in other panel as well
        actionButton(inputId = 'goButton', 
                     label = 'GO')
         
      ) # column
  
    ), # fluidRow


    # COMPOSING MAINPANEL SECTION
    mainPanel(
      
      h3('CHOSEN VALUES'),
      # DISPLAYING CHOSEN VALUES
      textOutput('ChosenDepDates1'),
      textOutput('ChosenDepDates2'),
      textOutput('ChosenDuration'),
      textOutput('ChosenIncWed'),
      textOutput('ChosenContinentName'),
      textOutput('ChosenCountryName'),
      textOutput('ChosenCityName'),
      textOutput('ChosenAirportName'),
      textOutput('ChosenAirportId'),
      textOutput('ChosenDistance'),
      textOutput('ChosenNorth'),
      textOutput('ChosenSouth'),
      textOutput('ChosenEast'),
      textOutput('ChosenWest'),
      
      h3('FILTERED POSSIBLE DESTINATIONS'),
      DT::dataTableOutput('FilteredGeoCatalog')
      
    ) # mainPanel
  
  ) # FluidPage
) # shinyUI

