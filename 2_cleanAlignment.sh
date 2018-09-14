#!/bin/bash

# Vars

fastq_dir="/data/scratch/20180912_CTCL_Exome_Analysis/fastq"
samples="/data/scratch/20180912_CTCL_Exome_Analysis/scripts/samples.txt"
bwa_index="/data/shares/ref/bwa/GRCh38/GRCh38p12"
align_dir="/data/scratch/20180912_CTCL_Exome_Analysis/aligned"
dbSNP="/data/shares/ref/GATK/GRCh38p13/All_20170710.vcf.gz"
genome="/data/shares/ref/STAR/GRCh38.p12/GRCh38.p12.genome.fa"
out_dir="/data/scratch/20180912_CTCL_Exome_Analysis/aligned"


# Covert SAM files to Coordinate-sorted BAM files:
for i in `cat $samples`; do
    date
    echo "Sorting $i"
    gatk SortSam \
        --INPUT ${align_dir}/${i}.sam \
        --OUTPUT ${out_dir}/${i}_sorted.bam \
        --SORT_ORDER coordinate
    echo "done."; echo ""
done

# [Optionally] remove sam files
for i in `cat $samples`; do
    if [ ${out_dir}/${i}_sorted.bam -s ]; then
        rm -f ${align_dir}/${i}.sam
    fi
done

# Run MarkDuplicates
for i in `cat $samples`; do
    date
    echo "Marking duplicates on $i"
    gatk MarkDuplicates \
        --INPUT ${align_dir}/${i}_sorted.bam \
        --METRICS_FILE ${out_dir}/${i}_dupMetrics \
        --OUTPUT ${out_dir}/${i}_sorted_dupMarked.bam
    echo "done."; echo ""
done

# [Optionally] remove sam files
for i in `cat $samples`; do
    if [ ${out_dir}/${i}_sorted_dupMarked.bam -s ]; then
        rm -f ${align_dir}/${i}_sorted.bam
    fi
done

# Add or replace read groups:
for i in `cat $samples`; do
    date
    echo "Repairing Readgroups on $i";
    gatk AddOrReplaceReadGroups \
        --INPUT ${align_dir}/${i}_sorted_dupMarked.bam \
        --OUTPUT ${align_dir}/${i}_sorted_DM_RG.bam \
        --RGLB illumina_$i \
        --RGPL illumina \
        --RGPU JR001 \
        --RGSM $i
     echo "done."; echo ""
done
# [Optionally] remove sam files
for i in `cat $samples`; do
    if [ ${out_dir}/${i}_sorted_DM_RG.bam -s ]; then
        rm -f ${align_dir}/${i}_sorted_dupMarked.bam
    fi
done


# Calculate covariate bias with Base Recalibration
for i in `cat $samples`; do
    date
    echo "Computing covariate bias on $i"
    # first recalibration table
    gatk BaseRecalibrator \
        --input ${align_dir}/${i}_sorted_DM_RG.bam \
        --known-sites ${dbSNP} \
        --output ${align_dir}/${i}_recal.table \
        --reference $genome
    # seccond reclaibration table
    gatk BaseRecalibrator \
        -bqsr ${align_dir}/${i}_recal.table \
        --input ${align_dir}/${i}_sorted_DM_RG.bam \
        --known-sites ${dbSNP} \
        --output ${align_dir}/${i}_recal2.table \
        --reference $genome
    # Apply BSQR
    gatk ApplyBQSR \
        -R $genome \
        -I ${align_dir}/${i}_sorted_DM_RG.bam \
        --bqsr-recal-file ${align_dir}/${i}_recal.table \
        -O ${align_dir}/${i}_BR.bam
    # Generate BQSR quality assesmnet plots
    gatk AnalyzeCovariates \
        -R $genome \
        -before ${align_dir}/${i}_recal.table \
        -after ${align_dir}/${i}_recal2.table \
        -csv ${i}_BQSR.csv \
        -plots ${i}_BQSR.pdf
    echo "done."; echo ""
done





echo "Complete."
