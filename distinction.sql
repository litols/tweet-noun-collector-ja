create table words (word text,kana text);
.separator "\t"
.import onomasticon_twilog.tsv words
.import onomasticon_twitter.tsv words
.mode tabs words
.output onomasticon_out.tsv
select distinct * from words;
drop table words;