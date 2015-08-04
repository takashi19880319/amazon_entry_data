@echo off
echo /
echo / GLOBERに登録されているデータを元にアマゾン店に登録する商品
echo / データを作成する
echo /
echo [手順]
echo --------------------------------------------------------
echo  1. 実行に必要なファイル一式が存在している事を確認する。
echo     -amazon_entry_data.bat
echo     +exe
echo       -amazon_entry_data.pl
echo  2. 下記の必要なファイル一式をバッチと同一フォルダに配置する。
echo     -sabun_YYYYMMDD.csv
echo     -genre_goods.csv
echo	 -category_amazon.csv
echo	 -category_amazon.csv
echo	 -goods_spec.csv
echo	 -goods_supp.csv
echo  3. 上記ファイルが正しく存在する事を確認してから処理を続行する。
echo  4. amazon_entry_data.csvが出力される
echo --------------------------------------------------------
echo ----- データ抽出処理(amazon_entry_data.pl)を実行します -----
PAUSE
echo データ抽出処理(amazon_entry_data.pl)を実行しています...

CD ./exe
perl -X amazon_entry_data.pl

echo データ抽出処理(amazon_entry_data.pl)の実行が完了しました。

PAUSE

END
