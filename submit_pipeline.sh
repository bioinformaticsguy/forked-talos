#!/usr/bin/env bash
# Reads pipeline_config.sh, auto-generates the pedigree if needed,
# then submits run_annot_talos.slurm with all correct arguments.
#
# Usage: ./submit_pipeline.sh [overrides]
#
# Overrides (all optional — any flag here wins over pipeline_config.sh):
#   --run           annotation|talos|both
#   --input_vcf_dir <path>
#   --pedigree      <path>
#   --matrix_table  <path>
#   --anno_config   <path>
#   --talos_config  <path>
#   -h, --help

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${SCRIPT_DIR}/pipeline_config.sh"

[[ -f "$CONFIG" ]] || { echo "Error: pipeline_config.sh not found at ${CONFIG}"; exit 1; }
# shellcheck source=pipeline_config.sh
source "$CONFIG"

print_usage() {
  cat <<EOF
Usage: $0 [overrides]

Reads pipeline_config.sh; any flag below overrides the config value.

  --run           <annotation|talos|both>
  --input_vcf_dir <path>
  --pedigree      <path>
  --matrix_table  <path>
  --anno_config   <path>
  --talos_config  <path>
  -h, --help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run)           RUN_MODE="${2}";       shift 2 ;;
    --input_vcf_dir) INPUT_VCF_DIR="${2}";  shift 2 ;;
    --pedigree)      PEDIGREE="${2}";        shift 2 ;;
    --matrix_table)  MATRIX_TABLE="${2}";   shift 2 ;;
    --anno_config)   ANNO_CONFIG="${2}";    shift 2 ;;
    --talos_config)  TALOS_CONFIG="${2}";   shift 2 ;;
    -h|--help)       print_usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; print_usage; exit 1 ;;
  esac
done

# ── Auto-generate pedigree if not present ─────────────────────
if [[ "$RUN_MODE" == "annotation" || "$RUN_MODE" == "both" ]]; then
    if [[ ! -f "$PEDIGREE" ]]; then
        echo "Pedigree not found — generating from VCFs in '${INPUT_VCF_DIR}'..."
        bash "${SCRIPT_DIR}/generate_ped_file.sh" "$INPUT_VCF_DIR" "$PEDIGREE" "$HPO_TERMS"
        echo
        echo "  Review ${PEDIGREE} before the talos step runs (sex column, family structure)."
        echo
    else
        echo "Using existing pedigree: ${PEDIGREE}"
    fi
fi

# ── Summary ───────────────────────────────────────────────────
echo "Submitting Talos pipeline:"
printf "  %-22s %s\n" "run_mode:"     "$RUN_MODE"
printf "  %-22s %s\n" "input_vcf_dir:" "${INPUT_VCF_DIR:-N/A}"
printf "  %-22s %s\n" "pedigree:"     "$PEDIGREE"
printf "  %-22s %s\n" "matrix_table:" "$MATRIX_TABLE"
printf "  %-22s %s\n" "anno_config:"  "$ANNO_CONFIG"
printf "  %-22s %s\n" "talos_config:" "$TALOS_CONFIG"
printf "  %-22s %s\n" "slurm queue:"  "${SLURM_PARTITION} (${SLURM_CPUS} CPUs, ${SLURM_MEM})"
echo

mkdir -p "${SCRIPT_DIR}/logs"

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
    --run           "$RUN_MODE" \
    --input_vcf_dir "$INPUT_VCF_DIR" \
    --pedigree      "$PEDIGREE" \
    --matrix_table  "$MATRIX_TABLE" \
    --anno_config   "$ANNO_CONFIG" \
    --talos_config  "$TALOS_CONFIG"
