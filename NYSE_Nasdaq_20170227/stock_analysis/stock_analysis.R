library(data.table)
library(rio)
library(plotly)


adat <- rbind(data.table(import('nasdaq_stock_data.RData')), data.table(import('nyse_full_hist.RData')))
comp_list <- rbind(data.table(import('nasdaq_comp_list.RData')), data.table(import('nyse_comp_list.RData')))

ScannedYear <- 2016
y_2016 <- data.table(setorder(rbind(adat[year(Date) == ScannedYear , .SD[which.min(Date)], by = ticker], adat[year(Date) == ScannedYear, .SD[which.max(Date)], by = ticker]), ticker))

change <-NULL
for (i in 1:nrow(y_2016)) {
  change <- c(change, y_2016[i+1, Close] / y_2016[i, Close]) 
}
y_2016$change <- change

for (i in seq(0, nrow(y_2016), by = 2)) {
  y_2016[i, change := 0]
}

year2016 <- y_2016[change != 0, ]

year2016_res <- merge(year2016, comp_list, by.x = 'ticker', by.y = 'Symbol', all.x = T)

y_2016_rep <- year2016_res[,list(change = mean(change, na.rm = T), count=.N), by = Sector]

y_2016_rep_by_ind <- year2016_res[, list(change = mean(change, na.rm=T), 
                                         count = .N, 
                                         min_change = min(change, na.rm = T), 
                                         max_vat = max(change, na.rm = T), 
                                         median_valt = median(change,na.rm = T)),
                                  by = c('Sector', 'industry')]

p <- plot_ly(y_2016_rep_by_ind, 
             x = ~year, 
             y = ~Number_of_companies, 
             color = ~industry) %>%
     add_lines() %>%
     layout(title = i)

p


