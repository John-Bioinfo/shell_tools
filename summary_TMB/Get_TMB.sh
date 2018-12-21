#!/bin/bash


array=(/TestA/3.somatic_VC/TMB.xls \
       /TestB/3.somatic_VC/TMB.xls \
       /TestC/3.somatic_VC/TMB.xls \
       /TestD/3.somatic_VC/TMB.xls \
       /TestE/3.somatic_VC/TMB.xls \
       /TestF/3.somatic_VC/TMB.xls \
       /TestG/3.somatic_VC/TMB.xls \
       /TestH/3.somatic_VC/TMB.xls \
       /TestI/3.somatic_VC/TMB.xls \
       /TestJ/3.somatic_VC/TMB.xls \
       /TestK/3.somatic_VC/TMB.xls \
       /TestL/3.somatic_VC/TMB.xls \
       /TestM/3.somatic_VC/TMB.xls \
       /TestN/3.somatic_VC/TMB.xls \
       /TestO/3.somatic_VC/TMB.xls \
       /TestP/3.somatic_VC/TMB.xls \
       /TestQ/3.somatic_VC/TMB.xls \
       /TestR/3.somatic_VC/TMB.xls
)




for data in ${array[@]}
do
    a=$(echo ${data} | cut -d '/' -f 7 )
    awk -v addcol=$a '{printf("%s\t%s\n", addcol, $0)}' ${data} >> results_s18_TMB.xls
done
