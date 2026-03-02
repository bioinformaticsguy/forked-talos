#!/usr/bin/env bash
# Reads pipeline_config.sh and submits run_annot_talos.slurm to SLURM.
# Any flag passed here overrides the value set in pipeline_config.sh.
#
# Usage: ./submit_pipeline.sh [--run annotation|talos|both] [other overrides]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/pipeline_config.sh"

[[ -f "$CONFIG_FILE" ]] || { echo "Error: pipeline_config.sh not found at ${CONFIG_FILE}"; exit 1; }
# shellcheck source=pipeline_config.sh
source "$CONFIG_FILE"

print_usage() {
  cat <<EOF
Usage: $0 [options]

All options override the value set in pipeline_config.sh.

  --run <annotation|talos|both>
  --cohort <name>
  --large_files <path>
  --ss_vcf_dir <path>      Per-sample VCF directory (merged before annotation)
  --vcf <path>             Pre-merged multi-sample VCF
  --shards <path>          Pre-sharded VCF directory
  --pedigree <path>
  --runtime_config <path>
  --nxf_config <path>
  -h, --help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run)            RUN_MODE="${2}";        shift 2 ;;
    --cohort)         COHORT="${2}";          shift 2 ;;
    --large_files)    LARGE_FILES="${2}";     shift 2 ;;
    --ss_vcf_dir)     SS_VCF_DIR="${2}";      shift 2 ;;
    --vcf)            VCF="${2}";             shift 2 ;;
    --shards)         SHARDS_DIR="${2}";      shift 2 ;;
    --pedigree)       PEDIGREE="${2}";        shift 2 ;;
    --runtime_config) RUNTIME_CONFIG="${2}";  shift 2 ;;
    --nxf_config)     NXF_CONFIG="${2}";      shift 2 ;;
    -h|--help)        print_usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; print_usage; exit 1 ;;
  esac
done

# Build pipeline arguments to forward to the slurm script
PIPELINE_ARGS=(
    --run            "$RUN_MODE"
    --cohort         "$COHORT"
    --large_files    "$LARGE_FILES"
    --pedigree       "$PEDIGREE"
    --runtime_config "$RUNTIME_CONFIG"
    --nxf_config     "$NXF_CONFIG"
)
[[ -n "$SS_VCF_DIR" ]] && PIPELINE_ARGS+=(--ss_vcf_dir "$SS_VCF_DIR")
[[ -n "$VCF" ]]         && PIPELINE_ARGS+=(--vcf        "$VCF")
[[ -n "$SHARDS_DIR" ]]  && PIPELINE_ARGS+=(--shards     "$SHARDS_DIR")

mkdir -p "${SCRIPT_DIR}/logs"

echo "Submitting Talos pipeline job:"
printf "  %-20s %s\n" "run_mode:"    "$RUN_MODE"
printf "  %-20s %s\n" "cohort:"      "$COHORT"
printf "  %-20s %s\n" "pedigree:"    "$PEDIGREE"
printf "  %-20s %s\n" "vcf input:"   "${SS_VCF_DIR:-${VCF:-${SHARDS_DIR:-<not set>}}}"
printf "  %-20s %s\n" "slurm queue:" "$SLURM_PARTITION (${SLURM_CPUS} CPUs, ${SLURM_MEM})"
echo

sbatch \
    --partition="$SLURM_PARTITION" \
    --nodes=1 \
    -c "$SLURM_CPUS" \
    --mem="$SLURM_MEM" \
    --tmp="$SLURM_TMP" \
    --mail-type=ALL \
    --mail-user="$SLURM_EMAIL" \
    --output="logs/%j_%u_%N_slurmJob.out" \
    --error="logs/%j_%u_%N_slurmJob.err" \
    "${SCRIPT_DIR}/run_annot_talos.slurm" \
    "${PIPELINE_ARGS[@]}"
