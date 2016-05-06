#! /bin/sh
for file in EastAsianWidth.txt UnicodeData.txt
do
	wget ftp://ftp.unicode.org/Public/UNIDATA/${file} -P lib/unicode
done
