@echo off
echo /
echo / GLOBER�ɓo�^����Ă���f�[�^�����ɃA�}�]���X�ɓo�^���鏤�i
echo / �f�[�^���쐬����
echo /
echo [�菇]
echo --------------------------------------------------------
echo  1. ���s�ɕK�v�ȃt�@�C���ꎮ�����݂��Ă��鎖���m�F����B
echo     -amazon_entry_data.bat
echo     +exe
echo       -amazon_entry_data.pl
echo  2. ���L�̕K�v�ȃt�@�C���ꎮ���o�b�`�Ɠ���t�H���_�ɔz�u����B
echo     -sabun_YYYYMMDD.csv
echo     -genre_goods.csv
echo	 -category_amazon.csv
echo	 -category_amazon.csv
echo	 -goods_spec.csv
echo	 -goods_supp.csv
echo  3. ��L�t�@�C�������������݂��鎖���m�F���Ă��珈���𑱍s����B
echo  4. amazon_entry_data.csv���o�͂����
echo --------------------------------------------------------
echo ----- �f�[�^���o����(amazon_entry_data.pl)�����s���܂� -----
PAUSE
echo �f�[�^���o����(amazon_entry_data.pl)�����s���Ă��܂�...

CD ./exe
perl -X amazon_entry_data.pl

echo �f�[�^���o����(amazon_entry_data.pl)�̎��s���������܂����B

PAUSE

END
