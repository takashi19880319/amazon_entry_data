# mall_price_upadate.pl
# author:T.Hashiguchi
# date:2014/10/13

#========== 改訂履歴 ==========
#
########################################################

#/usr/bin/perl

use strict;
use warnings;
use Cwd;
use Encode;
use XML::Simple;
use Text::ParseWords;
use Text::CSV_XS;
use File::Path;

####################
## ログファイル
####################
# ログファイルを格納するフォルダ名
my $output_log_dir="./../log";
# ログフォルダが存在しない場合は作成
unless (-d $output_log_dir) {
	if (!mkdir $output_log_dir) {
		&output_log("ERROR!!($!) create $output_log_dir failed\n");
		exit 1;
	}
}
# ログファイル名
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time());
my $time_str = sprintf("%04d%02d%02d%02d%02d%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec);
my $log_file_name="$output_log_dir"."/"."create_mall_entry_data"."$time_str".".log";
# ログファイルのオープン
if(!open(LOG_FILE, "> $log_file_name")) {
	print "ERROR!!($!) $log_file_name open failed.\n";
	exit 1;
}

####################
## 入力ファイルの存在チェック
####################
#入力ファイル配置ディレクトリのオープン
my $current_dir=Cwd::getcwd();
my $input_dir ="$current_dir"."/..";
opendir(INPUT_DIR, "$input_dir") or die("ERROR!! $input_dir open failed.");
#入力ファイル名
my $sabun_file_name="";
my $input_goods_spec_file_name="goods_spec.csv";
my $input_goods_supp_file_name="goods_supp.csv";
my $input_genre_goods_file_name="genre_goods.csv";
my $input_category_amazon_file_name="category_amazon.csv";
my $sabun_file_find=0;
my $goods_spec_file_find=0;
my $goods_supp_file_find=0;
my $genre_goods_file_find=0;
my $category_amazon_file_find=0;
my $sabun_file_multi=0;
while (my $current_dir_file_name = readdir(INPUT_DIR)){
	if(index($current_dir_file_name, "sabun_", 0) == 0) {
		if ($sabun_file_find) {
			#sabun_YYYYMMDDファイルが複数存在する
			$sabun_file_multi=1;
			next;
		}
		else {
			$sabun_file_find=1;
			$sabun_file_name=$current_dir_file_name;
		}
	}
	elsif($current_dir_file_name eq $input_goods_spec_file_name) {
		$goods_spec_file_find=1;
		next;
	}
	elsif($current_dir_file_name eq $input_goods_supp_file_name) {
		$goods_supp_file_find=1;
		next;
	}
	elsif($current_dir_file_name eq $input_genre_goods_file_name) {
		$genre_goods_file_find=1;
		next;
	}
	elsif($current_dir_file_name eq $input_category_amazon_file_name) {
		$category_amazon_file_find=1;
		next;
	}
}
closedir(INPUT_DIR);
if (!$sabun_file_find) {
	#sabun.csvファイルが存在しない
	output_log("ERROR!! Not exist sabun.csv.\n");
}
if (!$goods_spec_file_find) {
	#goods_spec.csvファイルがカレントディレクトリに存在しない
	&output_log("ERROR!! Not exist $input_goods_spec_file_name.\n");
}
if (!$goods_supp_file_find) {
	#goods_supp.csvファイルがカレントディレクトリに存在しない
	&output_log("ERROR!! Not exist $input_goods_supp_file_name.\n");
}
if (!$genre_goods_file_find) {
	#goods_supp.csvファイルがカレントディレクトリに存在しない
	&output_log("ERROR!! Not exist $input_genre_goods_file_name.\n");
}
if (!$category_amazon_file_find) {
	#goods_supp.csvファイルがカレントディレクトリに存在しない
	&output_log("ERROR!! Not exist $input_category_amazon_file_name.\n");
}
####################
## 参照ファイルの存在チェック
####################
my $brand_xml_filename="brand.xml";
my $genre_xml_filename="genre.xml";
my $goods_spec_xml_filename="goods_spec.xml";
#参照ファイル配置ディレクトリのオープン
my $ref_dir ="$current_dir"."/xml";
if (!opendir(REF_DIR, "$ref_dir")) {
	&output_log("ERROR!!($!) $ref_dir open failed.");
	exit 1;
}
# 参照ファイルの有無チェック
my $brand_xml_file_find=0;
my $genre_xml_file_find=0;
my $goods_spec_xml_file_find=0;
while (my $ref_dir_file_name = readdir(REF_DIR)){
	if($ref_dir_file_name eq $brand_xml_filename) {
		$brand_xml_file_find=1;
		next;
	}
	elsif($ref_dir_file_name eq $genre_xml_filename) {
		$genre_xml_file_find=1;
		next;
	}
	elsif($ref_dir_file_name eq $goods_spec_xml_filename) {
		$goods_spec_xml_file_find=1;
		next;
	}
}
closedir(REF_DIR);
if (!$brand_xml_file_find) {
	#goods_spec.xmlファイルが存在しない
	&output_log("ERROR!!($!) Not exist $brand_xml_filename.\n");
}
if (!$genre_xml_file_find) {
	#category.xmlファイルが存在しない
	&output_log("ERROR!!($!) Not exist $genre_xml_filename.\n");
}
if (!$goods_spec_xml_file_find) {
	#goods_spec.xmlファイルが存在しない
	&output_log("ERROR!!($!) Not exist $goods_spec_xml_filename.\n");
}
if (!$brand_xml_file_find || !$genre_xml_file_find) {
	exit 1;
}
$brand_xml_filename="$ref_dir"."/"."$brand_xml_filename";
$genre_xml_filename="$ref_dir"."/"."$genre_xml_filename";
$goods_spec_xml_filename="$ref_dir"."/"."$goods_spec_xml_filename";

####################
## 入力ファイルのオープン
####################
#CSVファイル用モジュールの初期化
my $input_sabun_csv = Text::CSV_XS->new({ binary => 1 });
my $input_goods_spec_csv = Text::CSV_XS->new({ binary => 1 });
my $input_goods_supp_csv = Text::CSV_XS->new({ binary => 1 });
my $input_genre_goods_csv = Text::CSV_XS->new({ binary => 1 });
my $input_category_amazon_csv = Text::CSV_XS->new({ binary => 1 });
#入力ファイルのオープン

$sabun_file_name="$input_dir"."/"."$sabun_file_name";
my $input_sabun_file_disc;
if (!open $input_sabun_file_disc, "<", $sabun_file_name) {
	&output_log("ERROR!!($!) $sabun_file_name open failed.");
	exit 1;
}
my $input_sabun_file_disc_2;
if (!open $input_sabun_file_disc_2, "<", $sabun_file_name) {
	&output_log("ERROR!!($!) $sabun_file_name open failed.");
	exit 1;
}
$input_goods_spec_file_name="$input_dir"."/"."$input_goods_spec_file_name";
my $input_goods_spec_file_disc;
if (!open $input_goods_spec_file_disc, "<", $input_goods_spec_file_name) {
	&output_log("ERROR!!($!) $input_goods_spec_file_name open failed.");
	exit 1;
}	
$input_goods_supp_file_name="$input_dir"."/"."$input_goods_supp_file_name";
my $input_goods_supp_file_disc;
if (!open $input_goods_supp_file_disc, "<", $input_goods_supp_file_name) {
	&output_log("ERROR!!($!) $input_goods_supp_file_name open failed.");
	exit 1;
}
$input_genre_goods_file_name="$input_dir"."/"."$input_genre_goods_file_name";
my $input_genre_goods_file_disc;
if (!open $input_genre_goods_file_disc, "<", $input_genre_goods_file_name) {
	&output_log("ERROR!!($!) $input_genre_goods_file_name open failed.");
	exit 1;
}
$input_category_amazon_file_name="$input_dir"."/"."$input_category_amazon_file_name";
my $input_category_amazon_file_disc;
if (!open $input_category_amazon_file_disc, "<", $input_category_amazon_file_name) {
	&output_log("ERROR!!($!) $input_category_amazon_file_name open failed.");
	exit 1;
}
####################
## 出力ファイルのオープン
####################
#出力ディレクトリ
my $output_up_data_dir="../up_data";
#出力ファイル名
my $output_file_name="$output_up_data_dir"."/"."amazon_entry_data.csv";

#出力先ディレクトリの作成
unless(-d $output_up_data_dir) {
	# 存在しない場合はフォルダ作成
	if(!mkpath($output_up_data_dir)) {
		output_log("ERROR!!($!) $output_up_data_dir create failed.");
		exit 1;
	}
}
#出力用CSVファイルモジュールの初期化
my $output_amazon_entry_data_csv = Text::CSV_XS->new({ binary => 1 });

#出力ファイルのオープン
my $output_amazon_entry_data_disc;
if (!open $output_amazon_entry_data_disc, ">", $output_file_name) {
	&output_log("ERROR!!($!) $output_file_name open failed.");
	exit 1;
}
####################
## 各関数間に跨って使用するグローバル変数
####################
my $global_entry_code=0;
my $global_entry_code_5=0;
my $global_entry_category="";
my $sabun_category="";
my $global_entry_name="";
my $global_entry_price=0;
my $global_entry_size="";
my $global_entry_color="";
my @done_goods_code =();
# ブランドカテゴリのジャンル判定フラグ
my $genre_flag_shoes_bag =0;
# ブランドカテゴリのジャンル判定フラグ
my $genre_flag_accessary =0;
# レディースの判定フラグ
my $sex_flag = 0;
# goods_spec.csvの情報をストックしたリスト
my @global_entry_goods_spec_info=();
# goods_supp.csvの情報をストックしたリスト
my @global_entry_goods_supp_info=();
# スペックの優先順位ルールの配列リストを作成
my @globel_spec_sort=&get_spec_sort_from_xml();
# 商品スペックを出力形式にした文字列のリスト
my @specs=();
# 商品スペックのサイズリスト
my @spec_size_info =();
########################################################################################################################
########################## 処理開始
########################################################################################################################
&output_log("**********START**********\n");
# goods_img.csv出に項目名を出力
&add_amazon_entry_data_name();
# 商品データの作成

my $sabun_line = $input_sabun_csv->getline($input_sabun_file_disc);
while($sabun_line = $input_sabun_csv->getline($input_sabun_file_disc)){
	##### sabun.csvファイルの読み出し
	$global_entry_code=@$sabun_line[0];
	$sabun_category=@$sabun_line[1];
	$global_entry_name=@$sabun_line[2];
	$global_entry_size = @$sabun_line[4];
	$global_entry_color=@$sabun_line[5];
	$global_entry_code_5 = substr($global_entry_code,0,5);
	# 既に登録済みの親コードが判別する
	my $done_find_flag =0;
	foreach my $done_goods_code (@done_goods_code) {
		if($done_goods_code == $global_entry_code_5){
			$done_find_flag =1;
			last;
		}
	}
	if($done_find_flag == 0){
		@spec_size_info=();
		# サイズバリエーションのある商品のサイズをリストに格納する
		if($global_entry_size ne ""){
			seek $input_sabun_file_disc_2,0,0;
			my $sabun_line_temp = $input_sabun_csv->getline($input_sabun_file_disc_2);
			while($sabun_line_temp = $input_sabun_csv->getline($input_sabun_file_disc_2)){
				my $size_find_flag =0;
				my $global_entry_code_temp = @$sabun_line_temp[0];
				my $sabun_line_temp_code5 = substr($global_entry_code_temp,0,5);
				if($global_entry_code_5 eq $sabun_line_temp_code5){
					my $sabun_line_size = @$sabun_line_temp[4];
					# 重複は配列に入れない
					for (my $i = 0; $i <= $#spec_size_info; $i++){
						if($sabun_line_size eq $spec_size_info[$i]){
							$size_find_flag =1;
						}
					}
					if ($size_find_flag == 0){
						push (@spec_size_info,@$sabun_line_temp[4]);
					}
				}
			}
		}
	}
	# ジャンル判定をして指定のブランドの文字列を取得する
	seek $input_genre_goods_file_disc,0,0;
	$genre_flag_shoes_bag =0;
	$genre_flag_accessary=0;
	my $genre_goods_line=$input_genre_goods_csv->getline($input_genre_goods_file_disc);
	while($genre_goods_line = $input_genre_goods_csv->getline($input_genre_goods_file_disc)){	
		# 登録情報から商品コード読み出し
		my $genre_code_5 = @$genre_goods_line[1];
		if ($global_entry_code_5 == $genre_code_5) {
				my $genre_code = @$genre_goods_line[0];
				if($genre_code =~ /13|15|16/){
					seek $input_category_amazon_file_disc,0,0;
					my $category_amazon_line=$input_category_amazon_csv->getline($input_category_amazon_file_disc);
					while($category_amazon_line = $input_category_amazon_csv->getline($input_category_amazon_file_disc)){
						if($sabun_category eq @$category_amazon_line[0]){
							$global_entry_category = @$category_amazon_line[2];
							# フラグを作成
							$genre_flag_shoes_bag = 1;
							last;
						}
					}
				}
				elsif($genre_code =~ /1910|1911|1912/){
					$genre_flag_accessary = 1;
				}
				else{
					seek $input_category_amazon_file_disc,0,0;
					my $category_amazon_line=$input_category_amazon_csv->getline($input_category_amazon_file_disc);
					while($category_amazon_line = $input_category_amazon_csv->getline($input_category_amazon_file_disc)){
						if($sabun_category eq @$category_amazon_line[0]){
							$global_entry_category = @$category_amazon_line[1];
							# フラグを作成
							$genre_flag_shoes_bag = 1;
							last;
						}
					}
				}
			last;
		}
	}
	$global_entry_category =~ s/\?//g;
	# スペック情報の取得
	@global_entry_goods_spec_info=();
	@specs=();
	seek $input_goods_spec_file_disc,0,0;
	my $goods_spec_line=$input_goods_spec_csv->getline($input_goods_spec_file_disc);
	while($goods_spec_line = $input_goods_spec_csv->getline($input_goods_spec_file_disc)){	
		# 登録情報から商品コード読み出し
		if ($global_entry_code_5 eq @$goods_spec_line[0]) {
			# 商品のスペック情報を保持する
			push(@global_entry_goods_spec_info, (@$goods_spec_line[1], @$goods_spec_line[2]));
			
		}
	}
	#商品説明の取得
	@global_entry_goods_supp_info=();
	seek $input_goods_supp_file_disc,0,0;
	my $goods_supp_line=$input_goods_supp_csv->getline($input_goods_supp_file_disc);
	while($goods_supp_line = $input_goods_supp_csv->getline($input_goods_supp_file_disc)){	
		# 登録情報から商品コード読み出し
		if ($global_entry_code_5 eq @$goods_supp_line[0]) {
			# 商品のスペック情報を保持する
			push(@global_entry_goods_supp_info, (@$goods_supp_line[1], @$goods_supp_line[2]));
			
		}
	}
	# 出力するスペック文字列を配列に格納
	&get_output_spec_list;
	# CSVにデータを主力
	if ($done_find_flag == 0){
		# 親コード5桁で1行出力する
		$global_entry_code = $global_entry_code_5;
		&add_amazon_entry_data();
		# 親コードは完了リストに入れておく
		push (@done_goods_code,$global_entry_code);
		# 読み込んだ9桁で再度1行出力する
		$global_entry_code=@$sabun_line[0];
		&add_amazon_entry_data();
	}
	else{
		#バリエーションの商品を出力
		&add_amazon_entry_data();
	}
}
# 処理終了
output_log("Process is Success!!\n");
output_log("**********END**********\n");

# 入力用CSVファイルモジュールの終了処理
$input_sabun_csv->eof;
$input_goods_spec_csv->eof;
$input_goods_supp_csv->eof;
$input_genre_goods_csv->eof;
$input_category_amazon_csv->eof;
# 出力用CSVファイルモジュールの終了処理
$output_amazon_entry_data_csv->eof;
# 入力ファイルのクローズ
close $input_sabun_file_disc;
close $input_sabun_file_disc_2;
close $input_goods_spec_file_disc;
close $input_goods_supp_file_disc;
close $input_genre_goods_file_disc;
close $input_category_amazon_file_disc;
# 出力ファイルのクローズ
close $output_amazon_entry_data_disc;
close(LOG_FILE);

##############################
## amazon_entry_data.csvファイルに項目名を追加
##############################
sub add_amazon_entry_data_name {
	#amazon仕様1
	my $amazon_str_1 ="TemplateType=Clothing";
	#amazon仕様2
	my $amazon_str_2 ="Version=2012.0530";
	#amazon仕様3
	my $amazon_str_3 ="この行はAmazonが使用しますので変更や削除しないでください。";
	my @csv_amazon_entry_data_name_1=($amazon_str_1,$amazon_str_2,$amazon_str_3);
	my $csv_amazon_entry_data_name_1_num=@csv_amazon_entry_data_name_1;
	my $csv_amazon_entry_count_1=0;
	for my $csv_amazon_entry_name_1_str (@csv_amazon_entry_data_name_1) {
		Encode::from_to( $csv_amazon_entry_name_1_str, 'utf8', 'shiftjis' );
		$output_amazon_entry_data_csv->combine($csv_amazon_entry_name_1_str) or die $output_amazon_entry_data_csv->error_diag();
		my $post_fix_str="";
		if (++$csv_amazon_entry_count_1 >= $csv_amazon_entry_data_name_1_num) {
			$post_fix_str="\n";
		}
		else {
			$post_fix_str=",";
		}
		print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), $post_fix_str;
	}
	my @csv_amazon_entry_data_name_2=("商品管理番号","商品名","商品コード(JANコード等)","商品コードのタイプ","ブランド名","商品タイプ","対象年齢・性別1","スタイルキーワード1","商品説明の箇条書き1","商品説明の箇条書き2","商品説明の箇条書き3","商品説明の箇条書き4","商品説明の箇条書き5","商品説明文","推奨ブラウズノード1","検索キーワード1","検索キーワード2","検索キーワード3","検索キーワード4","検索キーワード5","商品メイン画像URL","在庫数","リードタイム(出荷までにかかる作業日数)","商品のコンディション","商品のコンディション説明","商品の販売価格","通貨コード","サイズ","サイズマップ","カラー","カラーマップ","スタイル名","靴の幅","ヒールの高さの単位","ヒールの高さ","ストラップのタイプ","つま先の形状(トゥシェープ)","ウエストのスタイル","素材不透明度","ヒールのタイプ","シャフト(軸)の丈","表地素材","シャフト(軸)の直径","ライフスタイル1","袖のタイプ","留め具のタイプ","留め具のタイプ","親子指定","親商品のSKU(商品管理番号)","親子関係のタイプ","バリエーションテーマ","推奨ブラウズノード2","ライフスタイル2","ライフスタイル3","ライフスタイル4","ライフスタイル5","素材または繊維1","対象年齢・性別2","スタイルキーワード2","スタイルキーワード3","スタイルキーワード4","スタイルキーワード5","アダルト商品","推奨最低身長の単位","推奨最低身長","推奨最高身長の単位","推奨最高身長","商品パッケージの長さの単位","商品パッケージの長さ","商品パッケージの幅","商品パッケージの高さ","ウエストサイズの単位","ウエストサイズ","仕立ての長さの単位","仕立ての長さ","袖の長さの単位","袖の長さ","シャツカラースタイル","首のタイプ","首のサイズの単位","首のサイズ","ボトムススタイル","胸囲サイズの単位","胸囲サイズ","カップサイズ","振袖の長さの単位","振袖の長さ","振袖の幅の単位","振袖の幅","帯の長さの単位","帯の長さ","帯の幅の単位","帯の幅","付け帯の幅の単位","付け帯の幅","付け帯の高さの単位","付け帯の高さ","枕サイズ","枕サイズの単位","カラーサンプル画像URL","商品のサブ画像URL1","商品のサブ画像URL2","商品のサブ画像URL3","商品のサブ画像URL4","商品のサブ画像URL5","商品のサブ画像URL6","商品のサブ画像URL7","商品のサブ画像URL8","配送重量の単位","配送重量","商品パッケージの重量の単位","商品パッケージの重量","商品の公開日","予約商品の販売開始日","メーカー希望小売価格","使用しない支払い方法","セール価格","セール開始日","セール終了日","フルフィルメントセンターID","商品の入荷予定日","モデル年(発売年・発表年)","シーズン","最大注文個数","最大同梱可能個数","ギフトメッセージ","ギフト包装","メーカー製造中止","商品コードなしの理由","プラチナキーワード1","プラチナキーワード2","プラチナキーワード3","プラチナキーワード4","プラチナキーワード5","コート・ワンピース・チュニック着丈","アップデート・削除");
	my $csv_amazon_entry_data_name_2_num=@csv_amazon_entry_data_name_2;
	my $csv_amazon_entry_count_2=0;
	for my $csv_amazon_entry_name_2_str (@csv_amazon_entry_data_name_2) {
		Encode::from_to( $csv_amazon_entry_name_2_str, 'utf8', 'shiftjis' );
		$output_amazon_entry_data_csv->combine($csv_amazon_entry_name_2_str) or die $output_amazon_entry_data_csv->error_diag();
		my $post_fix_str="";
		if (++$csv_amazon_entry_count_2 >= $csv_amazon_entry_data_name_2_num) {
			$post_fix_str="\n";
		}
		else {
			$post_fix_str=",";
		}
		print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), $post_fix_str;
	}
	my @csv_amazon_entry_data_name_3=("sku","product-name","product-id","product-id-type","brand","clothing-type","department1","style-keyword1","bullet-point1","bullet-point2","bullet-point3","bullet-point4","bullet-point5","product-description","recommended-browse-node1","search-terms1","search-terms2","search-terms3","search-terms4","search-terms5","main-image-url","quantity","leadtime-to-ship","condition-type","condition-note","item-price","currency","size","size-map","color","color-map","style-name","shoe-width","heel-height-unit-of-measure","heel-height","strap-type","toe-shape","waist-style","material-opacity","heel-type","shaft-height","outer-material","shaft-diameter","occasion-lifestyle1","sleeve-type","apparel-closure-type","shoe-closure-type","parent-child","parent-sku","relationship-type","variation-theme","recommended-browse-node2","occasion-lifestyle2","occasion-lifestyle3","occasion-lifestyle4","occasion-lifestyle5","fabric-type","department2","style-keyword2","style-keyword3","style-keyword4","style-keyword5","is-adult-product","minimum-height-recommended-unit-of-measure","minimum-height-recommended","maximum-height-recommended-unit-of-measure","maximum-height-recommended","package-length-unit-of-measure","package-length","package-width","package-height","waist-size-unit-of-measure","waist-size","inseam-length-unit-of-measure","inseam-length","sleeve-length-unit-of-measure","sleeve-length","collar-style","neck-style","neck-size-unit-of-measure","neck-size","bottom-style","chest-size-unit-of-measure","chest-size","cup-size","furisode-length-unit-of-measure","furisode-length","furisode-width-unit-of-measure","furisode-width","obi-length-unit-of-measure","obi-length","obi-width-unit-of-measure","obi-width","tsukeobi-width-unit-of-measure","tsukeobi-width","tsukeobi-height-unit-of-measure","tsukeobi-height","pillow-size","pillow-size-unit-of-measure","swatch-image-url","other-image-url1","other-image-url2","other-image-url3","other-image-url4","other-image-url5","other-image-url6","other-image-url7","other-image-url8","shipping-weight-unit-measure","shipping-weight","package-weight-unit-of-measure","package-weight","launch-date","release-date","msrp","optional-payment-type-exclusion","sale-price","sale-from-date","sale-through-date","fulfillment-center-id","restock-date","model-year","season","max-order-quantity","max-aggregate-ship-quantity","is-gift-message-available","is-gift-wrap-available","is-discontinued-by-manufacturer","registered-parameter","platinum-keywords1","platinum-keywords2","platinum-keywords3","platinum-keywords4","platinum-keywords5","specific-uses-keywords","update-delete");
	my $csv_amazon_entry_data_name_3_num=@csv_amazon_entry_data_name_3;
	my $csv_amazon_entry_count_3=0;
	for my $csv_amazon_entry_name_3_str (@csv_amazon_entry_data_name_3) {
		Encode::from_to( $csv_amazon_entry_name_3_str, 'utf8', 'shiftjis' );
		$output_amazon_entry_data_csv->combine($csv_amazon_entry_name_3_str) or die $output_amazon_entry_data_csv->error_diag();
		my $post_fix_str="";
		if (++$csv_amazon_entry_count_3 >= $csv_amazon_entry_data_name_3_num) {
			$post_fix_str="\n";
		}
		else {
			$post_fix_str=",";
		}
		print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), $post_fix_str;
	}
	return 0;
}

