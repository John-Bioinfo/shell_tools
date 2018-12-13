#!/bin/bash




txtFile=$1
dir=$2

#for line in `cat ${txtFile}`

cat ${txtFile} | while read line
do
    #echo $line

    Num=${line:3}
    
    #find ${dir} -maxdepth 1 -type d -exec ls -ld "{}" \;
    find ${dir} -maxdepth 1 | grep $Num
done

