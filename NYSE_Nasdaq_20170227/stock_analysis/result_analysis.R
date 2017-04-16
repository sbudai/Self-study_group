library(rio)
library(data.table)

comp_list <- rbind(data.table(import('nasdaq_comp_list.RData')), data.table(import('nyse_comp_list.RData')))
stock_data<- data.table(import('results.RData'))
stock_data[, posperneg := positive/negative]

data <- merge(stock_data, comp_list, by.x = 'ticker', by.y = 'Symbol', all.x = T)
data <- data[, c(1, 63:69, 2:62), with = F]
str(data)

#export to shiny
export(data, 'shinydata.Rdata')

BigLoose <- data[d1_min < -60, ]
BigGain <- data[d1_max > 100, ]
TooYoung <- data[number_of_records < 200, ]

MyData <- data[!ticker %in% BigLoose$ticker, ]
MyData <- MyData[!ticker %in% BigGain$ticker, ]
MyData <- MyData[!ticker %in% TooYoung$ticker, ]

final_data <- MyData[, list('number_of_records' = .N,
                            'average_d1' = mean(d1_avg), 
                            'average_median'= mean(d1_median))
                     , by=.(Sector, industry)]