##############################
## amazon_entry_data.csvファイルにデータを追加
##############################
sub add_amazon_entry_data {
	# 各値をCSVファイルに書き出す
	#商品管理番号
	$output_amazon_entry_data_csv->combine($global_entry_code) or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#商品名
	$output_amazon_entry_data_csv->combine(&output_name()) or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#商品コード(JANコード等)
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#商品コードのタイプ
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#ブランド名
	$output_amazon_entry_data_csv->combine($global_entry_category) or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#商品タイプ
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#対象年齢・性別1
	$output_amazon_entry_data_csv->combine(&output_sex()) or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#スタイルキーワード1
	my $style_keyword ="アパレル";
	Encode::from_to( $style_keyword, 'utf8', 'shiftjis' );
	$output_amazon_entry_data_csv->combine($style_keyword) or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#商品説明の箇条書き1~5
	# 出力するスペック項目を配列で取得する
	my $specs_num = @specs;
	my $specs_str_over5 ="";
	# サイズのある商品
	if(@$sabun_line[4] ne ""){
		for (my $i=0; $i<$specs_num; $i++){
			if($i==0){
				$output_amazon_entry_data_csv->combine(&output_spec_size()) or die $output_amazon_entry_data_csv->error_diag();
				print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
				$output_amazon_entry_data_csv->combine($specs[$i]) or die $output_amazon_entry_data_csv->error_diag();
				print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
			}
			# 4つめまでは単体で出力する
			elsif($i<=2){
				$output_amazon_entry_data_csv->combine($specs[$i]) or die $output_amazon_entry_data_csv->error_diag();
				print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
			}
			# 5つめ以上はすべて連結して出力
			elsif($i==3){
				$specs_str_over5 = $specs[$i];
			}
			else{
				$specs_str_over5 .= "/".$specs[$i];
			}
		}
	}
	#サイズのない商品
	else{
		for (my $i=0; $i<$specs_num; $i++){
			if($i<=3){
				$output_amazon_entry_data_csv->combine($specs[$i]) or die $output_amazon_entry_data_csv->error_diag();
				print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
			}
			# 5つめ以上はすべて連結して出力
			elsif($i==4){
				$specs_str_over5 = $specs[$i];
			}
			else{
				$specs_str_over5 .= "/".$specs[$i];
			}
		}
	}
	#商品説明の箇条書き5
	$output_amazon_entry_data_csv->combine($specs_str_over5) or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#商品説明文
	$output_amazon_entry_data_csv->combine(&output_supp()) or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#推奨ブラウズノード1
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#検索キーワード1
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#検索キーワード2
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#検索キーワード3
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#検索キーワード4
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#検索キーワード5
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#商品メイン画像URL
	my $global_entry_code_7 = substr(@$sabun_line[0],0,7);
	my $img_main_str ="http://glober.jp/img/amazon/1/".$global_entry_code_7."_1.jpg";
	$output_amazon_entry_data_csv->combine($img_main_str) or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#在庫数
	my $quantity =0;
	if (length($global_entry_code)==5){$quantity = "";}
	$output_amazon_entry_data_csv->combine($quantity) or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#リードタイム(出荷までにかかる作業日数)
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#商品のコンディション
	my $condition_str="";
	if (length($global_entry_code)==5){$condition_str = "";}
	else{$condition_str ="New";}
	$output_amazon_entry_data_csv->combine($condition_str) or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#商品のコンディション説明
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#商品の販売価格
	if (length($global_entry_code)==5){$global_entry_price = "";}
	else{$global_entry_price =@$sabun_line[3];}
	$output_amazon_entry_data_csv->combine($global_entry_price) or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#通貨コード
	my $currency_code="";
	if (length($global_entry_code)==5){$currency_code = "";}
	else{$currency_code ="JPY";}
	$output_amazon_entry_data_csv->combine($currency_code) or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#サイズ
	if (length($global_entry_code)==5){$global_entry_size = "";}
	else{$global_entry_size=@$sabun_line[4];}
	$output_amazon_entry_data_csv->combine($global_entry_size) or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#サイズマップ
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#カラー
	my $color_str ="";
	if (length($global_entry_code)==5){$color_str = "";}
	else{$color_str = $global_entry_color;}
	$output_amazon_entry_data_csv->combine($color_str) or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#カラーマップ
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#スタイル名
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#靴の幅
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#ヒールの高さの単位
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#ヒールの高さ
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#ストラップのタイプ
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#つま先の形状(トゥシェープ)
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#ウエストのスタイル
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#素材不透明度
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#ヒールのタイプ
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#シャフト(軸)の丈
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#表地素材
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#シャフト(軸)の直径
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#ライフスタイル1
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#袖のタイプ
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#留め具のタイプ
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#留め具のタイプ
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#親子指定
	my $identify_p_c_str="";
	if (length($global_entry_code)==5){$identify_p_c_str = "parent";}
	else{$identify_p_c_str ="child";}
	$output_amazon_entry_data_csv->combine($identify_p_c_str) or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#親商品のSKU(商品管理番号)
	my $parent_code="";
	if (length($global_entry_code)==5){$parent_code = "";}
	else{$parent_code = $global_entry_code_5;}
	$output_amazon_entry_data_csv->combine($parent_code) or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#親子関係のタイプ
	my $variation_str="";
	if (length($global_entry_code)==5){$variation_str = "";}
	else{$variation_str ="Variation";}
	$output_amazon_entry_data_csv->combine($variation_str) or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#バリエーションテーマ
	my $var_str ="";
	$global_entry_size=@$sabun_line[4];
	if (!$global_entry_size){$var_str = "Color";}
	else{$var_str = "Sizecolor";}
	$output_amazon_entry_data_csv->combine($var_str) or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#推奨ブラウズノード2
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#ライフスタイル2
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#ライフスタイル3
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#ライフスタイル4
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#ライフスタイル5
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#素材または繊維1
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#対象年齢・性別2
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#スタイルキーワード2
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#スタイルキーワード3
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#スタイルキーワード4
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#スタイルキーワード5
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#アダルト商品
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#推奨最低身長の単位
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#推奨最低身長
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#推奨最高身長の単位
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#推奨最高身長
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#商品パッケージの長さの単位
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#商品パッケージの長さ
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#商品パッケージの幅
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#商品パッケージの高さ
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#ウエストサイズの単位
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#ウエストサイズ
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#仕立ての長さの単位
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#仕立ての長さ
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#袖の長さの単位
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#袖の長さ
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#シャツカラースタイル
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#首のタイプ
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#首のサイズの単位
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#首のサイズ
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#ボトムススタイル
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#胸囲サイズの単位
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#胸囲サイズ
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#カップサイズ
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#振袖の長さの単位
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#振袖の長さ
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#振袖の幅の単位
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#振袖の幅
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#帯の長さの単位
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#帯の長さ
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#帯の幅の単位
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#帯の幅
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#付け帯の幅の単位
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#付け帯の幅
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#付け帯の高さの単位
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#付け帯の高さ
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#枕サイズ
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#枕サイズの単位
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#カラーサンプル画像URL~商品のサブ画像URL8
	my $img_str ="";
	for (my $i =1; $i<=9; $i++){
		my $img_str ="http://glober.jp/img/amazon/".$i."/".$global_entry_code_7."_".$i.".jpg";
		$output_amazon_entry_data_csv->combine($img_str) or die $output_amazon_entry_data_csv->error_diag();
		print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	}
	#配送重量の単位
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#配送重量
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#商品パッケージの重量の単位
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#商品パッケージの重量
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#商品の公開日
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#予約商品の販売開始日
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#メーカー希望小売価格
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#使用しない支払い方法
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#セール価格
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#セール開始日
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#セール終了日
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#フルフィルメントセンターID
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#商品の入荷予定日
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#モデル年(発売年・発表年)
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#シーズン
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#最大注文個数
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#最大同梱可能個数
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#ギフトメッセージ
	my $gift_str="false";
	$output_amazon_entry_data_csv->combine($gift_str) or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#ギフト包装
	my $gift_package_str="false";
	$output_amazon_entry_data_csv->combine($gift_package_str) or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#メーカー製造中止
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#商品コードなしの理由
	my $product_reason ="PrivateLabel";
	$output_amazon_entry_data_csv->combine($product_reason) or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#プラチナキーワード1
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#プラチナキーワード2
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#プラチナキーワード3
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#プラチナキーワード4
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#プラチナキーワード5
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#コート・ワンピース・チュニック着丈
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), ",";
	#アップデート・削除
	$output_amazon_entry_data_csv->combine("") or die $output_amazon_entry_data_csv->error_diag();
	#最後に改行を追加
	print $output_amazon_entry_data_disc $output_amazon_entry_data_csv->string(), "\n";
	return 0;
}

