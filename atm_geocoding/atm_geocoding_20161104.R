library(ggmap)
library(data.table)

adat = data.table(read.csv('atm_list.csv', header = T, sep = ',', encoding = 'utf-8', stringsAsFactors = F))

third_section <- adat[, ][4401:6800]
third_section[, ':=' (lon = geocode(cimek)[[1]], lat = geocode(cimek)[[2]])]

write.csv(third_section, 'atm_list_geocoded_third_section.csv')

# great work