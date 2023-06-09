#!/bin/bash
#Purpose: down 2020 DailyImmigPort data.
#Create-Date: 2023-05-24

# Text color setting
NC="\033[0m" # Color reset
BLACK="\033[0;30m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
CYAN="\033[0;36m"
WHITE="\033[0;37m"

dataset_list="
https://data.moi.gov.tw/MoiOD/System/DownloadFile.aspx?DATA=EEEBDF54-B1CC-42D8-8375-ADFEE149EB2C
https://data.moi.gov.tw/MoiOD/System/DownloadFile.aspx?DATA=1AF0ADAD-F262-4AF5-8F43-FB83A3448AA0
https://data.moi.gov.tw/MoiOD/System/DownloadFile.aspx?DATA=8099181F-15F1-4EBF-AA57-A0B10C755615
https://data.moi.gov.tw/MoiOD/System/DownloadFile.aspx?DATA=016CB666-09D4-46CD-A3AE-1BF86899E146
https://data.moi.gov.tw/MoiOD/System/DownloadFile.aspx?DATA=15112836-06E1-4058-A947-5BFABFFD94A2
https://data.moi.gov.tw/MoiOD/System/DownloadFile.aspx?DATA=764BA741-C68E-41DC-ACD4-78E5569CFDA1
https://data.moi.gov.tw/MoiOD/System/DownloadFile.aspx?DATA=9A092C4D-7308-4003-BAD9-02D327FCA615
https://data.moi.gov.tw/MoiOD/System/DownloadFile.aspx?DATA=49390CCA-4672-45CC-9586-0E8DFBEA4F3E
https://data.moi.gov.tw/MoiOD/System/DownloadFile.aspx?DATA=8F45B4FC-0CD8-40F4-818E-D46E32E76D41
https://data.moi.gov.tw/MoiOD/System/DownloadFile.aspx?DATA=92790B45-C4DC-4AAD-B56B-B44A02C63FFC
https://data.moi.gov.tw/MoiOD/System/DownloadFile.aspx?DATA=58018F40-0223-4C59-BA9C-30EB2575091C
https://data.moi.gov.tw/MoiOD/System/DownloadFile.aspx?DATA=727BB9F6-82BA-4B9C-9F62-1099FC3A8EED"

date="202001"

ls ~/2020_DailyImmigPort &> /dev/null
[ $? == 0 ] && rm -r ~/2020_DailyImmigPort
hdfs dfs -ls hive-work/2020_DailyImmigPort &> /dev/null
[ $? == 0 ] && hdfs dfs -rm -r hive-work/2020_DailyImmigPort

ls ~/2020_DailyImmigPort/{original-data,fix-data} &> /dev/null
[ $? != 0 ] && mkdir -p ~/2020_DailyImmigPort/{original-data,fix-data}

hdfs dfs -ls hive-work/2020_DailyImmigPort &> /dev/null
[ $? != 0 ] && hdfs dfs -mkdir hive-work/2020_DailyImmigPort &> /dev/null || hdfs dfs -rm -r hive-work/2020_DailyImmigPort/* &> /dev/null

for list in ${dataset_list}
do
  wget "${list}" -O ~/2020_DailyImmigPort/${date}_DailyImmigPort.zip > /dev/null 2>&1
  [ $? == 0 ] && echo -e " [${GREEN}●${NC}] ${date}_DailyImmigPort.zip download success." || echo -e " [${RED}●${NC}] ${date}_DailyImmigPort.zip download failed."

  original=$(unzip -l ~/2020_DailyImmigPort/${date}_DailyImmigPort.zip | grep "${date}" | tail -n 1 | awk '{ print $4 }')
  fix=$(unzip -l ~/2020_DailyImmigPort/${date}_DailyImmigPort.zip | grep "${date}" | tail -n 1 | awk '{ print $4 }' | sed 's/.csv/_Fix.csv/g')
  unzip ~/2020_DailyImmigPort/${date}_DailyImmigPort.zip ${original} -d ~/2020_DailyImmigPort/original-data/ &> /dev/null
  [ $? == 0 ] && echo -e " [${GREEN}●${NC}] ${date}_DailyImmigPort.zip unzip success." || echo -e " [${RED}●${NC}] ${date}_DailyImmigPort.zip unzip failed."

  ls ~/2020_DailyImmigPort/original-data/${original} &> /dev/null
  [ $? == 0 ] && rm ~/2020_DailyImmigPort/${date}_DailyImmigPort.zip

  cat ~/2020_DailyImmigPort/original-data/${original} | cut -d ',' -f 1,2,39 > ~/2020_DailyImmigPort/fix-data/${fix}
  #sed -i 's/日期,入出境總人數_小計,桃園一期出境查驗,桃園二期出境查驗/Date,Entry_and_Departure,TPE_Terminal_1,TPE_Terminal_2/g' ~/2022_DailyImmigPort/fix-data/${original}
  sed -i '/日期,入出境總人數_小計,松山機場小計/d' ~/2020_DailyImmigPort/fix-data/${fix}

  hdfs dfs -put ~/2020_DailyImmigPort/fix-data/${fix} hive-work/2020_DailyImmigPort/${fix}
  [ $? == 0 ] && echo -e " [${GREEN}●${NC}] ${fix} put success." || echo -e " [${RED}●${NC}] ${fix} put failed."
  date=$((${date}+1))
  echo "---"
done
