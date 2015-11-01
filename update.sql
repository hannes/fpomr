create function  klmrants2()returns table ("id"  string,      "tsstr"  string,    "txt" string)language R {
library(data.table)

dd <- fread("/Users/hannes/source/hackathon/klmrants2.tsv", header=F)
dd <- setNames(dd, c("id", "tsstr", "txt"))
as.data.frame(dd, stringsAsFactors=F)
};

create table klmrants as select * from klmrants2() with data;

-- run updater after this

create function  grepl(pattern string, x string) returns boolean language R {
grepl(pattern, x, perl=T, ignore.case=T)
};

drop table regex;
create table regex as select id, grepl('((lost|missing|verloren|kwijt).{1,100}bag|bag.{1,100}(lost|missing|verloren|kwijt))', txt) as lostbag, grepl('over *bo(oked|ekt)', txt) as overbook, grepl('(cancelled|geannuleerd)', txt) as cancelled from klmrants where substring(tsstr,0,10) > '2014-10-29' with data;
