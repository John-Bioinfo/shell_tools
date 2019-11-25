sample=someSampleID
fgbio=path_to_/fgbio-1.1.0.jar
picard=path_to_/picard.jar
bwa=path_to_/bwa-0.7.17/bwa
hg19=path_to_/hg19.fasta
hg19_dict=path_to_/hg19.dict
bedfile=path_to_/gene.bed
intervalF=path_to_/gene.intervals

java -jar ${fgbio} CallDuplexConsensusReads --min-reads=1 \
        --min-input-base-quality=30 \
        --error-rate-pre-umi=45 \
        --error-rate-post-umi=30 \
        --input=${sample}.umi.group.BAM \
        --output=${sample}.consensus.uBAM

java -jar ${picard} SamToFastq I=${sample}.consensus.uBAM F=/dev/stdout INTERLEAVE=true \
        | ${bwa} mem -p -t 20 $hg19 /dev/stdin \
        | java -jar $picard MergeBamAlignment \
            UNMAPPED=${sample}.consensus.uBAM ALIGNED=/dev/stdin O=${sample}.consensus.BAM \
            R=${hg19} SO=coordinate ALIGNER_PROPER_PAIR_FLAGS=true MAX_GAPS=-1 \
            ORIENTATIONS=FR VALIDATION_STRINGENCY=SILENT CREATE_INDEX=true  

java -jar ${fgbio} FilterConsensusReads \
        --input=${sample}.consensus.BAM \
        --output=${sample}.consensus.filter.BAM \
        --ref=${hg19} \
        --min-reads=6 3 3 \
        --max-read-error-rate=0.05 \
        --max-base-error-rate=0.1 \
        --min-base-quality=50 \
        --max-no-call-fraction=0.05

java -jar ${fgbio} ClipBam \
        --input=${sample}.consensus.filter.BAM \
        --output=${sample}.consensus.filter.clip.BAM \
        --ref=${hg19} \
        --clipping-mode=Hard \
        --clip-overlapping-reads=true

vardict-java -G ${hg19} -f "0.00000001" -N ${sample} \
        -b ${sample}.consensus.filter.clip.BAM \
        -z -c 1 -S 2 -E 3 -g 4 -r 1 -B 1 -th 8 ${bedfile} \
        | teststrandbias.R \
        | var2vcf_valid.pl -N ${sample} -E -f "0.00000001" \
        | awk '{if($1 ~ /^#/)print; else if ($4 != $5)print;}' > tmp.vcf

java -jar ${picard} SortVcf I=tmp.vcf O=${sample}.target.vcf SD=${hg19_dict}

java -jar ${picard} CollectHsMetrics \
        R=${hg19} \
        I=${sample}.consensus.filter.BAM \
        O=${sample}.target.stat.xls \
        BI=${intervalF} \
        TI=${intervalF} \
        PER_TARGET_COVERAGE=${sample}.target.coverage \
        PER_BASE_COVERAGE=${sample}.base.coverage \
        MQ=0 \
        Q=0 \
        COVMAX=100000 \
        CLIP_OVERLAPPING_READS=true

#echo -ne "Mean_target_cov:\t"
#sed -n '7,8p' ${sample}.target.stat.xls | awk '{print $ 34}'

java -jar ${picard} CollectHsMetrics \
        R=${hg19} \
        I=${sample}.consensus.filter.BAM \
        O=${sample}.op.target.stat.xls \
        BI=${intervalF} \
        TI=${intervalF} \
        MQ=0 \
        Q=0 \
        COVMAX=100000


java -jar ${picard} CollectAlignmentSummaryMetrics \
        R=${hg19} \
        I=${sample}.consensus.filter.BAM \
        O=${sample}.alignment.xls

java -jar ${picard} CollectGcBiasMetrics \
        I=${sample}.consensus.filter.BAM \
        R=${hg19} \
        O=${sample}.gc_bias_metrics.txt \
        CHART=${sample}.gc_bias_metrics.pdf \
        S=${sample}.gc_summary_metrics.txt 

 
