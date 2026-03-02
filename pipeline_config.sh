#!/usr/bin/env bash
# =============================================================
# Talos Pipeline Configuration
# Edit this file for each cohort run, then execute:
#   ./submit_pipeline.sh
# =============================================================

# Run mode: annotation | talos | both
RUN_MODE="both"

# Cohort name — controls output directory: nextflow/<COHORT>_outputs/
COHORT="cohort"

# ── Reference data ────────────────────────────────────────────
LARGE_FILES="large_files"

# ── Input VCF — set exactly ONE of the three options ─────────
# SS_VCF_DIR : directory of per-sample *.vcf.bgz files (merged before annotation)
# VCF        : path to a single pre-merged multi-sample VCF
# SHARDS_DIR : directory of pre-sharded VCFs
SS_VCF_DIR=""
VCF=""
SHARDS_DIR=""

# ── Talos runtime files ───────────────────────────────────────
PEDIGREE="ped_files/pedigree.ped"
RUNTIME_CONFIG="nextflow/inputs/config.toml"

# ── Nextflow config ───────────────────────────────────────────
NXF_CONFIG="nextflow.config"

# ── HPO terms (used by generate_pedigree.sh to build PEDIGREE) ─
# Comma-separated list e.g. "HP:0000032,HP:0000062,HP:0010458"
HPO_TERMS="HP:0000032,HP:0000062,HP:0010458,HP:0000046,HP:0000137"

# ── SLURM settings (injected by submit_pipeline.sh) ──────────
SLURM_PARTITION="shortterm"
SLURM_CPUS=16
SLURM_MEM="64GB"
SLURM_TMP="100G"
SLURM_EMAIL="alihassan1697@gmail.com"
