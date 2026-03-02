#!/usr/bin/env bash
# =============================================================
# Talos Pipeline Configuration
# Edit this file for your run, then execute:  ./submit_pipeline.sh
# =============================================================

# ── Run mode ──────────────────────────────────────────────────
# annotation | talos | both
RUN_MODE="both"

# ── Input VCFs (for annotation) ───────────────────────────────
# Directory containing *.vcf.gz files to merge and annotate
INPUT_VCF_DIR="data/long_cohort"

# ── Pedigree ──────────────────────────────────────────────────
# If this file does not exist when submit_pipeline.sh runs,
# it will be auto-generated from the VCFs in INPUT_VCF_DIR.
PEDIGREE="ped_files/long_cohort.ped"

# ── HPO terms assigned to all probands ────────────────────────
# Used only during auto-generation; edit per-sample in the PED
# file afterwards if cases have different phenotypes.
HPO_TERMS="HP:0000032,HP:0000062,HP:0010458,HP:0000046,HP:0000137"

# ── Matrix table path ─────────────────────────────────────────
# Annotation writes here; talos reads from here.
# Must match params.cohort_output_dir/params.cohort in annotation.config
# Default: nextflow/cohort_outputs/cohort.mt
MATRIX_TABLE="nextflow/cohort_outputs/cohort.mt"

# ── Nextflow config files ─────────────────────────────────────
ANNO_CONFIG="nextflow/annotation.config"
TALOS_CONFIG="nextflow/talos.config"

# ── SLURM settings ────────────────────────────────────────────
SLURM_PARTITION="shortterm"
SLURM_CPUS=16
SLURM_MEM="64GB"
SLURM_TMP="100G"
SLURM_EMAIL="alihassan1697@gmail.com"
