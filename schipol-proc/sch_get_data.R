require(curl)
require(jsonlite)

robust.system <- function (cmd) {
  stderrFile = tempfile(pattern="R_robust.system_stderr", fileext=as.character(Sys.getpid()))
  stdoutFile = tempfile(pattern="R_robust.system_stdout", fileext=as.character(Sys.getpid()))
  
  retval = list()
  retval$exitStatus = system(paste0(cmd, " 2> ", shQuote(stderrFile), " > ", shQuote(stdoutFile)))
  retval$stdout = readLines(stdoutFile)
  retval$stderr = readLines(stderrFile)
  
  unlink(c(stdoutFile, stderrFile))
  return(retval)
}

numberOfDays <- function(date) {
  date <- as.Date(date, "%Y-%m-%d")
  m <- format(date, format="%m")
  
  while (format(date, format="%m") == m) {
    date <- date + 1
  }
  
  return(as.integer(format(date - 1, format="%d")))
}


app_id = "9748f58b"
app_key = "5e72804013d167b714f595601df84a29"

for (month in 3:1) {

  from = paste("2015-0", month, "-01", collapse = NULL, sep = "")
  to =   paste("2015-0", month, "-", numberOfDays(from), collapse = NULL, sep = "")
  
  
  sch_url = paste("https://api-acc.schiphol.nl/public-flights/flights?app_id=",
              app_id,
              "&app_key=",
              app_key,
              "&fromdate=",
              from,
              "&todate=",
              to,
              collapse=NULL, sep = "")
  
  
  page <- 1
  command = paste("curl -v -k -H \"ResourceVersion:v1\" \"",
                  sch_url,
                  "\"",
                  collapse = NULL, sep = "")
  
  out = robust.system(command)
  
  conn_try <- 1
  while (grepl("failed", out$stdout)) {
    Sys.sleep(1)
    out <- robust.system(command)
    
    print(paste("TRYING TO CONNECT TRY", conn_try))
    conn_try <- conn_try + 1
  }
  
  last_idx = match(TRUE, grepl("last", out$stderr))
  
  page_arr <- strsplit(strsplit(out$stderr[last_idx], ">; rel=\"last\"")[[1]][1], "&page=")[[1]]
  last_page <- strtoi(page_arr[length(page_arr)])
  
  # for (page in 1:last_page) {
  for (page in 1:last_page) {
    print(paste("PROCESSING MONTH", month, "PAGE", page, "OUT OF", last_page,
                collapse = NULL))
    
    curr_url <- paste(sch_url, "&page=", page, collapse = NULL, sep = "")
    
    curr_command = paste("curl -v -k -H \"ResourceVersion:v1\" \"",
                    curr_url,
                    "\"",
                    collapse = NULL, sep = "")
    
    # system(curr_command)
    out <- robust.system(curr_command)
    
    conn_try <- 1
    while (grepl("failed", out$stdout)) {
      Sys.sleep(1)
      out <- robust.system(curr_command)
      
      print(paste("TRYING TO CONNECT TRY", conn_try))
      conn_try <- conn_try + 1
    }
    
  #   if (page == 1) {
  #     flight_data <- fromJSON(out$stdout)$flights
  #     row.names(flight_data) <- NULL 
  #   }
  #   else flight_data <- rbind(flight_data, fromJSON(out$stdout)$flights, row.names=NULL)  
    
    write(out$stdout, 
          paste("data2/sch_", tolower(month.abb[month]), page, ".json", collapse = NULL, sep = ""))
  }
}
