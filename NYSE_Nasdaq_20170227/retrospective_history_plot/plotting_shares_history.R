library(XML)
library(data.table)
library(plotly)
library(magrittr)

source('my_functions.R')

PlotHistory(TickersSubset = c('TSLA', 'GE', 'AMD', 'GOOGL'), 
            FromDate = '01012011', 
            ToDate = 0)
