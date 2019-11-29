sample=test
export LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}
GATK_jar=/data/softwares/GenomeAnalysisTK.jar
varscan=/data/softwares/VarScan.v2.4.3.jar
picard=/data/softwares/picard.jar
intervalsF=/data/varscan_test/UMI_data_samples/New_genes.intervals
bedfile=/data/varscan_test/UMI_data_samples/New_genes.bed
hg19=/data/reference_data/ref_fasta/hg19.fasta
hg19_dict=/data/reference_data/ref_fasta/hg19.dict
hg19_sites=/data/reference_data/ref_fasta//dbsnp_138.hg19.vcf
T1000G_indels_sites=/data/reference_data/ref_DB/1000G_phase1.indels.hg19.sites.vcf
gold_std_indels_sites=/data/reference_data/ref_DB/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf

realign_inter=${sample}.realign.intervals

cp ../${sample}/${sample}.consensus.filter.clip.BAM ./

/data/program/C_prog/modify_qual ${sample}.consensus.filter.clip.BAM ${sample}.mod.BAM
samtools index ${sample}.mod.BAM

java -jar ${GATK_jar} -T RealignerTargetCreator \
        -L  ${intervalsF} \
        -R  ${hg19} \
        -I  ${sample}.mod.BAM \
        -o  ${realign_inter} \
        -known ${T1000G_indels_sites} \
        -known ${gold_std_indels_sites} \
        2>${sample}.realignCreator.log

java -jar ${GATK_jar} -T IndelRealigner \
        -L  ${intervalsF} \
        -maxReads 100000 \
        -R  ${hg19} \
        -I  ${sample}.mod.BAM \
        -targetIntervals ${realign_inter} \
        -known  ${T1000G_indels_sites} \
        -known  ${gold_std_indels_sites} \
        -o  ${sample}.realign.bam \
        2>${sample}.realign.log 


java -jar ${GATK_jar} -T BaseRecalibrator \
        -L  ${intervalsF} \
        -R  ${hg19} \
        -knownSites  ${hg19_sites} \
        -knownSites  ${T1000G_indels_sites} \
        -knownSites  ${gold_std_indels_sites} \
        -o  ${sample}.recal.grp \
        -I  ${sample}.realign.bam \
        2>${sample}.recal_BQ.log

java -jar ${GATK_jar} -T PrintReads \
        -L  ${intervalsF} \
        -R  ${hg19} \
        -I  ${sample}.realign.bam \
        -BQSR  ${sample}.recal.grp \
        -o  ${sample}.recal.bam \
        2>${sample}.recal_PR.log

samtools view ${sample}.recal.bam -h -@ 16 -F 256 | samtools view -@ 16 -bS > ${sample}.recal_noH.bam

samtools index ${sample}.recal_noH.bam

samtools mpileup -E -f ${hg19} ${sample}.recal_noH.bam > ${sample}.mpileup

java -jar ${varscan} pileup2snp ${sample}.mpileup  --min-coverage 500 --min-reads2 2 --min-avg- --min-coverage 500 --min-reads2 2 --min-avg-qual 24 --min-var-freq 0.0001 > ${sample}.vs.snp

java -jar ${varscan} pileup2indel ${sample}.mpileup  --min-coverage 500 --min-reads2 2 --min-avg- --min-coverage 500 --min-reads2 2 --min-avg-qual 24 --min-var-freq 0.0001 > ${sample}.vs.indel

vardict-java -G ${hg19} -f "0.00000001" -N ${sample} \
        -b ${sample}.recal_noH.bam \
        -z -c 1 -S 2 -E 3 -g 4 -r 1 -B 1 -th 8 ${bedfile} \
        | teststrandbias.R \
        | var2vcf_valid.pl -N ${sample} -E -f "0.00000001" \
        | awk '{if($1 ~ /^#/)print; else if ($4 != $5)print;}' > tmp.vcf

java -jar ${picard} SortVcf I=tmp.vcf O=${sample}.vd_target.vcf SD=${hg19_dict}


