 #!/bin/bash

 # Vars

 fastq_dir="/data/scratch/20180912_CTCL_Exome_Analysis/fastq"
 samples="/data/scratch/20180912_CTCL_Exome_Analysis/scripts/samples.txt"
 bwa_index="/data/shares/ref/bwa/GRCh38/GRCh38p12"
 align_dir="/data/scratch/20180912_CTCL_Exome_Analysis/aligned"
 out_dir="/data/scratch/20180912_CTCL_Exome_Analysis/aligned"

 for i in `cat $samples`; do
     date
     echo "Sorting $i"
     gatk SortSam \
         --INPUT ${align_dir}/${i}.sam \
         --OUTPUT ${out_dir}/${i}_sorted.bam \
         --SORT_ORDER coordinate
     echo "done."; echo ""
 done



 echo "Complete."
