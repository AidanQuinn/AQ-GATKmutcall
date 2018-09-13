 #!/bin/bash

 # Vars

 fastq_dir="/data/scratch/20180912_CTCL_Exome_Analysis/fastq"
 samples="/data/scratch/20180912_CTCL_Exome_Analysis/scripts/samples.txt"
 bwa_index="/data/shares/ref/bwa/GRCh38/GRCh38p12"
 out_dir="/data/scratch/20180912_CTCL_Exome_Analysis/aligned"

 for i in `cat $samples`; do
     date
     echo "Aligning $i"
     bwa mem -t 24 ${bwa_index} ${fastq_dir}/${i}_R1.fastq.gz ${fastq_dir}/${i}_R2.fastq.gz >         ${out_dir}/${i}.sam
     echo "done."; echo ""
 done

 echo "Complete."
