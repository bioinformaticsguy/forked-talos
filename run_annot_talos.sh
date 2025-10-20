#!/bin/bash

nextflow -c nextflow/annotation.config run nextflow/annotation.nf --large_files large_files/ --input_vcf_dir data/

nextflow -c nextflow/talos.config run nextflow/talos.nf --matrix_table nextflow/cohort_outputs/cohort.mt --pedigree data/pedgree.ped