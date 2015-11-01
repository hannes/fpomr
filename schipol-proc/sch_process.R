require(jsonlite)
library(stringr)


complaints <- read.csv("fb_splits/part-2015-10.tsv", sep = "\t", header = F, stringsAsFactors = F)
colnames(complaints) <- c("id", "time", "text", "time-short", "month")
complaints_with_flight_nr <- complaints[grepl("KL[0-9]+", complaints$text) |
                                        grepl("KL [0-9]+", complaints$text), ]

for (i in 2:9) {
  compl <- read.csv(paste("fb_splits/part-2015-0", i, ".tsv", sep = ""),
                sep = "\t", header = F, stringsAsFactors = F)
  colnames(compl) <- c("id", "time", "text", "time-short", "month")
  compl <- compl[grepl("KL[0-9]+", compl$text) |
                   grepl("KL [0-9]+", compl$text), ]
  
  complaints_with_flight_nr <- rbind(complaints_with_flight_nr,
                                     compl)
  
}

regex_day_list <- c("[0-3][0-9]th",
                    "[0-3]1st",
                    " [1-9]th",
                    " 1st",
                    "[0-3][0-9]",
                    " [1-9]")
regex_list <- c()

for (i in 1:12) {
  regex_list <- append(regex_list, paste(regex_day_list, tolower(month.abb[i])))
  regex_list <- append(regex_list, paste(regex_day_list, "of", tolower(month.abb[i])))
}

regex_list <- append(regex_list, paste(regex_day_list, "-[0-3][0-9]", sep = ""))
regex_list <- append(regex_list, paste(regex_day_list, "\\.[0-3][0-9]", sep = ""))
regex_list <- append(regex_list, paste(regex_day_list, "/[0-3][0-9]", sep = ""))
regex_list <- append(regex_list, paste(regex_day_list, "-[0-9] ", sep = ""))
regex_list <- append(regex_list, paste(regex_day_list, "\\.[0-9] ", sep = ""))
regex_list <- append(regex_list, paste(regex_day_list, "/[0-9] ", sep = ""))

date_formats <- c(
  "%dth %b %Y",
  "%dth of %b %Y", 
  "%d %b %Y", 
  "%d of %b %Y",
  "%dst %b %Y",
  "%dst of %b %Y",
  "%d-%m %Y",
  "%d.%m %Y",
  "%d/%m %Y",
  "%m-%d %Y",
  "%m.%d %Y",
  "%m/%d %Y"
)

complaints_with_flight_nr$text <- tolower(complaints_with_flight_nr$text)
complaints_with_flight_nr$pred_date <- rep("", length(complaints_with_flight_nr[, 1]))
complaints_with_flight_nr$flight_no <- rep("", length(complaints_with_flight_nr[, 1]))

for (i in 1:length(complaints_with_flight_nr[, 1])) {
  complaints_with_flight_nr$flight_no[i] <- str_extract(complaints_with_flight_nr$text[i], "kl[0-9]+")
  if (is.na(complaints_with_flight_nr$flight_no[i])) {
    complaints_with_flight_nr$flight_no[i] <- str_extract(complaints_with_flight_nr$text[i], "kl [0-9]+")
    complaints_with_flight_nr$flight_no[i] <- paste("KL",
                                                    substr(complaints_with_flight_nr$flight_no[i], 4, 7),
                                                    sep = "")
  }
  complaints_with_flight_nr$flight_no[i] <- toupper(complaints_with_flight_nr$flight_no[i])
  
  for (j in 1:length(regex_list)) {
    if (grepl(regex_list[j], complaints_with_flight_nr$text[i])) {
      poss_date <- str_trim(str_extract(complaints_with_flight_nr$text[i], regex_list[j]))
      poss_date <- paste(poss_date, 2015)
      
      date_var <- ""
      found <- F
      for (k in 1:length(date_formats)) {
        if (!is.na(as.Date(poss_date, date_formats[k]))) {
          date_var <- as.Date(poss_date, date_formats[k])
          found <- T
        }
      }
      
      if (found == F) {
        print(poss_date)
      }
      else {
        if (complaints_with_flight_nr$pred_date[i] == "")
          complaints_with_flight_nr$pred_date[i] <- as.character(date_var)
        else
          complaints_with_flight_nr$pred_date[i] <- paste(complaints_with_flight_nr$pred_date[i],
                                                     as.character(date_var),
                                                     sep = ",")
      }
    }
  }
}


write.table(complaints_with_flight_nr, "complaints_with_flight_nr.csv", sep=";")
save(complaints_with_flight_nr, file = "complaints_flight_nr.Rdata")

######################### match with flights #########################

files <- list.files(path = "data2/", pattern = "sch_oct")
data <- data.frame(stringsAsFactors = F)

for (i in 1:length(files)) {
  print(paste("PROCESSING FILE", i, "OUT OF", length(files)))
  
  data_file <- paste("data2", files[i], sep = "/")
  data_aux <- fromJSON(data_file, flatten = T)$flights
  data_aux <- data_aux[grepl("KL", data_aux$flightName ), ]
  
  colnames(data_aux) <- c("id", "flightName", "scheduleDate", "flightDirection", "flightNumber", 
                          "prefixIATA", "prefixICAO", "scheduleTime", "serviceType", "mainFlight", 
                          "codeshares", "estimatedLandingTime", "actualLandingTime", "publicEstimatedOffBlockTime", 
                          "actualOffBlockTime", "publicFlightState", "terminal", "gate", 
                          "baggageClaim", "expectedTimeOnBelt", "checkinAllocations", "transferPositions", 
                          "aircraftType", "aircraftRegistration", "expectedTimeGateOpen", 
                          "expectedTimeBoarding", "expectedTimeGateClosing", "schemaVersion", 
                          "destinations")
  
  rownames(data_aux) <- NULL
  rownames(data) <- NULL
  
  data <- rbind(data, data_aux)
}

airport_codes <- read.csv("iata-airport-codes/airport-codes.csv")

