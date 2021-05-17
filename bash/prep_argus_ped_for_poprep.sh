#!/bin/bash
#
#
#
# ###########################################

cd /qualstorzws01/data_projekte/projekte/genmon/pedigrees
a="PopReport_BV_20210510.csv"
cp ${a} ${a}_adaptfin.csv
sed -i -e "s/;/|/g" ${a}_adaptfin.csv 
(echo "#IDTier|IDVater|IDMutter|Birthdate|Geschlecht|PLZ|introg|inb_gen|cryo"; awk -F'|' 'NR>1&&substr($4,1,4)<2021 {print $0}' ${a}_adaptfin.csv ) > ${a}_adaptfin6.csv 
Rscript /home/gnmzws/simg/genmon-sidef/R/checkpedig.R ${a}_adaptfin6.csv
awk -F'|' '{if(FILENAME==ARGV[1])
{id[$1]} else {if($1 in id){$2=""; $4=""}{OFS="|"}
{print $0}}}' IDsire.txt ${a}_adaptfin6.csv | awk -F'|' '{if(FILENAME==ARGV[1])
{id[$1]} else {if($1 in id){$3=""; $4=""}{OFS="|"}{
print $0}}}' IDdam.txt - | awk -F'|' '{if(FILENAME==ARGV[1])
{id[$1]} else {if($1 in id){$2=""}{OFS="|"}
{print $0}}}' Eqsire.txt - | awk -F'|' '{if(FILENAME==ARGV[1])
{id[$1]} else {if($1 in id){$3=""}{OFS="|"}
{print $0}}}' Eqdam.txt - |  awk -F'|' '{if(FILENAME==ARGV[1])
{id[$1]} else {if($3 in id){$3=""} if($2 in id){$2=""} {OFS="|"}{if(!($1 in id))
{print $0}}}}' WrongSire.txt - |  awk -F'|' '{if(FILENAME==ARGV[1])
{id[$1]} else {if($3 in id){$3=""} if($2 in id){$2=""} {OFS="|"}{if(!($1 in id))
{print $0}}}}' WrongDam.txt - | awk -F'|' '{OFS="|"} 
{if($6==3000||$6==3052 ||$6==3362){$6=""}{print $0}}' > ${a}_adaptfin7.csv
Rscript checkpedig.R ${a}_adaptfin7.csv
rm ${a}_adaptfin.csv ${a}_adaptfin6.csv IDsire.txt IDdam.txt Eqsire.txt Eqdam.txt WrongSire.txt WrongDam.txt
awk -F'|' '{print $2}' ${a}_adaptfin7.csv | sort | uniq -c | sort -nrk1,1 | head -20
awk -F'|' '{print $3}' ${a}_adaptfin7.csv | sort | uniq -c | sort -nrk1,1 | head -20