##############################
############ 関数 ############
##############################

#########################
###  商品名作成 ###
#########################

sub output_name {
	my $info_name ="";
	my $str ="【正規販売店】";
	Encode::from_to( $str, 'utf8', 'shiftjis' );
	if(length($global_entry_code) == 5){
		$info_name = $global_entry_category.$global_entry_name." ".$str;
	}
	else{
		$info_name = $global_entry_category.$global_entry_name." ".$global_entry_color." ".$global_entry_size." ".$str;
	}
	$info_name =~ s/  / /g;
	return $info_name;
}

#########################
###  性別を出力 ###
#########################
sub output_sex {
	# 性別判定
	my $sex_str ="";
	$sex_flag = 0;
	my $ladys_find_str = "WOMEN'S";
	my $kids_find_str = "キッズ";
	Encode::from_to( $kids_find_str, 'utf8', 'shiftjis' );	
	# ブランド名にレディースが入っていればレディーズ
	if($global_entry_category =~ /$ladys_find_str/){
		$sex_str = "レディーズ";
	}
	# 商品名にキッズの文字列があればキッズの商品
	elsif($global_entry_name =~ /$kids_find_str/){
		$sex_str = "ボーイズ";
	}
	else{
		$sex_str = "メンズ";
	}
	Encode::from_to( $sex_str, 'utf8', 'shiftjis' );	
	return $sex_str;
}

