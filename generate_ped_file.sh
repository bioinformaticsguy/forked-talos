#!/usr/bin/env bash
# Generate a PED file from a directory of VCF files.
#
# Handles both single-sample and multi-sample (joint) VCFs:
#   Each VCF becomes one family (ID derived from the filename stem).
#   Sample roles are inferred by position in the VCF column order:
#     1 sample  → singleton proband
#     2 samples → proband (index 0) + one parent (index 1)
#     3 samples → trio: proband (0), father (1), mother (2)
#     4+ samples→ proband + remaining unaffected family members
#
# PED columns (tab-separated):
#   family_id  sample_id  father_id  mother_id  sex  affected  [hpo_terms]
#   sex: 1=male 2=female 0=unknown
#   affected: 1=unaffected 2=affected
#
# Usage:
#   ./generate_ped_file.sh <data_dir> <output.ped> <hpo_terms>
#
# Example:
#   ./generate_ped_file.sh data/long_cohort ped_files/long_cohort.ped \
#       "HP:0000032,HP:0000062,HP:0010458,HP:0000046,HP:0000137"
#
# NOTE: Review the generated file and set the sex column (col 5) correctly.
#       1=male, 2=female, 0=unknown. Talos uses sex for X-linked MOI calls.

set -euo pipefail

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <data_dir> <output_ped> <hpo_terms>"
    echo "  data_dir   : directory containing *.vcf / *.vcf.gz / *.vcf.bgz files"
    echo "  output_ped : path to write the pedigree file"
    echo "  hpo_terms  : comma-separated HPO terms assigned to all probands"
    exit 1
fi

DATA_DIR="$1"
OUTPUT_FILE="$2"
HPO_TERMS="$3"

[[ -d "$DATA_DIR" ]] || { echo "Error: '$DATA_DIR' is not a directory"; exit 1; }
mkdir -p "$(dirname "$OUTPUT_FILE")"
> "$OUTPUT_FILE"

family_count=0

# Sort the VCFs for deterministic output
while IFS= read -r -d '' vcf_file; do

    # Derive family ID from the filename stem (everything before the first dot)
    # e.g. "first_trio.joint.GRCh38.small_variants.phased.vcf.gz" -> "first_trio"
    family_id="$(basename "$vcf_file")"
    family_id="${family_id%%.*}"

    # Extract all sample IDs in VCF column order
    if command -v bcftools >/dev/null 2>&1; then
        mapfile -t samples < <(bcftools query -l "$vcf_file")
    elif [[ "$vcf_file" == *.gz || "$vcf_file" == *.bgz ]]; then
        mapfile -t samples < <(zcat "$vcf_file" | grep -m1 '^#CHROM' | tr '\t' '\n' | tail -n +10)
    else
        mapfile -t samples < <(grep -m1 '^#CHROM' "$vcf_file" | tr '\t' '\n' | tail -n +10)
    fi

    n="${#samples[@]}"
    if [[ "$n" -eq 0 ]]; then
        echo "Warning: no samples found in '$vcf_file', skipping" >&2
        continue
    fi

    proband="${samples[0]}"
    father_id="0"
    mother_id="0"

    case "$n" in
        1) ;;   # singleton — no parents
        2)      # duo: proband + one parent (sex unknown, assumed father)
            father_id="${samples[1]}"
            ;;
        *)      # trio or larger: sample[1]=father, sample[2]=mother
            father_id="${samples[1]}"
            mother_id="${samples[2]}"
            ;;
    esac

    # Proband line (affected=2, HPO terms in col 7)
    printf '%s\t%s\t%s\t%s\t0\t2\t%s\n' \
        "$family_id" "$proband" "$father_id" "$mother_id" "$HPO_TERMS" \
        >> "$OUTPUT_FILE"

    # Remaining family members: unaffected (affected=1), no HPO
    for i in "${!samples[@]}"; do
        [[ "$i" -eq 0 ]] && continue
        printf '%s\t%s\t0\t0\t0\t1\n' "$family_id" "${samples[$i]}" >> "$OUTPUT_FILE"
    done

    (( family_count++ ))
    echo "  [$family_id]  $n sample(s)  proband=${proband}"

done < <(find "$DATA_DIR" \( -name "*.vcf" -o -name "*.vcf.gz" -o -name "*.vcf.bgz" \) -print0 | sort -z)

if [[ "$family_count" -eq 0 ]]; then
    echo "Warning: no VCF files found in '$DATA_DIR'"
    exit 0
fi

echo
echo "Pedigree written: $OUTPUT_FILE  ($family_count families)"
echo "ACTION REQUIRED: open the file and set the sex column (col 5: 1=male 2=female)"
echo "  Talos uses sex for X-linked mode-of-inheritance filtering."
