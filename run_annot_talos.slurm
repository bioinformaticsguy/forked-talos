#!/bin/bash
# Talos Pipeline – SLURM Job Script
# ──────────────────────────────────
# Normally invoked via submit_pipeline.sh, which injects SLURM resource
# settings from pipeline_config.sh.
#
# Direct sbatch usage (resource flags must be passed explicitly):
#   sbatch --partition=shortterm --mem=64GB -c 16 \
#          run_annot_talos.slurm --run both --pedigree ped_files/cohort.ped ...
#
# SBATCH directives below are minimal fallback defaults only.
#SBATCH --nodes=1
#SBATCH --output=logs/%j_%u_%N_slurmJob.out
#SBATCH --error=logs/%j_%u_%N_slurmJob.err
#SBATCH --mail-type=ALL

module load singularity/v4.1.3
module load nextflow/v24.04.3

set -euo pipefail

print_usage() {
  cat <<EOF
Usage: sbatch run_annot_talos.slurm [options]

  --run <annotation|talos|both>    (required)
  --cohort <name>                  Cohort name; sets output dir nextflow/<COHORT>_outputs/ (default: cohort)
  --large_files <path>             Large reference files directory (default: large_files)
  --ss_vcf_dir <path>              Directory of per-sample VCFs (merged before annotation)
  --vcf <path>                     Path to a single pre-merged VCF
  --shards <path>                  Directory of pre-sharded VCFs
  --pedigree <path>                Pedigree .ped file (default: ped_files/pedigree.ped)
  --runtime_config <path>          Talos runtime config (default: nextflow/inputs/config.toml)
  --nxf_config <path>              Nextflow config file (default: nextflow.config)
  -h, --help
EOF
}

# ── Defaults ──────────────────────────────────────────────────
run_mode=""
cohort="cohort"
large_files="large_files"
ss_vcf_dir=""
vcf=""
shards=""
pedigree="ped_files/pedigree.ped"
runtime_config="nextflow/inputs/config.toml"
nxf_config="nextflow.config"

# ── Argument parsing ──────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --run)            run_mode="${2}";        shift 2 ;;
    --cohort)         cohort="${2}";          shift 2 ;;
    --large_files)    large_files="${2}";     shift 2 ;;
    --ss_vcf_dir)     ss_vcf_dir="${2}";      shift 2 ;;
    --vcf)            vcf="${2}";             shift 2 ;;
    --shards)         shards="${2}";          shift 2 ;;
    --pedigree)       pedigree="${2}";        shift 2 ;;
    --runtime_config) runtime_config="${2}";  shift 2 ;;
    --nxf_config)     nxf_config="${2}";      shift 2 ;;
    -h|--help)        print_usage; exit 0 ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1" >&2; print_usage; exit 1 ;;
    *)  echo "Unknown argument: $1" >&2; print_usage; exit 1 ;;
  esac
done

# ── Validations ───────────────────────────────────────────────
[[ -z "$run_mode" ]] && { echo "Error: --run is required" >&2; print_usage; exit 1; }
[[ "$run_mode" =~ ^(annotation|talos|both)$ ]] || {
    echo "Error: --run must be annotation, talos, or both" >&2; exit 1
}

# Build VCF args array for annotation runs
NXF_VCF_ARGS=()
if [[ "$run_mode" == "annotation" || "$run_mode" == "both" ]]; then
    if   [[ -n "$ss_vcf_dir" ]]; then NXF_VCF_ARGS=(--ss_vcf_dir "$ss_vcf_dir")
    elif [[ -n "$vcf" ]];        then NXF_VCF_ARGS=(--vcf         "$vcf")
    elif [[ -n "$shards" ]];     then NXF_VCF_ARGS=(--shards      "$shards")
    else
        echo "Error: annotation requires one of --ss_vcf_dir, --vcf, or --shards" >&2
        exit 1
    fi
fi

mkdir -p logs

echo "========================================"
echo " Talos Pipeline"
printf "  %-18s %s\n" "run_mode:"    "$run_mode"
printf "  %-18s %s\n" "cohort:"      "$cohort"
printf "  %-18s %s\n" "pedigree:"    "$pedigree"
printf "  %-18s %s\n" "nxf_config:"  "$nxf_config"
echo "========================================"

# ── Run Workflows ─────────────────────────────────────────────

if [[ "$run_mode" == "annotation" ]]; then
    echo "Running annotation workflow..."
    nextflow -c "$nxf_config" run main.nf \
        -entry ANNOTATION_ONLY \
        --large_files "$large_files" \
        --cohort      "$cohort" \
        "${NXF_VCF_ARGS[@]}"

elif [[ "$run_mode" == "talos" ]]; then
    echo "Running talos workflow..."
    nextflow -c "$nxf_config" run main.nf \
        -entry TALOS_ONLY \
        --cohort         "$cohort" \
        --pedigree       "$pedigree" \
        --runtime_config "$runtime_config"

elif [[ "$run_mode" == "both" ]]; then
    echo "Running annotation + talos (combined)..."
    nextflow -c "$nxf_config" run main.nf \
        --large_files    "$large_files" \
        --cohort         "$cohort" \
        --pedigree       "$pedigree" \
        --runtime_config "$runtime_config" \
        "${NXF_VCF_ARGS[@]}"
fi

echo "Done."
