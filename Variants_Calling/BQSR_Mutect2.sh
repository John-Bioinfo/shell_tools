## Softwares and database Files
picard=/data/softwares/picard.jar
GATK4=/data/softwares/gatk-4.1.4.0/gatk-package-4.1.4.0-local.jar
GATK3_jar=/data/softwares/GenomeAnalysisTK.jar
intervalsF=/data/UMI_samples/Newgene.intervals
bedfile=/data/UMI_samples/Newgene.bed
hg19=/data/ref_data/ref_fasta/hg19.fasta
hg19_dict=/data/ref_data/ref_fasta/hg19.dict
hg19_sites=/data/reference_data/ref_DB/dbsnp_138.hg19.vcf
OneG_indels_sites=/data/reference_data/ref_DB/1000G_phase1.indels.hg19.sites.vcf
gold_std_indels_sites=/data/reference_data/ref_DB/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf

sample=test
realign_inter=${sample}.realign.intervals

java -jar ${picard} MarkDuplicates \
	REMOVE_DUPLICATES=false \
	METRICS_FILE=dup.txt \
	INPUT=../${sample}.umi.merged.bam \
	OUTPUT=${sample}.dup.bam

#java -jar ${GATK4} MarkDuplicates -I ../${sample}.umi.merged.bam \
#	-O ${sample}.markdup.bam \
#	-M ${sample}markdup_metrics.txt 

java -jar ${picard} BuildBamIndex \
        I=${sample}.dup.bam

java -jar ${GATK3_jar} -T RealignerTargetCreator \
        -L  ${intervalsF} \
        -R  ${hg19} \
        -I  ${sample}.dup.bam \
        -o  ${realign_inter} \
        -known ${OneG_indels_sites} \
        -known ${gold_std_indels_sites} \
        2>${sample}.realignCreator.log

java -jar ${GATK3_jar} -T IndelRealigner \
        -L  ${intervalsF} \
        -maxReads 100000 \
        -R  ${hg19} \
        -I  ${sample}.dup.bam \
        -targetIntervals ${realign_inter} \
        -known  ${OneG_indels_sites} \
        -known  ${gold_std_indels_sites} \
        -o  ${sample}.realign.bam \
        2>${sample}.realign.log


java -jar ${GATK3_jar} -T BaseRecalibrator \
        -L  ${intervalsF} \
        -R  ${hg19} \
        -knownSites  ${hg19_sites} \
        -knownSites  ${OneG_indels_sites} \
        -knownSites  ${gold_std_indels_sites} \
        -o  ${sample}.recal.grp \
        -I  ${sample}.realign.bam \
        2>${sample}.recal_BQ.log

java -jar ${GATK3_jar} -T PrintReads \
        -L  ${intervalsF} \
        -R  ${hg19} \
        -I  ${sample}.realign.bam \
        -BQSR  ${sample}.recal.grp \
        -o  ${sample}.recal.bam \
        2>${sample}.recal_PR.log

## remove secondary alignments or hard clipping alignments
samtools view ${sample}.recal.bam -h -@ 16 -F 256 | samtools view -@ 16 -bS > ${sample}.recal_noH.bam

samtools index ${sample}.recal_noH.bam


# mkdir -p somatic_VC

java -Xmx16g -jar ${GATK3_jar} -T MuTect2 \
	-I:tumor ${sample}.recal_noH.bam \
	-L  ${intervalsF} \
	-R  ${hg19} \
	--dbsnp  ${hg19_sites} \
	-o  ${sample}.target.mutect.vcf \
	-A StrandBiasBySample  \
	-A TandemRepeatAnnotator \
	-A FisherStrand \
	-A StrandOddsRatio \
	-A Coverage \
	2>${sample}.mutect2.log








