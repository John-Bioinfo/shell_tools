#!/bin/bash

Pfifo="/tmp/$$.fifo"
mkfifo $Pfifo
exec 6<>$Pfifo

rm -f $Pfifo


## define parallel process num
for i in `seq 1 4`
do
    echo >&6                   
done

shellFile=`ls 1*.sh`

##  run shells
for i in ${shellFile[*]}
do
    read -u6
    {
        bash ${i} && {
            echo "Job ${i} finished"
        } || {
            echo "Job ${i} error"
        }

        sleep 1
        echo >&6
    } &

done

wait
exec 6>&-





