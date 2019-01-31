#!/bin/bash

filelabel=(A.dep B.dep C.dep)

declare -A OutFiles
OutFiles=([A.dep]=results_Auniformity.xls [B.dep]=results_Buniformity.xls [C.dep]=results_Cuniformity.xls)

#for i in `ls *A.dep`
for i in `ls *.dep`
do

    
    ave=$(awk '{sum+=$3} END {print sum/NR}' ${i})
    upN=$(awk -v a=$ave '{if($3>0.2*a){print}}' ${i} | wc -l)
    tot=$(wc -l ${i} | cut -d' ' -f 1)
    uniformity=$(echo "scale=4; 100*${upN}/${tot}" | bc)

    sampleN=$(echo ${i} | awk -F'_' '{print $1}')

    for j in `eval echo {0..$((${#filelabel[*]}-1))}`
    do
        result=$(echo $i | grep "${filelabel[j]}") 
        if [ -n "$result" ]
        then
            echo -e "${sampleN}\t${uniformity}" >> ${OutFiles["${filelabel[j]}"]}
            break
        fi
    done
done


