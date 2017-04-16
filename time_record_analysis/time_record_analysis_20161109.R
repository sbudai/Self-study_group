library(data.table)
library(XLConnect)
library(rio)
library(ggplot2)

setwd('./Self-study_group/time_record_analysis')
input <- data.table(readWorksheet(loadWorkbook('working_hours_report_20161019.xlsx'), sheet = '102016', header = TRUE))
summary(input)

input[is.na(User.name) == TRUE, User.name := paste('Noname User', User.id, sep = '_')]
input[, ':=' (No. = NULL, Door = NULL)]
input <- unique(input[, ])
input[, ':=' (counter = .N, min.Time = min(Time), max.Time = max(Time)), by=.(User.id, Date, IN.OUT)]
indt <- input[IN.OUT == 'IN' & Time == min.Time, .(User.id, User.name, Card.No, Date, min.Time)]
outdt <- input[IN.OUT == 'OUT' & Time == max.Time, .(User.id, User.name, Card.No, Date, max.Time)]

setkey(indt, User.id, User.name, Card.No, Date)
setkey(outdt, User.id, User.name, Card.No, Date)
output <- merge(indt, outdt, all = TRUE)

#output[, date.span := as.numeric(max(Date) - min(Date)) + 1, by = .(User.id, User.name, Card.No)]
output[, ':=' (min.Date = min(Date), max.Date = max(Date)), by = .(User.id, User.name, Card.No)]

# innentől a min és a max date-et kellene tovább vinni.
output[is.na(min.Time) == FALSE & is.na(max.Time) == FALSE, Time.diff := (max.Time - min.Time) / 60 / 60]
output[Time.diff < 0, Time.diff := NA]
output[Time.diff > 0, ':=' (avg.Time = mean(Time.diff), median.Time = median(Time.diff), right.days = .N), by = .(User.id, User.name, Card.No)]
output[is.na(right.days) == TRUE, right.days := 0]
output[, ':=' (avg.Time = round(avg.Time, digits = 2), median.Time = round(median.Time, digits = 2))]

wrongdt <- output[is.na(Time.diff) == TRUE, .N, by = .(User.id, User.name, Card.No, min.Date, max.Date)]
setnames(wrongdt, 'N', 'wrong.days')

output <- unique(output[right.days > 0, .(User.id, User.name, Card.No, avg.Time, median.Time, min.Date, max.Date, right.days)])
output <- output[wrongdt, on = .(User.id, User.name, Card.No, min.Date, max.Date)]
output[is.na(right.days) == TRUE, right.days := 0]
output[, date.span := as.numeric(max.Date - min.Date) + 1, by = .(User.id, User.name, Card.No)]
output[is.na(date.span) == FALSE, log.ratio := round((right.days + wrong.days) / date.span, 2)]

setkey(output, wrong.days, right.days, median.Time)

rm(input, indt, outdt, wrongdt)
export(output, 'working_hours_report_20161019_results.RData')

ggplot(data = output, 
       aes(x = as.factor(User.name), 
           y = as.numeric(median.Time), 
           size = as.numeric(right.days))) +
  geom_point(aes(alpha = as.numeric(log.ratio)), 
             shape = 13, 
             stroke = 1, 
             na.rm = TRUE, 
             col = 'blue') + 
  coord_flip() +
  scale_size_continuous(range = c(0, 20),
                        breaks = c(1, 20, 40), 
                        labels = c('1', '20', '40'),
                        guide = guide_legend(title = 'Nr of Fully\nAdministered\nDays',
                                             keywidth = 10,
                                             keyheight = 40,
                                             default.unit = 'point')) +
  guides(shape = guide_legend(override.aes = list(size = 50))) +
  scale_alpha_continuous(range = c(0, 1),
                         breaks = c(.50, .75, 1.0), 
                         labels = c('50%', '75%', '100%'),
                         guide = guide_legend(title = 'Ratio of\nLogged\nDays',
                                              keywidth = 10,
                                              keyheight = 40, 
                                              override.aes = list(size = 10, 
                                                                  shape = 16),
                                              default.unit = 'point')) +
  scale_y_continuous(limits = c(0, 11),
                     minor_breaks = seq(0 , 11, 1), 
                     breaks = seq(0, 10, 2)) +
  geom_hline(yintercept = 8, color = 'red') +
  ggtitle('Median Daily Working Hours') +
  theme_bw() +
  theme(axis.title.x = element_blank()) +
  theme(axis.title.y = element_blank()) 


  
