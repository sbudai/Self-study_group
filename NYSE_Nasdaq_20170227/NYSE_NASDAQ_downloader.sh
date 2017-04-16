#!/bin/bash

# README
# I wrote, tested and ran it on Ubuntu 16.04.
# It may require such kind of packages which are basically not installed by default.
# I suggest to run the following installer line in terminal:
# sudo apt-get install mawk coreutils curl findutils sed perl libeigen3-dev libarpack2-dev
# You should put the following content( https://github.com/jeroenjanssens/data-science-at-the-command-line/blob/master/tools/header )
# into an editor and save as header in your home folder. Then move it into /usr/local/bin folder and finally make it executable.
# touch header
# gedit header
# <paste content of https://github.com/jeroenjanssens/data-science-at-the-command-line/blob/master/tools/header in>
# sudo cp header /usr/local/bin/header
# rm -f header
# sudo chmod +755 /usr/local/bin/header

clear
set -e

# let's assign values to necessary variables
begin=$(date +"%s")
WD=$(pwd)
part_A="http://chart.finance.yahoo.com/table.csv?s="
part_1="&a=0&b=1&c=1900&d=$"
month=$(date +'%m')
let part_2=month-1
part_3="&e=$"
part_4=$(date +'%d')
part_5="&f=$"
part_6=$(date +'%Y')
part_7="&g=d&ignore=.csv"
part_B=$part_1$part_2$part_3$part_4$part_5$part_6$part_7
thrd=$(nproc)
let thrd=thrd*10

# let's ask whether current folder is ok?
echo -n "You are in "
echo -n $WD
echo " folder."
echo "Do you want to download company list here?"
echo -n "(y/n): " 
read DJ
if [ $DJ = "n" ]; then
	echo -n "Which subfolder do you choose instead?: "
	echo -n $WD
	read SD
	cd $WD$SD
	WD=$(pwd)
	echo "Downloading company list has started."
else if [ $DJ = "y" ]; then
		echo "Downloading company list has started."
	else
		echo "Wrong answer."
		exit
	fi
fi

# let the party begin


# if previous results have already been presented then I delete them
rm -f comp_list.csv
rm -f history_data.csv

# it parallelly downloads the company lists
parallel --link --jobs $thrd --eta --bar --gnu curl -sL -w time_total -o {1} {2} ::: comp_list_nasdaq.csv comp_list_nyse.csv ::: "http://www.nasdaq.com/screening/companies-by-name.aspx?letter=0&exchange=nasdaq&render&render=download" "http://www.nasdaq.com/screening/companies-by-name.aspx?letter=0&exchange=nyse&render&render=download" &
wait

# appends those 2 files
cat comp_list_nyse.csv | header -d >> comp_list_nasdaq.csv

# fills empty spaces up with n/a
sed 's/,\"\"/,\"n\/a\"/g' comp_list_nasdaq.csv > comp_list.csv

# replaces commas to | between double quotes
sed -i 's/\",\"/\"|\"/g' comp_list.csv

# drops commas after last column
perl -pe 's|,\r\n|\n|' comp_list.csv > temp.csv

# trims every lines
sed 's/^[ \t]*//;s/[ \t]*$//' temp.csv > comp_list.csv

# removes every TAB
sed -i 's/\t//g' comp_list.csv

# replaces every double space for simple ones
sed -i 's/  / /g' comp_list.csv

# and once more: replaces every double space for simple ones
sed -i 's/  / /g' comp_list.csv

# and once more: replaces every double space for simple ones
sed -i 's/  / /g' comp_list.csv

# and once more: replaces every double space for simple ones
sed -i 's/  / /g' comp_list.csv

# and once more: replaces every double space for simple ones
sed -i 's/  / /g' comp_list.csv

# and once more: replaces every double space for simple ones
sed -i 's/  / /g' comp_list.csv

# replaces ^ character for dot in first column
awk -F"|" -v OFS="|" '{sub(/\^/,".",$1); print}' 2>/dev/null comp_list.csv > temp.csv

# drops double quotes from 3th column
awk -F"|" -v OFS="|" '{if($3!~"n\/a" && $3!~"LastSale") gsub(/\"/,"",$3); print}' 2>/dev/null temp.csv > comp_list.csv

