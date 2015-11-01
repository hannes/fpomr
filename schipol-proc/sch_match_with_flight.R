files <- list.files(path = "data2/", pattern = "sch_")
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

data <- data[order(data$scheduleDate), ]

save(data, file = "schiphol_klm_data.Rdata")

load("complaints_flight_nr.Rdata")
airport_codes <- read.csv("iata-airport-codes/airport-codes.csv")


######### match data #########

data <- data[data$flightName %in% complaints_with_flight_nr$flight_no, ]
complaints_with_flight_nr <- complaints_with_flight_nr[complaints_with_flight_nr$flight_no %in%
                                                         data$flightName, ]

complaints_with_flight_nr$departure <- rep("", length(complaints_with_flight_nr[, 1]))
complaints_with_flight_nr$arrival <- rep("", length(complaints_with_flight_nr[, 1]))
complaints_with_flight_nr$flight_time <- rep("", length(complaints_with_flight_nr[, 1]))

for (i in 1:length(complaints_with_flight_nr[, 1])) {
  print(paste("PROCESSING", i, "OUT OF", length(complaints_with_flight_nr[, 1])))
  
  sample_fl <- data[data$flightName %in% c(complaints_with_flight_nr$flight_no[i]), ]
  
   if (i == 3077)  {
     other_city <- "Hangzhou, China"
   }
   else {
     other_city <- sample_fl$destinations[[1]][1]
     oc_pos <- match(sample_fl$destinations[[1]][1], airport_codes$code)
     if(!is.na(oc_pos) && length(oc_pos) > 0) {
       other_city <- paste(airport_codes$city[oc_pos], airport_codes$country[oc_pos], sep = ", ")
     }
   }
   
   if (sample_fl$flightDirection[1] == "A") {
     complaints_with_flight_nr$arrival[i] <-  "Amsterdam, Netherlands"
     complaints_with_flight_nr$departure[i] <- other_city
   }
   else {
     complaints_with_flight_nr$departure[i] <-  "Amsterdam, Netherlands"
     complaints_with_flight_nr$arrival[i] <- other_city
   }
   
   complaints_with_flight_nr$flight_time[i] <- sample_fl$scheduleTime[1]
   if (!grepl("2015", complaints_with_flight_nr$pred_date[i])) {
     complaints_with_flight_nr$pred_date[i] <- as.character(as.Date(complaints_with_flight_nr[i, "time-short"], "%Y-%m-%d"))
   }
  
  poss_dates_comm <- strsplit(complaints_with_flight_nr$pred_date[i], ",")[[1]]
  poss_dates <- c()
  
  if (!is.na(match(poss_dates_comm, sample_fl$scheduleDate))) {
    sample_fl$scheduleDate[match(poss_dates_comm, sample_fl$scheduleDate)]
  }
}



####### write data #######


out_data <- complaints_with_flight_nr[, c("id", "time", "text", "pred_date", "flight_time", "flight_no", "departure", "arrival")]
colnames(out_data) <- c(
  "id",
  "comment_time",
  "comment_text",
  "flight_date",
  "flight_time",
  "flight_id",
  "departure",
  "arrival"
)

# write.table(out_data, file = "comments_with_flights.tsv", quote = T, sep = "\t", row.names = F)

comments_with_flights <- out_data
save(comments_with_flights, file = "comments_with_flights_new.Rdata")
