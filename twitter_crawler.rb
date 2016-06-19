require 'twitter'
require 'natto'
require 'kconv'
require 'csv'
require 'moji'
require 'nokogiri'

#debug
require 'pp'

require './tweet_normalize'
require './node_parser'
require './settings'

FILENAME = ARGV[0] || 'onomasticon_twitter.tsv'

client_rest = Twitter::REST::Client.new do |config|
  config.consumer_key        = TWITTER_CONSUMER_KEY
  config.consumer_secret     = TWITTER_CONSUMER_SECRET
  config.access_token        = TWITTER_OAUTH_TOKEN
  config.access_token_secret = TWITTER_OAUTH_TOKEN_SECRET
end

client_stream = Twitter::Streaming::Client.new do |config|
  config.consumer_key        = TWITTER_CONSUMER_KEY
  config.consumer_secret     = TWITTER_CONSUMER_SECRET
  config.access_token        = TWITTER_OAUTH_TOKEN
  config.access_token_secret = TWITTER_OAUTH_TOKEN_SECRET
end

def processing(object)
	if object.is_a?(Twitter::Tweet)
	   	texts = object.text.dup.split("\n")
	   	
	   	texts.each do |text|
		   	text = tweet_normalize(text.dup)

			return if text[%r{(\A[\p{InBasicLatin}]+\z)}]

		   	nm = Natto::MeCab.new(
				dicdir: NEOLOGD_PATH,
				unk_format: '未知語,%H\n',
				node_format: '%H')

			puts text

			parse_result = parse_nodes(text, nm.enum_parse(text))

			File.open(FILENAME, 'a') do |file|
				parse_result.each do |r|
					break if r.empty?
					puts ">>>>>>> #{r[:words].join}\t#{r[:kanas].join}"
					file.write "#{r[:words].join}\t#{r[:kanas].join}\n"
				end
			end
		end
	end
end

client_rest.home_timeline(count: 300).each do |object|
	begin
		if object.is_a?(Twitter::Tweet) &&
			object.text[%r{(\A[\p{Han}\p{InHiragana}\p{InKatakana}\p{InHalfwidthAndFullwidthForms}\p{InCJKSymbolsAndPunctuation}]+\z)}] &&
			!object.text[%r{(\A[\p{InBasicLatin}]+\z)}]
				processing( object)
		end
	rescue Twitter::Error::TooManyRequests => e
		sleep error.rate_limit.reset_in
  		retry
	end
end

client_stream.sample(lang: "ja") do |object|
	begin
		if object.is_a?(Twitter::Tweet) &&
			object.text[%r{(\A[\p{Han}\p{InHiragana}\p{InKatakana}\p{InHalfwidthAndFullwidthForms}\p{InCJKSymbolsAndPunctuation}]+\z)}] #&&
			!object.text[%r{(\A[\p{InBasicLatin}]+\z)}]
				processing(object)
		end
	rescue Twitter::Error::TooManyRequests => error
		sleep error.rate_limit.reset_in
		retry
	end
end

##TESTFIELD
if if $0 == __FILE__
# text = '@litos0816 http://example.com ABC事件とは東京特許許可局でバスガス爆発が緊急発生した事件のことです　#りとるすめも　って感じ'
# text = %Q[いきたいUNISON SQUARE GARDEN BLUE ENCOUNT]

# text = 'Webをうぇっぶと発音するタイプの先生だ。よい。'
# text = %Q[ﾄﾙｺwwwwwwwwwwwwwwwスクエニ魔法。Postgre　SQLもデータベースっていうのである。you faceが分割される問題。SIMフリー端末出して。結果キターwww。スポーツNews読むよ。ついでにWWWとか言っててわろたｗｗｗｗｗｗｗｗ。無理ゲーｗｗｗｗｗｗめっちゃ無理ゲー.ケッコンカッコ。ゆうじゅうふだんにん。ゃくざこわい]
# text = 'www2.0で姉さん感出してwwwwww一緒に芸能活動www'
#remove mention
# text=%Q[SATURDAY SIX Father’s Day Special: Celebrating Dads at the Disney and Universal Parks]
# text="ビッグオーダーにデイジー役で出演してた三咲麻里って声優さんめっちゃ好きになった"
# text = %Q[Guests standing in rain for Kong technical rehearsals. At least there is a formal queue now. #kongwatch ~@skubersky]
# text = %Q[草はえるwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww]


p text
text = tweet_normalize(text)

# text = normalize_neologd(text)
p text


nm = Natto::MeCab.new(
	dicdir: NEOLOGD_PATH,
	unk_format: '未知語,%H\n',
	node_format: '%H')
nmi = Natto::MeCab.new(
	unk_format: '未知語,%H\n',
	node_format: '%H')
pp nm
pp nmi
pp nmi.options
parse_result = parse_nodes(text,nm.enum_parse(text))
pp parse_result

puts ""
# ret = result_parse parse_result
pp parse_result

parse_result.each do |n|
	puts ">>RESULT>>>>#{n[:words].join}\t#{n[:kanas].join}"
end

nmi.parse(text) do |n|
	puts "#{n.surface}\t#{n.feature}"
end

nm.parse(text) do |n|
	puts "#{n.surface}\t#{n.feature}"
end

p exist_neologd_dic?("PostgreSQL")

end