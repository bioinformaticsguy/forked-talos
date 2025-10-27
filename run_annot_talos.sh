#!/bin/bash

module load singularity/v4.1.3
module load nextflow/v24.04.3

# nextflow -c nextflow/annotation.config run nextflow/annotation.nf --large_files large_files/ --input_vcf_dir nextflow/inputs/individual_vcfs
# nextflow -c nextflow/talos.config run nextflow/talos.nf --matrix_table nextflow/cohort_outputs/cohort.mt --pedigree nextflow/inputs/pedigree.ped



# nextflow -c nextflow/annotation.config run nextflow/annotation.nf --large_files large_files/ --input_vcf_dir data_back
nextflow -c nextflow/talos.config run nextflow/talos.nf --matrix_table nextflow/cohort_outputs/cohort.mt --pedigree ped_files/pedigree.ped