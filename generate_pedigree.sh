#!/usr/bin/env bash
# Generate a pedigree.ped file from a directory of VCF files.
# Each VCF is treated as a single affected proband (no parental samples).
#
# Usage:
#   ./generate_pedigree.sh <data_dir> <output_ped> <hpo_terms>
#
# Example:
#   ./generate_pedigree.sh data/vcfs ped_files/cohort.ped \
#       "HP:0000032,HP:0000062,HP:0010458,HP:0000046,HP:0000137"

set -euo pipefail

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <data_dir> <output_ped> <hpo_terms>"
    echo "  data_dir   : directory containing VCF files"
    echo "  output_ped : path to write the pedigree file"
    echo "  hpo_terms  : comma-separated HPO terms"
    exit 1
fi

DATA_DIR="$1"
OUTPUT_FILE="$2"
HPO_TERMS="$3"

[[ -d "$DATA_DIR" ]] || { echo "Error: '$DATA_DIR' is not a directory"; exit 1; }
mkdir -p "$(dirname "$OUTPUT_FILE")"
> "$OUTPUT_FILE"

count=0
while IFS= read -r -d '' vcf_file; do
    if command -v bcftools >/dev/null 2>&1; then
        sample_id=$(bcftools query -l "$vcf_file" | head -n1)
    elif [[ "$vcf_file" == *.gz || "$vcf_file" == *.bgz ]]; then
        sample_id=$(zcat "$vcf_file" | grep -m1 '^#CHROM' | awk '{print $NF}')
    else
        sample_id=$(grep -m1 '^#CHROM' "$vcf_file" | awk '{print $NF}')
    fi

    # PED format (tab-separated):
    # family_id  sample_id  father  mother  sex  affected  hpo_terms
    # sex: 0=unknown  affected: 2=affected
    printf '%s\t%s\t0\t0\t0\t2\t%s\n' "fam_${sample_id}" "$sample_id" "$HPO_TERMS" \
        >> "$OUTPUT_FILE"
    (( count++ ))
done < <(find "$DATA_DIR" \( -name "*.vcf" -o -name "*.vcf.gz" -o -name "*.vcf.bgz" \) -print0)

if [[ $count -eq 0 ]]; then
    echo "Warning: no VCF files found in '$DATA_DIR'"
    exit 0
fi

echo "Pedigree written: $OUTPUT_FILE ($count samples)"