#########################
###  スペック作成 ###
#########################

# スペックのサイズを出力する
sub output_spec_size {
	my $output_spec_size_str="";
	my $signal_before ="【";
	Encode::from_to( $signal_before, 'utf8', 'shiftjis' );
	my $signal_after ="】";
	Encode::from_to( $signal_after, 'utf8', 'shiftjis' );
	my $spec_size_str ="サイズ";
	Encode::from_to( $spec_size_str, 'utf8', 'shiftjis' );
	my $spec_size_count = @spec_size_info;
	my $size_str ="";
	for (my $num = 0; $num<$spec_size_count; $num++){
		if($num == 0){
			$size_str = $spec_size_info[$num];
		}
		else {
			$size_str .= " ".$spec_size_info[$num];
		}
	}
	$output_spec_size_str = $signal_before.$spec_size_str.$signal_after.$size_str;
	return $output_spec_size_str;
}

# スペックリストを作成する
sub get_output_spec_list {
	my $output_spec_str ="";
	my $spec_count = @global_entry_goods_spec_info;
	foreach my $spec_sort_num ( @globel_spec_sort ) {
		for (my $i=0; $i < $spec_count; $i+=2) {
			if ($global_entry_goods_spec_info[$i] ne $spec_sort_num) {
				next;
			}
			my $spec_name = &get_spec_info_from_xml($global_entry_goods_spec_info[$i]);
			my $spec_info = $global_entry_goods_spec_info[$i+1];
#			Encode::from_to( $spec_info, 'utf8', 'shiftjis' );
			if ($global_entry_goods_spec_info[$i] == 7) {
				# ギフトのパッケージ名を変換
				my $gift_name="GLOBERオリジナルパッケージ";
				Encode::from_to( $gift_name, 'utf8', 'shiftjis' );
				chomp $global_entry_goods_spec_info[$i+1];
				if ($spec_info eq $gift_name) {
					$spec_info = "当店オリジナルパッケージ";
					Encode::from_to( $spec_info, 'utf8', 'shiftjis' );
				}
			}
			my $signal_before ="【";
			Encode::from_to( $signal_before, 'utf8', 'shiftjis' );
			my $signal_after ="】";
			Encode::from_to( $signal_after, 'utf8', 'shiftjis' );
			$output_spec_str =$signal_before.$spec_name.$signal_after.$spec_info;
			my $str_before_1 = "<br.*>";
			my $str_after_1 = "/";
			$output_spec_str =~ s/$str_before_1/$str_after_1/g;
			push(@specs, $output_spec_str);
		}
	}
}

