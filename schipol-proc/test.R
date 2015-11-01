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


app_id = "9748f58b"
app_key = "5e72804013d167b714f595601df84a29"

from = "2015-10-30"
to = "2015-10-31"


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
last_idx = match(TRUE, grepl("last", out$stderr))

page_arr <- strsplit(strsplit(out$stderr[last_idx], ">; rel=\"last\"")[[1]][1], "&page=")[[1]]
last_page <- strtoi(page_arr[length(page_arr)])

for (page in 1:last_page) {
# for (page in 294:last_page) {
  print(paste("PROCESSING PAGE", page, "OUT OF", last_page, collapse = NULL))
  
  curr_url <- paste(sch_url, "&page=", page, collapse = NULL, sep = "")
  
  curr_command = paste("curl -v -k -H \"ResourceVersion:v1\" \"",
                  curr_url,
                  "\"",
                  collapse = NULL, sep = "")
  
  # system(curr_command)
  out <- robust.system(curr_command)
  
  while (grepl("failed", out$stdout)) {
    Sys.sleep(1)
    out <- robust.system(curr_command)
  }
  
#   if (page == 1) {
#     flight_data <- fromJSON(out$stdout)$flights
#     row.names(flight_data) <- NULL 
#   }
#   else flight_data <- rbind(flight_data, fromJSON(out$stdout)$flights, row.names=NULL)  
  
  write(out$stdout, 
        paste("data2/sch_oct", page, ".json", collapse = NULL, sep = ""))
}
