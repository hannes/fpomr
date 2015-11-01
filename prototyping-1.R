library(data.table)
library(dplyr)
library(ggplot2)
library(jsonlite)

dd <- fread("klmrants2.tsv", header=F)
ddn <- fread("klmrants-new.tsv", header=F)
dd <- rbind(dd, ddn)
dd <- setNames(dd, c("id", "tsstr", "txt"))
dd <- as.data.frame(dd, stringsAsFactors=F)
dd$ts <- as.POSIXlt(sub("T", " ", dd$tsstr, fixed=T), tz="UTC")
dd$date <- strftime(dd$ts, "%Y-%m-%d")

dd$lostbag <- grepl("((lost|missing|verloren|kwijt).{1,100}bag|bag.{1,100}(lost|missing|verloren|kwijt))",dd$txt, perl=T, ignore.case=T)
dd$overbook <- grepl("over\\w*bo(oked|ekt)",dd$txt, perl=T, ignore.case=T)
dd$cancelled <- grepl("(cancelled|geannuleerd)",dd$txt, perl=T, ignore.case=T)
#dd$delay <- grepl("(delay|vertrag)",dd$txt, perl=T, ignore.case=T)
#dd$rude <- grepl("(rude|unfriendly|onbeleefd|ruw|grof)",dd$txt, perl=T, ignore.case=T)

dd2 <- dd[dd$date > "2014-10-29",]
dd2$ts <- NULL
write.csv(dd2, "/tmp/dd2", row.names=F)
overall <- dd2 %>% group_by(date) %>% summarise(lostbag=sum(lostbag),overbook=sum(overbook),cancelled=sum(cancelled),delay=sum(delay),rude=sum(rude) ) %>% arrange(date)

cat(toJSON(overall), file="public/overall.json")

load("comments_with_flights_new.Rdata")

dd3 <- dd2 %>% left_join(comments_with_flights, by="id")
dd4 <- dd3 %>% filter(!is.na(flight_id) & (lostbag | overbook | cancelled)) %>% select(id, flight_date, flight_time, flight_id, departure, arrival)
write.csv(dd4, "/tmp/dd4", row.names=F)