#########################
###  商品説明文を作成する ###
#########################

sub output_supp{
	my $info_supp="";
	# スマホ用のタグを削除
	my $info_supp_str_1 = $global_entry_goods_supp_info[0] || "";
	my $info_supp_str_2 = $global_entry_goods_supp_info[1] || "";
	my $info_str_before_1 ="<span class=\"itemComment\">";
	my $info_str_after_1 ="";
	$info_supp_str_1 =~ s/$info_str_before_1/$info_str_after_1/g;
	my $info_str_before_2 ="</span>";
	my $info_str_after_2 ="";
	$info_supp_str_1 =~ s/$info_str_before_2/$info_str_after_2/g;
	$info_supp = $info_supp_str_1;
	if($info_supp_str_2 ne "") {
		# 商品コメント2を取得
		my $before_rep_str1="\n\n";
		my $after_rep_str1="\n";
		$info_supp_str_2 =~ s/$before_rep_str1/$after_rep_str1/g;
		# 1行ごとにサイズ要素のみの配列を作る
		my $before_str2="<table class=\"infoTable\"><tr><td><table>";
		my $after_str2="";
		$info_supp_str_2 =~ s/$before_str2/$after_str2/g;
		# 1行ごとにサイズ要素のみの配列を作る
		my $before_str3="<\/table><\/td><\/tr><\/table>";
		my $after_str3="";	
		$info_supp_str_2 =~ s/$before_str3/$after_str3/g;
		# スマホ用のタグを削除
		my $before_str4="<span>";
		my $after_str4="";	
		$info_supp_str_2 =~ s/$before_str4/$after_str4/g;
		# スマホ用のタグを削除
		my $before_str5="</span>";
		my $after_str5="";	
		$info_supp_str_2 =~ s/$before_str5/$after_str5/g;
		# スマホ用サイズチャートのヘッダー
		my $sizechart_header = "<br /><br />【サイズチャート】" || "";
		Encode::from_to( $sizechart_header, 'utf8', 'shiftjis' );
		# GLOBERのサイズチャートを改行で分割して配列にする
		my @goods_info_str_list_tr = split(/<tr>/, $info_supp_str_2);
		my @goods_info_str_list_sub = split(/<\/th>/, $goods_info_str_list_tr[1]);
		# GLOBERのサイズチャートの行数を格納する
		my $goods_info_str_list_count=@goods_info_str_list_tr;
		# スマホサイズチャートを宣言
		my $smp_sizechart ="$sizechart_header";
		#GLOBERのサイズチャートを<tr>の行ごとに読み込み、1行ずつ処理して変数に追加していく。
		my $i=2;
		# 1行<tr>にあたりにおけるサイズの項目数
		my $size_i=0;
		while ($i <= $goods_info_str_list_count-1){
			# 1行ごとにサイズ要素のみの配列を作る
			my $before_str1="<\/tr>";
			my $after_str1="";	
			$goods_info_str_list_tr[$i] =~ s/$before_str1/$after_str1/g;
			my @goods_info_str_list_size = split(/<\/td><td>/, $goods_info_str_list_tr[$i]);
			# サイズの要素数を格納する
			my $goods_info_str_list_size_count=@goods_info_str_list_size;
			# サイズ要素数が1つのとき
			if ($goods_info_str_list_size_count ==2){
				if ($size_i==0){
					my $before_str_1="<td class=\'col01\'>";
					my $before_str_2="<td class=\"col01\">";
					my $after_str="<br />";	
					$goods_info_str_list_size[$size_i] =~ s/$before_str_1/$after_str/g;
					$goods_info_str_list_size[$size_i] =~ s/$before_str_2/$after_str/g;
					$goods_info_str_list_size[$size_i] = "$goods_info_str_list_size[$size_i]";
					$smp_sizechart .= $goods_info_str_list_size[$size_i];
					$size_i++;
					next;
				}
				else {
					# サイズ項目の余計な文字列を削除
					my $before_str="<th>";
					my $after_str="";	
					$goods_info_str_list_sub[$size_i] =~ s/$before_str/$after_str/g;
					# サイズ項目の余計な文字列を削除
					my $before_str_1="<\/tr>";
					my $after_str_1="";	
					$goods_info_str_list_sub[$size_i] =~ s/$before_str_1/$after_str_1/g;
					# サイズ要素の余計な文字列を削除
					my $before_str_2="<\/td><\/tr>";
					my $after_str_2="";	
					$goods_info_str_list_size[$size_i] =~ s/$before_str_2/$after_str_2/g;
					# サイズ要素の余計な文字列を削除
					my $before_str_3="<\/td>";
					my $after_str_3="";	
					$goods_info_str_list_size[$size_i] =~ s/$before_str_3/$after_str_3/g;
					# サイズ要素の余計な文字列を削除
					my $before_str_4="<\/tr>";
					my $after_str_4="";	
					$goods_info_str_list_size[$size_i] =~ s/$before_str_4/$after_str_4/g;
					chomp($goods_info_str_list_size[$size_i]);
					$smp_sizechart .= "("."$goods_info_str_list_sub[$size_i]"."$goods_info_str_list_size[$size_i]".")";
					$size_i=0;
					$i++;
				}
			}
			# サイズ要素数が2以上のとき
			else{
				# サイズ要素のみの配列を1つずつサイズの要素とサイズ項目を組み合わせてスマホ用サイズチャートを作る
				# 1番目はサイズで余分な文字列を省き、ヘッダーを追加してサイズチャートに格納する
				if ($size_i==0){
					my $before_str_1="<td class=\'col01\'>";
					my $before_str_2="<td class=\"col01\">";
					my $after_str="<br />";	
					$goods_info_str_list_size[$size_i] =~ s/$before_str_1/$after_str/g;
					$goods_info_str_list_size[$size_i] =~ s/$before_str_2/$after_str/g;
					$goods_info_str_list_size[$size_i] = "$goods_info_str_list_size[$size_i]";
					$smp_sizechart .= $goods_info_str_list_size[$size_i];
					$size_i++;
					next;
				}
				# 2番目はサイズ要素のスタートなので、（をつけて1番目のサイズ項目を組み合わせてサイズチャートに格納する
				elsif($size_i==1 ){
					# サイズ項目の余計な文字列を削除
					my $before_str="<th>";
					my $after_str="";	
					$goods_info_str_list_sub[$size_i] =~ s/$before_str/$after_str/g;
					# サイズ項目の余計な文字列を削除
					my $before_str_1="<\/tr>";
					my $after_str_1="";	
					$goods_info_str_list_sub[$size_i] =~ s/$before_str_1/$after_str_1/g;
					# サイズ要素の余計な文字列を削除
					my $before_str_2="<\/td><\/tr>";
					my $after_str_2="";	
					$goods_info_str_list_size[$size_i] =~ s/$before_str_2/$after_str_2/g;
					# サイズ要素の余計な文字列を削除
					my $before_str_3="<\/td>";
					my $after_str_3="";	
					$goods_info_str_list_size[$size_i] =~ s/$before_str_3/$after_str_3/g;
					# サイズ要素の余計な文字列を削除
					my $before_str_4="<\/tr>";
					my $after_str_4="";	
					$goods_info_str_list_size[$size_i] =~ s/$before_str_4/$after_str_4/g;
					chomp($goods_info_str_list_size[$size_i]);
					$smp_sizechart .= "("."$goods_info_str_list_sub[$size_i]"."$goods_info_str_list_size[$size_i]";
					$size_i++;
					next;
				}
				elsif($size_i<$goods_info_str_list_size_count-1){
					# サイズ項目の余計な文字列を削除
					my $before_str_0="<th>";
					my $after_str_0="";	
					$goods_info_str_list_sub[$size_i] =~ s/$before_str_0/$after_str_0/g;
					# サイズ項目の余計な文字列を削除
					my $before_str_1="<\/tr>";
					my $after_str_1="";	
					$goods_info_str_list_sub[$size_i] =~ s/$before_str_1/$after_str_1/g;
					# サイズ要素の余計な文字列を削除
					my $before_str_2="<\/tr>";
					my $after_str_2="";	
					$goods_info_str_list_size[$size_i] =~ s/$before_str_2/$after_str_2/g;
					# サイズ要素の余計な文字列を削除
					my $before_str_3="<\/td><\/tr>";
					my $after_str_3="";	
					$goods_info_str_list_size[$size_i] =~ s/$before_str_3/$after_str_3/g;
					chomp($goods_info_str_list_size[$size_i]);
					$smp_sizechart .= "/"."$goods_info_str_list_sub[$size_i]"."$goods_info_str_list_size[$size_i]";
					$size_i++;
					next;
				}
				else{
					# サイズ項目の余計な文字列を削除
					my $before_str_0="<th>";
					my $after_str_0="";	
					$goods_info_str_list_sub[$size_i] =~ s/$before_str_0/$after_str_0/g;
					# サイズ項目の余計な文字列を削除
					my $before_str_1="<\tr>";
					my $after_str_1="";	
					$goods_info_str_list_sub[$size_i] =~ s/$before_str_1/$after_str_1/g;
					# サイズ要素の余計な文字列を削除
					my $before_str_2="<\/td><\/tr>";
					my $after_str_2="";	
					$goods_info_str_list_size[$size_i] =~ s/$before_str_2/$after_str_2/g;
					# サイズ要素の余計な文字列を削除
					my $before_str_3="<\/tr>";
					my $after_str_3="";	
					$goods_info_str_list_size[$size_i] =~ s/$before_str_3/$after_str_3/g;
					# サイズ要素の余計な文字列を削除
					my $before_str_4="<\/td>";
					my $after_str_4="";	
					$goods_info_str_list_size[$size_i] =~ s/$before_str_4/$after_str_4/g;
					chomp($goods_info_str_list_size[$size_i]);
					$smp_sizechart .= "/"."$goods_info_str_list_sub[$size_i]"."$goods_info_str_list_size[$size_i]".")";
					$size_i=0;
					$i++;
				}
			}
		}
		$info_supp .="$smp_sizechart";
	}
	my $info_str_end ="<br /><br />・ディスプレイにより、実物と色、イメージが異なる事がございます。あらかじめご了承ください。<br />・当店では、他店舗と在庫データを共有しているため、まれに売り切れや入荷待ちの場合がございます。<br /><br />【 正規販売店 GLOBER.jp 】";
	Encode::from_to( $info_str_end, 'utf8', 'shiftjis' );
	$info_supp.= $info_str_end;
	my $before_n="\n";
	my $after_n="";
	$info_supp =~ s/$before_n/$after_n/g;
	return $info_supp;
}

