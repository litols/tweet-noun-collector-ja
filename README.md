# tweet-noun-collector-ja
## Overview
Twitterの日本語ツイートまたはTwilogに保存された日本語ツイートから、日本語の複合名詞の単語と読み仮名のペアをMeCabの辞書である[mecab-ipadic-neologd](https://github.com/neologd/mecab-ipadic-neologd)と標準のシステム辞書(ipadic)を用いて収集します。

Collect japanese noun in Twitter and Twilog by using [mecab-ipadic-neologd](https://github.com/neologd/mecab-ipadic-neologd).

## 使用方法
次のソフトウェアを使用した環境で動作を確認しています。
 - Ruby 2.2.4 p230
 - xubuntu 16.04 amd64
 - MeCab 0.996
 - mecab-ipadic-neologd 20160613-01 release
 - SQLite 3.11.0
    - クローラーanemoneの動作の他、重複削除に使用します。

## ファイル構成
### 実行用スクリプト
 - twitter-crawler.rb
    - Twitterからデータを収集します。UserStreamを用いているので、常時起動型です。^Cで終了します。
    - 第一引数としてファイル名を与えると、そちらに書き出します。
    - 出力するデータは重複ありデータです
- twilog-crawler.rb
    - twilogからデータを収集します。クロールが終了するまで起動します。^Cで終了します。
    - 第一引数としてファイル名を与えると、そちらに書き出します。
    - 出力するデータは重複ありのデータです
- distinction.sql
    - 重複ありデータを整形して出力するSQLite3スクリプトです。catコマンド等を用いてパイプでsqlite3コマンドに流し込みます。

### それ以外
 - node-parser.rb
    - NEologdを用いて解析したデータのMeCab::Nattoのenum形式のデータを用いて複合語の構成を行う処理が記述されています。
    - 内部でさらにIPA辞書のMeCabによる形態素解析を実施し、複合語としてふさわしくない可能性が高いものは排除します
- settings[-sample].rb
    - 設定ファイルです。settings-sample.rbをsettings.rbにリネームして使用します。
    - Consumer_keyなどを含むので、settings.rbをGitで共有しないでください。
- tweet_normalize.rb
    - ツイートの正規化処理が記述されています。
 - node-parser.rb
    - [mecab-ipadic-neologd](https://github.com/neologd/mecab-ipadic-neologd)のWikiに掲載されている正規化スクリプトです。

- その他Gemfileなど

## データについて
収集したデータは、次に示すTSV形式で収集されます。

実際にTwitter/Twilogから収集した重複のない単語データも、この形式で/dataフォルダに格納されています。
（非常に大きいので開くときに注意）
```
[単語データ]\t[読み仮名データ]
```
ただし、twitter-crawler.rbとtwilog-crawler.rbが出力するデータは、重複ありのデータになります。
dup-remover.rbを用いて重複データを削除することが可能です。

## 留意事項
本プログラムはTwilogをスクレイピングする形で実装していますので、過負荷にならないよう1秒間隔でクロールするなど、節度を守り使用してください。