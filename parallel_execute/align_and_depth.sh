#!/bin/bash

fqfile=$1
ref=/data2/test/lohhla_test/hg19Ref_depth/HLA_ref.fasta
SAMTOOLS=/root/anaconda3/bin/samtools

mkdir shell_file

if [[ ! -e  HLA_REF.nix ]]
then
    /root/anaconda3/bin/novoindex HLA_REF.nix ${ref}
fi

cat ${fqfile} | while read line
do
    fq1=${line}.1.fastq
    fq2=${line}.2.fastq

    sampleFullName=${line##*/}
    sampleName=$(echo ${sampleFullName} | awk -F'_' '{printf("%s-%s", $1,$2)}')    
    hlas_sample=$(echo ${line} | cut -d'_' -f 3)

    cat > ${sampleName}.sh << EOF    

if [[ ! -e out_${sampleName}_hlasB.sam ]]
then    
    /root/anaconda3/bin/novoalign -d HLA_REF.nix -f ${fq1} ${fq2} -F STDFQ -R 0 -r All 9999 -o SAM -o FullNW 1> out_${sampleName}_HLA.sam 2> out.${hlas_sample}.hlas.metrics    
fi

$SAMTOOLS view -@ 8 -bS out_${sampleName}_HLA.sam | $SAMTOOLS sort - -@ 8 -T aln_tmp_sorted -o hla_${sampleName}_sorted.bam
$SAMTOOLS index hla_${sampleName}_sorted.bam

sleep 2
$SAMTOOLS depth -b ../test_HLA-A.bed hla_${sampleName}_sorted.bam -a > ${sampleName}_hla-A.dep
$SAMTOOLS depth -b ../test_HLA-B.bed hla_${sampleName}_sorted.bam -a > ${sampleName}_hla-B.dep
$SAMTOOLS depth -b ../test_HLA-C.bed hla_${sampleName}_sorted.bam -a > ${sampleName}_hla-C.dep

EOF
    cp ${sampleName}.sh shell_file/

done