#####################
### ユーティリティ関数 ###
#####################

#########################
###  ブランド名を取得する ###
#########################

sub get_info_from_xml {
	my $info_name = $_[0]; 
	#brand.xmlからブランド名を取得
	my $xml = XML::Simple->new;
	# XMLファイルのパース
	my $xml_data = $xml->XMLin("$brand_xml_filename",ForceArray=>['brand']);
	# XMLからカテゴリを取得
	my $count=0;
	my $info="";
	while(1) {
		# XMLからカテゴリ名を取得
		my $xml_category_name = $xml_data->{brand}[$count]->{category_name};
		if (!$xml_category_name) {
			# 全て読み出したら終了
			last;
		}
		Encode::_utf8_off($xml_category_name);
		Encode::from_to( $xml_category_name, 'utf8', 'shiftjis' );
		# カテゴリ名のチェック
		if ($sabun_category eq $xml_category_name){
			$info = $xml_data->{brand}[$count]->{$info_name};
			Encode::_utf8_off($info);
			Encode::from_to( $info, 'utf8', 'shiftjis' );
			last;
		}
		$count++;
	}
	return $info;
}

#########################
###  スペックの優先順位を取得 ###
#########################

sub get_spec_sort_from_xml {
	#goods_spec.xmlからブランド名を取得
	my $xml = XML::Simple->new;
	# XMLファイルのパース
	my $xml_data = $xml->XMLin("$goods_spec_xml_filename",ForceArray=>['spec']);
	# XMLからカテゴリを取得し、ハッシュに一時的に保持する
	my $count=0;
	my $info="";
	my %temp_spec_sort;
	while(1) {
		my $xml_spec_sort_num = $xml_data->{spec}[$count]->{spec_sort_num};
		my $xml_spec_number = $xml_data->{spec}[$count]->{spec_number};
		if (!$xml_spec_sort_num) {
			# 情報を取得できなかったら終了
			last;
		}
		$temp_spec_sort{$xml_spec_sort_num}=$xml_spec_number;
		$count++;
	}	
	# スペック情報のソート順を配列変数に格納する
	my @spec_sort;
	foreach my $key ( sort { $a <=> $b } keys %temp_spec_sort ) { 
		push(@spec_sort, $temp_spec_sort{$key});
	}
	return @spec_sort;
}

