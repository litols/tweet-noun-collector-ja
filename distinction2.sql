create table words (word text,kana text);
.separator "\t"
.import onomasticon_twilog.tsv words
.import onomasticon_twitter.tsv words
.mode tabs words
.output onomasticon_out_2.tsv
select * from words group by word order by count(*) desc limit 100000;
drop table words;