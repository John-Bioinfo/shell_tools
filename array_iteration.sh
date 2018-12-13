#!/bin/bash


array=(file1 \
       file2 \
       file3 \
       file4 \
       file5 \
       file6
)


for data in ${array[@]}
do
    ##  echo ${data}
    sample_id=$(echo ${data} | cut -d '/' -f 7)

    if [[ ! -e ${sample_id}.txt ]]
    then
        echo "does not exist!"
        awk -v OFS='\t' -F'\t' '$6 >= 0.01' ${data} > ${sample_id}.txt
    else
        echo "Exist."
    fi

done

