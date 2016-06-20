require 'natto'
require 'moji'
require './settings'

RULE_BASE = {:noun1 => true, :noun2 => true,:noun3 => true,:unk => true, :verb => true}
WORD_BASE = {:words => [], :kanas => []}

#generate complex noun 
def parse_nodes(text,nm_enum)
	#using Enumlator type MeCab result.
	#ignoring unknown words. (because can't assosiate word with kana)

	text = Marshal.load(Marshal.dump(text))

	rule = RULE_BASE

	#parse result
	# example
	# [{:words=>["SIMフリー", "端末"], :kanas=>["SIMフリー", "タンマツ"]},
	# {:words=>["スポーツ", "News"], :kanas=>["スポーツ", "ニュース"]}]
	result = []

	words = []
	kanas = []

	unk_words = []
	unk_kanas = []


	must_flag = false
	space_flag =false
	unk_flag = false

	nm_enum.each do |n|
		word = n.surface
		morph = n.feature.dup
		kana = n.feature.split(",")[7]

		# p text

		#複合語判定されたときに前にスペースを入れるべきか判定
		if text[/\A[\s　]+.*/u]
			space_flag = true
			text.gsub!(/\A[\s　]+/u, "")
		end
		# p "test"


		#前方一致でテキストを削除
		#正規表現を用いると(でエラーになる
		text.slice!(0,word.length)
		# p text
		
		# remove 笑　and 爆
		if word[/\A[笑爆]/]
			next
		end

		# katakana word's kana is katanaka.
		if word[%r{(\A[\p{InKatakana}]+\z)}]
			kana = word
		end

		if word[%r{(\A[\p{InHiragana}]+\z)}]
			kana = Moji.hira_to_kata(word)
		end

		#first character is not [ぁぃぅぇぉゃゅょゎァィゥェォヵㇰヶㇱㇲッㇳㇴㇵㇶㇷㇷ゚ㇸㇹㇺャュョㇻㇼㇽㇾㇿヮ] ignore "っ"
		if word[/\A[ぁぃぅぇぉゃゅょゎァィゥェォヵㇰヶㇱㇲッㇳㇴㇵㇶㇷㇷ゚ㇸㇹㇺャュョㇻㇼㇽㇾㇿヮ].*/u]
			next
		end

		#force out
		if word[/\A[wW!?]+/u]
			if words.size > 1
				puts ">>>> #{words.join}\t#{kanas.join}"
				result << {:words => Marshal.load(Marshal.dump(words)), :kanas => Marshal.load(Marshal.dump(kanas))}
				# csv << [words.join, nil, nil, nil, '名詞', '固有名詞', '*', '*', '*', '*', words.join, kanas.join, '*']
			end
			next
		end

		#読み仮名の対応が難しいので未知語は無視
		#名詞：接尾は頭にこない
		# TODO: Refactering
		if !(morph[/\A名詞,接尾,.*/u] && words.empty?)

			#一般名詞等のチェック
			if morph[/\A名詞,(一般|サ変接続|固有名詞),.*/u] ||
	           morph[/\A名詞,接尾,(一般|サ変接続),.*/u]
				#前の単語が英単語だったのであれば、空白を挿入
				if ( !words.empty? ) && space_flag
					words.push("\s")
					kanas.push("\s")
					space_flag = false
				end
				# puts "pushword1"
				if complex_noun?(word)
					words.push(word)
					kanas.push(kana)
					must_flag=false
					next
				end
			elsif morph[/\A名詞,(形容動詞語幹|ナイ形容詞語幹),.*/u]
				#前の単語が英単語だったのであれば、空白を挿入
				if ( !words.empty? ) && space_flag
					words.push("\s")
					kanas.push("\s")
					space_flag = false
				end
				# puts "pushword2"
				if complex_noun?(word)
					words.push(word)
					kanas.push(kana)
					must_flag = true
					next
				end
			elsif morph[/\A名詞,接尾,形容動詞語幹,.*/u]
				#接尾辞が頭にくることはない
				#前の単語が英単語だったのであれば、空白を挿入
				if ( !words.empty? ) && space_flag
					words.push("\s")
					kanas.push("\s")
					space_flag = false
				end
				# puts "pushword3"
				if !words.empty? && complex_noun?(word)
					words.push(word)
					kanas.push(kana)
					must_flag = true
					next
				end
			elsif morph[/\A名詞,接続詞的,.*/u] #対,VS,兼
				if complex_noun?(word)
					words.push(word)
					kanas.push(kana)
					must_flag = true
					next
				end
			end

		end

		# puts "endpush"

		must_flag = rule[:verb] if morph[/\A動詞,.*/u]

		if must_flag || words.size > 1
			if !words.empty? && !exist_neologd_dic?(words.join) 
				puts ">>>> #{words.join}\t#{kanas.join}"
				result << {:words => Marshal.load(Marshal.dump(words)), :kanas => Marshal.load(Marshal.dump(kanas))}
			end
		end
		words.clear
		kanas.clear
		space_flag = false
		must_flag = false
	end

	if(!words.empty?)
		if !words.empty? && !exist_neologd_dic?(words.join) 
			puts ">>>> #{words.join}\t#{kanas.join}"
			result << {:words => Marshal.load(Marshal.dump(words)), :kanas => Marshal.load(Marshal.dump(kanas))}
		end
	end
	result
end

# check complex noun with mecab ipadic
def complex_noun?(text)
	nmi = Natto::MeCab.new
	words = []
	must_flag =false
	noun_flag =false
	# p "complex_noun?"
	nmi.parse(text) do |n|
		# puts "#{n.surface}\t#{n.feature}"
		next if n.surface[/\A\z/]
		#バラして複合名詞組成にならないなら、おかしいので廃棄
		if n.feature[/\A名詞,.*/u] ||
			n.feature[/\A助詞,連体化.*/u] ||
			n.feature[/\A助詞,格助詞,(一般|引用),.+/u]
			# p n.surface
			next
		end
		# p "return false"
		return false
	end
	# p "return true"
	return true
end

# check exitst neologd dictonary
def exist_neologd_dic?(text)
	nm = Natto::MeCab.new(
	dicdir: "/usr/lib/mecab/dic/mecab-ipadic-neologd",
	unk_format: '未知語,%H\n',
	node_format: '%H')
	cnt = 0
	# p "complex_noun?"

	nm.parse(text) do |n|
		# puts "#{n.surface}\t#{n.feature}"
		next if n.surface[/\A\z/]
		return false if n.feature[/\A未知語,.*/u]
		cnt = cnt + 1
	end
	# p "return true"
	return cnt==1
end

#deprecated method
def result_parse(parse_result)
	result = []
	nmi = Natto::MeCab.new
	must_flag = false
	rule = RULE_BASE

	if !parse_result.empty?
		parse_result.each do |p_res|
			ret = []
			flag = false
			p_res[:words].each do |word|
				last_n = nil

				nmi.parse(word) do |n|
					next if n.surface.empty?
					# puts "#{n.surface}\t#{n.feature}"

					if n.feature[/\A名詞,.*/u] 
						flag = true
						# p "flag!"
					else
						flag = false
					end
				end

			end
			result.push p_res if !p_res.empty? && flag
		end
	end
	result
end