#########################
###  スペック名を取得する ###
#########################

sub get_spec_info_from_xml {
	my $spec_number = $_[0]; 
	#goods_spec.xmlからブランド名を取得
	my $xml = XML::Simple->new;
	# XMLファイルのパース
	my $xml_data = $xml->XMLin("$goods_spec_xml_filename",ForceArray=>['spec']);
	# XMLからカテゴリを取得
	my $count=0;
	my $info="";
	while(1) {
		# XMLからカテゴリ名を取得
		my $xml_spec_number = $xml_data->{spec}[$count]->{spec_number};
		Encode::_utf8_off($xml_spec_number);
		Encode::from_to( $xml_spec_number, 'utf8', 'shiftjis' );
		$info = $xml_data->{spec}[$count]->{spec_name};
		if (!$info) {
			# 情報を取得できなかったので、終了
			output_log("not exist spec_number($spec_number) in $goods_spec_xml_filename\n");
			last;
		}
		Encode::_utf8_off($info);
		Encode::from_to( $info, 'utf8', 'shiftjis' );
		if ($spec_number == $xml_spec_number){
			last;
		}
		$count++;
	}
	return $info;
}

## ログ出力
sub output_log {
	my $day=&to_YYYYMMDD_string();
	print "[$day]:$_[0]";
	print LOG_FILE "[$day]:$_[0]";
}

## 現在日時取得関数
sub to_YYYYMMDD_string {
  my $time = time();
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
  my $result = sprintf("%04d%02d%02d %02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec);
  return $result;
}