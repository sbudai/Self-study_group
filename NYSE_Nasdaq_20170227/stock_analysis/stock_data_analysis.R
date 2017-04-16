library(data.table)
library(rio)
library(plotly)

data_all <- rbind(data.table(import('nasdaq_stock_data.RData')), data.table(import('nyse_full_hist.RData')))
comp_list <- rbind(data.table(import('nasdaq_comp_list.RData')), data.table(import('nyse_comp_list.RData')))

#calculating legs  1, 2, 3, 5, 10 days by tickers
data_all <- data_all[, change1 := round((Close/shift(Close, 1L, type = 'lag')-1)*100, 2), by = ticker]
data_all <- data_all[, change2 := round((Close/shift(Close, 2L, type = 'lag')-1)*100, 2), by = ticker]
data_all <- data_all[, change3 := round((Close/shift(Close, 3L, type = 'lag')-1)*100, 2), by = ticker]
data_all <- data_all[, change5 := round((Close/shift(Close, 5L, type = 'lag')-1)*100, 2), by = ticker]
data_all <- data_all[, change10 := round((Close/shift(Close, 10L, type = 'lag')-1)*100, 2), by = ticker]

data_all<- data_all[complete.cases(data_all)]


# select_list
# my_list <- comp_list[Sector == 'Finance', Symbol ]

# data <- data_all[ticker %in% my_list, ]


result <- data_all[, list('d1_avg' = mean(change1), 
                          'd1_min' = min(change1), 
                          'd1_max' = max(change1), 
                          'd1_median' = median(change1), 
                          'number_of_records' = .N, 
                          'positive' = sum(ifelse(change1 < 0, 1, 0)),
                          'negative'= sum(ifelse(change1 > 0, 1, 0)), 
                          'first_quarter' = quantile(change1, 0.25), 
                          'second_quarter' = quantile(change1, 0.5),
                          'third_quarter' = quantile(change1, 0.75), 
                          'ninety' =quantile(change1, 0.9),
                          'd1plus5' = sum(ifelse(change1 > 5, 1, 0)), 
                          'd1minus5'= sum(ifelse(change1 < (-5), 1, 0)),
                          'd1plus10' = sum(ifelse(change1 > 10, 1, 0)), 
                          'd1minus10'= sum(ifelse(change1 < (-10), 1, 0)),
                          'd1plus20' = sum(ifelse(change1 > 20, 1, 0)), 
                          'd1minus20'= sum(ifelse(change1 < (-20), 1, 0)),
                          'd1plus50' = sum(ifelse(change1 > 50, 1, 0)), 
                          'd1minus50'= sum(ifelse(change1 < (-50), 1, 0)),
                          'd1plus100' = sum(ifelse(change1 > 100, 1, 0)), 
                          'd1minus90'= sum(ifelse(change1 < (-90), 1, 0)),
                          'd2plus5' = sum(ifelse(change2 > 5, 1, 0)), 
                          'd2minus5'= sum(ifelse(change2 < (-5), 1, 0)),
                          'd2plus10' = sum(ifelse(change2 > 10, 1, 0)), 
                          'd2minus10'= sum(ifelse(change2 < (-10), 1, 0)),
                          'd2plus20' = sum(ifelse(change2 > 20, 1, 0)), 
                          'd2minus20'= sum(ifelse(change2 < (-20), 1, 0)),
                          'd2plus50' = sum(ifelse(change2 > 50, 1, 0)), 
                          'd2minus50'= sum(ifelse(change2 < (-50), 1, 0)),
                          'd2plus100' = sum(ifelse(change2 > 100, 1, 0)), 
                          'd2minus90'= sum(ifelse(change2 < (-90), 1, 0)),
                          'd3plus5' = sum(ifelse(change3 > 5, 1, 0)), 
                          'd3minus5'= sum(ifelse(change3 < (-5), 1, 0)),
                          'd3plus10' = sum(ifelse(change3 > 10, 1, 0)), 
                          'd3minus10'= sum(ifelse(change3 < (-10), 1, 0)),
                          'd3plus20' = sum(ifelse(change3 > 20, 1, 0)), 
                          'd3minus20'= sum(ifelse(change3 < (-20), 1, 0)),
                          'd3plus50' = sum(ifelse(change3 > 50, 1, 0)), 
                          'd3minus50'= sum(ifelse(change3 < (-50), 1, 0)),
                          'd3plus100' = sum(ifelse(change3 > 100, 1, 0)), 
                          'd3minus90'= sum(ifelse(change3 < (-90), 1, 0)), 
                          'd5plus5' = sum(ifelse(change5 > 5, 1, 0)), 
                          'd5minus5'= sum(ifelse(change5 < (-5), 1, 0)),
                          'd5plus10' = sum(ifelse(change5 > 10, 1, 0)), 
                          'd5minus10'= sum(ifelse(change5 < (-10), 1, 0)),
                          'd5plus20' = sum(ifelse(change5 > 20, 1, 0)), 
                          'd5minus20'= sum(ifelse(change5 < (-20), 1, 0)),
                          'd5plus50' = sum(ifelse(change5 > 50, 1, 0)), 
                          'd5minus50'= sum(ifelse(change5 < (-50), 1, 0)),
                          'd5plus100' = sum(ifelse(change5 > 100, 1, 0)), 
                          'd5minus90'= sum(ifelse(change5 < (-90), 1, 0)), 
                          'd10plus5' = sum(ifelse(change10 > 5, 1, 0)), 
                          'd10minus5'= sum(ifelse(change10 < (-5), 1, 0)),
                          'd10plus10' = sum(ifelse(change10 > 10, 1, 0)), 
                          'd10minus10'= sum(ifelse(change10 < (-10), 1, 0)),
                          'd10plus20' = sum(ifelse(change10 > 20, 1, 0)), 
                          'd10minus20'= sum(ifelse(change10 < (-20), 1, 0)),
                          'd10plus50' = sum(ifelse(change10 > 50, 1, 0)), 
                          'd10minus50'= sum(ifelse(change10 < (-50), 1, 0)),
                          'd10plus100' = sum(ifelse(change10 > 100, 1, 0)), 
                          'd10minus90'= sum(ifelse(change10 < (-90), 1,0))
                          ), by = ticker]

setDT(result)

result[, posperneg := positive/negative]

rio::export(result, 'results.RData')





