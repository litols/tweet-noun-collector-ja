require 'twitter'
require 'natto'
require 'kconv'
require 'csv'
require 'moji'
require 'nokogiri'
require 'anemone'
require 'sqlite3'

#debug
require 'pp'

require './tweet_normalize'
require './node_parser'

FILENAME = ARGV[0] || 'onomasticon_twilog.tsv'

def processing(fetch_text)
   	texts = fetch_text.dup.split("\n")
   	
   	texts.each do |text|
	   	text = tweet_normalize(text)
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

opts = {
    :skip_query_strings => true,
    :storage => Anemone::Storage::SQLite3('./db/anemone.db'),
    :depth_limit => 100000,
    :delay => 1
}

url = "http://twilog.org/user-list/"

Anemone.crawl(url, opts) do |anemone|

	anemone.focus_crawl do |page|
		page.links.keep_if { |link|
			link.to_s.match(%r{((\Ahttp://twilog.org/[A-Za-z0-9_/]+\z)|(\Ahttp://twilog.org/[A-Za-z0-9_/]+/date-[0-9]+\z)|(\Ahttp://twilog.org/user-list/[0-9]+\z))})
		}
	end

	anemone.on_every_page do |page|
        puts page.url
	end

	anemone.on_pages_like(%r{((\Ahttp://twilog.org/[A-Za-z0-9_]+.*\z))}) do |page|
		if !page.body.empty?
	    	doc = Nokogiri::HTML.parse(page.body.toutf8)

	        puts page.url
	    	doc.xpath('//article[@class="tl-tweet"]').each do |n|
	        	processing(n.css('p.tl-text').text)
	   		end
   		end
    end

end