
#### function: plot an interactiv history chart from the subset of shares
PlotHistory <- function(TickersSubset, FromDate, ToDate) {
  
  ## manipulating from date
  tmp <- paste('0', as.character(as.numeric(substr(FromDate, 1, 2))-1), sep = '')
  FromMonth <- ifelse(nchar(tmp) == 3, substr(tmp, 2, 3), tmp)
  FromDay <- substr(FromDate, 3, 4)
  FromYear <- substr(FromDate, 5, 8)
  
  ## manipulating to date
  if (ToDate == 0) {
    ToMonth <- as.character(as.numeric(format(Sys.Date(), "%m"))-1)
    ToMonth <- ifelse(ToMonth <10, paste('0', ToMonth, sep = ''), ToMonth)
    ToDay <- format(Sys.Date(), "%d")
    ToYear <- format(Sys.Date(), "%Y")
  } else {
    tmp <- paste('0', as.character(as.numeric(substr(ToDate, 1, 2))-1), sep = '')
    ToMonth <- ifelse(nchar(tmp) == 3, substr(tmp, 2, 3), tmp)
    ToDay <- substr(ToDate, 3, 4)
    ToYear <- substr(ToDate, 5, 8)  
  }
  
  ## define the URLs
  addstock_datas <- paste('http://real-chart.finance.yahoo.com/table.csv?s=',
                          TickersSubset, 
                          '&a=', 
                          FromMonth,
                          '&b=', 
                          FromDay, 
                          '&c=', 
                          FromYear,
                          '&d=', 
                          ToMonth, 
                          '&e=', 
                          ToDay, 
                          'to&f=', 
                          FromYear,
                          '&g=d&ignore=.csv', 
                          sep = '')
  
  ## subsetting using lapply instead of a loop: faster
  SubsetDt <- lapply(seq(addstock_datas), function(x) {
                temp <- data.table(read.csv(addstock_datas[x], stringsAsFactors = F))
                temp <- data.table(temp[nrow(temp):1, ])
                temp$ticker <- TickersSubset[x]
                temp
              })
  SubsetDt <- do.call('rbind', SubsetDt)

  ## computing share price changes history based on closing price
  setorder(SubsetDt, ticker, Date)
  for (i in TickersSubset) {
    baseline <- SubsetDt[ticker == i, Close][1]
    SubsetDt[ticker == i, change := (Close/baseline-1)*100]
  }
  
  ## plot(ly)
  p <- plot_ly(SubsetDt, 
               x = ~Date, 
               y = ~change, 
               color = ~ticker) %>% add_lines()
  return(p)
}