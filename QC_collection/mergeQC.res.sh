#!/bin/bash


QClist=$1

fileNum=0

echo -ne "join " >> test_QC.sh

cat ${QClist} | while read line
do
    fileNum=`expr $fileNum + 1`
    if [ $fileNum -lt 3 ]
    then
        echo "$line \\" >> test_QC.sh
    else
        echo "| join - $line \\" >> test_QC.sh
    fi
done

echo ">> QC_resAll.xls" >> test_QC.sh

