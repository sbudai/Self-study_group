library(data.table)

comp_list = data.table(rbind(read.csv('http://www.nasdaq.com/screening/companies-by-name.aspx?letter=0&exchange=nasdaq&render=download', stringsAsFactors = F), read.csv('http://www.nasdaq.com/screening/companies-by-name.aspx?letter=0&exchange=nyse&render=download', stringsAsFactors = F)))

#cleaning
comp_list <- comp_list[, -c(5, 8, 9), with = F]
comp_list <- comp_list[-grep('\\^', comp_list$Symbol), ]
comp_list <- comp_list[duplicated(Name) == F, ]
comp_list[MarketCap == '/a', MarketCap := NA]
comp_list[MarketCap == 'n/a', MarketCap := NA]
comp_list[, MarketCap := substr(MarketCap, 2, nchar(MarketCap))]
comp_list[!is.na(LastSale), LastSale := as.numeric(LastSale)]

for (i in 1:nrow(comp_list)) {
  if (endsWith(comp_list[i, MarketCap], 'B') & !is.na(comp_list[i, MarketCap])) {
    comp_list[i, MarketCap := as.numeric(substr(MarketCap, 1, nchar(MarketCap)-1))]
  }
  if (endsWith(comp_list[i, MarketCap], 'M') & !is.na(comp_list[i, MarketCap])) {
    comp_list[i, MarketCap := as.numeric(substr(MarketCap, 1, nchar(MarketCap)-1))/1000]
  }
}

first.date <- '1900-01-01'
last.date <- Sys.Date()

changedir <- paste('cd ', getwd(), sep = '')
changedir
reach <- paste('python3 parhuzamos_adat_leszedo.py', paste(getwd(), 'data_', last.date, '.csv', sep = ''), first.date, last.date, sep = ' ')
reach

system(paste(changedir, reach, sep = ' && '))


system('rm -f history_data.csv')
system('cat ./data/*.csv >> history_data.csv')
system('rm -rf ./data')

data <- fread('history_data.csv', stringsAsFactors = F, sep = ',')

data <- data[Date != 'Date', ]
data[, Date := as.Date(Date)]
ExchLaunch <- data[, list(belepes = min(Date)) , by = 'ticker']

setkey(ExchLaunch, 'ticker')
setkey(comp_list, 'Symbol')
comp_list <- comp_list[ExchLaunch]

records <- seq(from = 1, to = nrow(data), by = 5)
data <- data[records, ]

data[, Close := as.numeric(Close)]
data <- data[, change := (Close/shift(Close, 1L, type = 'lag')-1)*100, by = ticker]
data <- data[complete.cases(data)]

res <- data[, list(atlag_vlat = mean(change, na.rm = T)), by = ticker]

result <- data[, list('d1_avg' = round(mean(change), 2), 
                      'd1_min' = round(min(change), 2), 
                      'd1_max' = round(max(change), 2),
                      'd1_median' = median(change), 
                      'number_of_records' = .N, 
                      'positive' = sum(ifelse(change > 0, 1, 0))/.N,
                      'negative' = sum(ifelse(change < 0 , 1, 0))/.N, 
                      'first_quarter' = quantile(change, 0.25), 
                      'second_quarter' = quantile(change, 0.5),
                      'third_quarter' = quantile(change, 0.75), 
                      'ninety' = quantile(change, 0.9))
               , by = ticker]

results <- merge(result, comp_list, by.x = 'ticker', by.y = 'Symbol', all.x = T)

final_data <- results[, list('number_of_records' = .N,
                             'average_d1' = mean(d1_avg), 
                             'average_median'= mean(d1_median))
                      , by=.(Sector, industry)]

y_2016 <- setorder(rbind(data[, .SD[which.min(Date)], by = ticker],
                         data[, .SD[which.max(Date)], by = ticker]),
                   ticker)

change <- NULL

for (i in 1:nrow(y_2016)) {
  change <-c(change, y_2016[i+1, Close] / y_2016[i, Close]) 
}

y_2016$change <- change

for (i in seq(0, nrow(y_2016), by = 2)) {
  y_2016[i, change := 0]
}

year2016 <- y_2016[change != 0, ]

year2016_res <- merge(year2016, comp_list, by.x = 'ticker', by.y = 'Symbol', all.x = T)

y_2016_rep <- year2016_res[, list(change = mean(change, na.rm = T),
                                  count = .N), 
                           by = Sector]

y_2016_rep_by_ind <- year2016_res[, list(change = mean(change, na.rm = T), 
                                         count = .N, 
                                         min_change = min(change, na.rm = T), 
                                         max_vat = max(change, na.rm = T), 
                                         median_valt = median(change, na.rm = T))
                                   ,by = c('Sector', 'industry')]

p <- plot_ly(y_2016_rep_by_ind, 
             x = ~year, 
             y = ~Number_of_companies, 
             color = ~industry) %>%
       add_lines() %>%
       layout(title = i)
p

data <- data[, change2:=(Close/shift(Close, 2L, type = 'lag')-1)*100, by = ticker]
data <- data[, change3:=(Close/shift(Close, 3L, type = 'lag')-1)*100, by = ticker]
data <- data[, change5:=(Close/shift(Close, 5L, type = 'lag')-1)*100, by = ticker]
data <- data[, change0:=(Close/shift(Close, 10L, type = 'lag')-1)*100, by = ticker]

export(data, 'nasdaq_stock_data.RData')