# drops $ signs from 4th column
awk -F"|" -v OFS="|" '{sub(/\$/,"",$4); print}' 2>/dev/null comp_list.csv > temp.csv

# drops M character from 4th column
awk -F"|" -v OFS="|" '{if($4!~"MarketCap") sub(/M/,"",$4); print}' 2>/dev/null temp.csv > comp_list.csv

# recomputes billions to millions in 4th column, and drops M and B characters and double quotes
awk -F"|" -v OFS="|" '{$9=1; print}' 2>/dev/null comp_list.csv > temp.csv
awk -F"|" -v OFS="|" '{if($4~/B/) $9=1000; print}' 2>/dev/null temp.csv > comp_list.csv
awk -F"|" -v OFS="|" '{sub(/B/,"",$4); print}' 2>/dev/null comp_list.csv > temp.csv
awk -F"|" -v OFS="|" '{if($4!~"n\/a" && $4!~"MarketCap") gsub(/\"/,"",$4); print}' 2>/dev/null temp.csv > comp_list.csv
awk -F"|" -v OFS="|" '{if($4!~"n\/a" && $4!~"MarketCap") $4=$4*$9; print}' 2>/dev/null comp_list.csv > temp.csv

# drops 5th, 8th and 9th columns
cut --delimiter="|" -f5,8,9 --complement temp.csv > comp_list.csv

echo "The comp_list.csv is now ready!"
echo
echo "Historical data download has started."


# drops all those companies which symbol contain dot
awk -F"|" -v OFS="|" '$1 !~ "\\."' comp_list.csv > temp.csv

# drops header
sed -i '1d' temp.csv

# creates a filename & link list
awk -F"|" -v OFS=" " '{gsub(/\"/,"",$1); print}' 2>/dev/null temp.csv > comp_list_mod.csv
awk -F" " '{print $1}' comp_list_mod.csv > temp.csv
awk -v OFS=" " '{$2=$1; print $1, $2}' temp.csv > comp_list_mod.csv
awk -F" " -v OFS=" " -v x=$part_A '$2=x $1' comp_list_mod.csv > temp.csv
awk -F" " -v OFS=" " -v y=$part_B '$2=$2 y' temp.csv > comp_list_mod.csv

# creates the "tables" subfolder and steps into it
mkdir tables
cd tables

# paralelly downloads all historical files
dlbegin=$(date +"%s")
parallel --jobs $thrd --eta --bar --gnu --colsep ' ' curl -sL -o {1} {2} :::: $WD/comp_list_mod.csv &
wait
dltermin=$(date +"%s")
dldifftimelps=$(($dltermin-$dlbegin))
echo "$(($dldifftimelps / 60)) minutes and $(($dldifftimelps % 60)) seconds elapsed for history files download execution."

# creating new file with appropiate header
first=$(ls | sort -n | head -1)
head -n+1 $first > $WD/temp.csv
awk -F"," -v OFS="," '{$8="Symbol"; print}' 2>/dev/null $WD/temp.csv > $WD/history_data.csv

echo
echo "Appending those historical files into one."

# adds filename into last column in each and every downloaded historical file + appending them into one
# dropping wrong files
for filename in *; do 
	mimet=$(file --mime-type $filename | perl -p -e 's/^\s+|\s+$//g' | tail -c 9)
	case "$mimet" in
	ext/plain) sed "s/$/,$filename/" "$filename" | tail -n+2 >> $WD/history_data.csv
		;;
	*) rm -f $filename
		;;
	esac &
	wait
done &	
wait
cd ..
echo "The history_data.csv has completed!"
echo

# let's drop unnecessary files & variables
rm -f $WD/temp.csv
rm -f $WD/comp_list_nasdaq.csv
rm -f $WD/comp_list_nyse.csv
rm -f $WD/comp_list_mod.csv
rm -rf tables
unset WD
unset part_1
unset month
unset part_2
unset part_3
unset part_4
unset part_5
unset part_6
unset part_7
unset part_A
unset part_B
unset first
unset thrd
unset dlbegin
unset dltermin
unset dldifftimelps

# let us compute elapsed time
termin=$(date +"%s")
difftimelps=$(($termin-$begin))
echo "$(($difftimelps / 60)) minutes and $(($difftimelps % 60)) seconds elapsed for whole script execution."

# let's drop the remaining variables
unset begin
unset termin
unset difftimelps

