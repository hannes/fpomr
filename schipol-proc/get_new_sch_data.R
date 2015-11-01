load("schipol_klm_data.Rdata")

require(jsonlite)
library(stringr)

files <- list.files(path = "data2/", pattern = "sch_oct")
new_data <- data.frame(stringsAsFactors = F)

for (i in 1:181) {
  print(paste("PROCESSING FILE", i, "OUT OF", 181))
  
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
  rownames(new_data) <- NULL
  
  new_data <- rbind(new_data, data_aux)
}

new_data <- new_data[!new_data$id %in% data$id, ]
data <- rbind(data, new_data)
save(data, file="schipol_klm_data_new.Rdata")


############# get comments #############

load("complaints_flight_nr.Rdata")

new_complaints <- read.csv("fb_splits/klmrants-new.tsv", sep = "\t", header = F, stringsAsFactors = F)
colnames(new_complaints) <- c("id", "time", "text")
new_complaints_with_flight_nr <- new_complaints[grepl("KL[0-9]+", new_complaints$text) |
                                          grepl("KL [0-9]+", new_complaints$text), ]

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

new_complaints_with_flight_nr$text <- tolower(new_complaints_with_flight_nr$text)
new_complaints_with_flight_nr$pred_date <- rep("", length(new_complaints_with_flight_nr[, 1]))
new_complaints_with_flight_nr$flight_no <- rep("", length(new_complaints_with_flight_nr[, 1]))

for (i in 1:length(new_complaints_with_flight_nr[, 1])) {
  new_complaints_with_flight_nr$flight_no[i] <- str_extract(new_complaints_with_flight_nr$text[i], "kl[0-9]+")
  if (is.na(new_complaints_with_flight_nr$flight_no[i])) {
    new_complaints_with_flight_nr$flight_no[i] <- str_extract(new_complaints_with_flight_nr$text[i], "kl [0-9]+")
    new_complaints_with_flight_nr$flight_no[i] <- paste("KL",
                                                    substr(new_complaints_with_flight_nr$flight_no[i], 4, 7),
                                                    sep = "")
  }
  new_complaints_with_flight_nr$flight_no[i] <- toupper(new_complaints_with_flight_nr$flight_no[i])
  
  for (j in 1:length(regex_list)) {
    if (grepl(regex_list[j], new_complaints_with_flight_nr$text[i])) {
      poss_date <- str_trim(str_extract(new_complaints_with_flight_nr$text[i], regex_list[j]))
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
        if (new_complaints_with_flight_nr$pred_date[i] == "")
          new_complaints_with_flight_nr$pred_date[i] <- as.character(date_var)
        else
          new_complaints_with_flight_nr$pred_date[i] <- paste(new_complaints_with_flight_nr$pred_date[i],
                                                          as.character(date_var),
                                                          sep = ",")
      }
    }
  }
}


new_complaints_with_flight_nr[, "time-short"] <- new_complaints_with_flight_nr$time
new_complaints_with_flight_nr[, "month"] <- new_complaints_with_flight_nr$time

complaints_with_flight_nr <- rbind(complaints_with_flight_nr, new_complaints_with_flight_nr)

################ match flight with comment ################

