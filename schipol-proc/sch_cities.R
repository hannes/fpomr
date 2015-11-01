require(jsonlite)
library(stringr)

complaints <- read.csv("fb_splits/part-2015-10.tsv", sep = "\t", header = F, stringsAsFactors = F)
colnames(complaints) <- c("id", "time", "text", "time-short", "month")
complaints$text <- tolower(complaints$text)
complaints$city <- rep("", length(complaints[, 1]))

airport_codes <- read.csv("iata-airport-codes/airport-codes.csv", stringsAsFactors = F)
airport_codes$city <- tolower(airport_codes$city)

for (i in 1:length(airport_codes$city)) {
  found <- grepl(airport_codes$city[i], complaints$text)
  
  print(paste("PROCESSING", airport_codes$city[i]))
  
  for (j in 1:length(complaints[, 1])) {
    if (found[j] == T) {
      # print(paste(airport_codes$city[i], complaints$text[j], sep = " :: "))
      if (complaints$city[j] == "") complaints$city[j] <- airport_codes$city[i]
      else complaints$city[j] <- paste(complaints$city[j], airport_codes$city[i], sep = ",")
    }
  }
}

for (i in 2:9) {
  compl <- read.csv(paste("fb_splits/part-2015-0", i, ".tsv", sep = ""),
                    sep = "\t", header = F, stringsAsFactors = F)
  colnames(compl) <- c("id", "time", "text", "time-short", "month")
  
  complaints_with_flight_nr <- rbind(complaints_with_flight_nr,
                                     compl)
  
}