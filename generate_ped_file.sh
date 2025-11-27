#!/bin/bash

# Script to generate a pedigree.ped file from VCF files in a data directory
# Usage: ./generate_pedigree.sh <data_path> <output_pedigree_file> <hpo_terms>
# Example: ./generate_pedigree.sh /path/to/data /path/to/pedigree.ped "HP:0000032,HP:0000062,HP:0010458,HP:0000046,HP:0000137"

# Check arguments
if [ $# -ne 3 ]; then
    echo "Usage: $0 <data_path> <output_pedigree_file> <hpo_terms>"
    echo "  data_path: Directory containing VCF files"
    echo "  output_pedigree_file: Full path to output pedigree.ped file"
    echo "  hpo_terms: Comma-separated HPO terms (e.g., 'HP:0000032,HP:0000062,HP:0010458,HP:0000046,HP:0000137')"
    exit 1
fi

DATA_PATH="$1"
OUTPUT_FILE="$2"
HPO_TERMS="$3"

# Check if data path exists
if [ ! -d "$DATA_PATH" ]; then
    echo "Error: Data path '$DATA_PATH' does not exist or is not a directory."
    exit 1
fi

# Create output directory if it doesn't exist
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
mkdir -p "$OUTPUT_DIR"

# Clear or create the output file
> "$OUTPUT_FILE"

# Find all VCF files in the data directory
VCF_FILES=$(find "$DATA_PATH" -name "*.vcf" -o -name "*.vcf.gz" -o -name "*.vcf.bgz")

if [ -z "$VCF_FILES" ]; then
    echo "Warning: No VCF files found in '$DATA_PATH'"
    exit 0
fi

# Process each VCF file
for VCF_FILE in $VCF_FILES; do

    if command -v bcftools >/dev/null 2>&1; then
        SAMPLE_ID=$(bcftools query -l "$VCF_FILE" | head -n1)
    else
        if [[ "$VCF_FILE" == *.gz ]] || [[ "$VCF_FILE" == *.bgz ]]; then
            SAMPLE_ID=$(zcat "$VCF_FILE" | grep -m1 '^#CHROM' | awk '{print $NF}')
        else
            SAMPLE_ID=$(grep -m1 '^#CHROM' "$VCF_FILE" | awk '{print $NF}')
        fi
    fi

    # Write pedigree line
    # Family ID = Sample ID (as in your example)
    # Father ID = 0, Mother ID = 0, Sex = 0 (unknown), Affected = 2 (affected)
    FAMILY_ID="fam_${SAMPLE_ID}"
    echo "$FAMILY_ID	$SAMPLE_ID	0	0	0	2	$HPO_TERMS" >> "$OUTPUT_FILE"
done

echo "Pedigree file generated: $OUTPUT_FILE"
echo "Processed $(echo "$VCF_FILES" | wc -l) VCF files."