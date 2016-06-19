require './normalize_neologd'

def tweet_normalize(text)
	#remove mention
   	text = text.gsub(/@[^\s　]+/u, "")
   	# text = text.gsub(/@.+[\s　]/u, " ")
   	#remove RT
   	text = text.gsub(/\ART/u, "")
   	#remove link text
   	text = text.gsub(/(https?:\/\/)[^ ]+/u, "")
   	#remove hashtag
   	text = text.gsub(/#[^\s　]+/u, "")
   	#remove unicode emoji
   	text = text.encode('SJIS', 'UTF-8', invalid: :replace, undef: :replace, replace: '').encode('UTF-8')

   	normalize_neologd(text)
end