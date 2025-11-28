#!/bin/bash

#SBATCH --partition=shortterm
#SBATCH --nodes=1
#SBATCH -c 16
#SBATCH --mem=64GB
#SBATCH --tmp=100G
#SBATCH --output=logs/%j_%u_%N_slurmJob.out
#SBATCH --error=logs/%j_%u_%N_slurmJob.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=alihassan1697@gmail.com

module load singularity/v4.1.3
module load nextflow/v24.04.3

set -euo pipefail

print_usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  -r, --run <annotation|talos|both>   Which workflow(s) to run (required)
  -l, --large_files <path>            Path to large_files (default: large_files/)
  -i, --input_vcf_dir <path>          Input VCF directory for annotation (default: nextflow/inputs/individual_vcfs)
  -a, --anno_config <path>            Annotation Nextflow config (default: nextflow/annotation.config)
  -t, --talos_config <path>           Talos Nextflow config (default: nextflow/talos.config)
  -m, --matrix_table <path>           Matrix table for talos (default: nextflow/cohort_outputs/cohort.mt)
  -p, --pedigree <path>               Pedigree file for talos (default: ped_files/pedigree.ped)
  -h, --help                          Show this help and exit

Examples:
  $0 --run annotation
  $0 --run talos --matrix_table my.mt --pedigree my.ped
  $0 --run both --large_files /data/large_files --input_vcf_dir /data/vcfs

Real Example:
  sbatch run_annot_talos.slurm --run both --large_files large_files/ --input_vcf_dir data/multi_sample_vcf/ --pedigree ped_files/multi_sample_vcf_pedgree.ped 
  sbatch run_annot_talos.slurm --run talos --large_files large_files/ --input_vcf_dir data/full_cohort/ --pedigree ped_files/full_cohort.ped 


## Important Notes:
  - Before Running Talos ensure that you have the latest ClinvArbitration from this link https://zenodo.org/records/17577130


EOF
}

# defaults
run_mode=""
large_files="large_files/"
input_vcf_dir="nextflow/inputs/individual_vcfs"
anno_config="nextflow/annotation.config"
talos_config="nextflow/talos.config"
matrix_table="nextflow/cohort_outputs/cohort.mt"
pedigree="ped_files/pedigree.ped"

# parse args (supports long and short options)
while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--run)
      run_mode="${2:-}"; shift 2 ;;
    -l|--large_files)
      large_files="${2:-}"; shift 2 ;;
    -i|--input_vcf_dir)
      input_vcf_dir="${2:-}"; shift 2 ;;
    -a|--anno_config)
      anno_config="${2:-}"; shift 2 ;;
    -t|--talos_config)
      talos_config="${2:-}"; shift 2 ;;
    -m|--matrix_table)
      matrix_table="${2:-}"; shift 2 ;;
    -p|--pedigree)
      pedigree="${2:-}"; shift 2 ;;
    -h|--help)
      print_usage; exit 0 ;;
    --) shift; break ;;
    -*)
      echo "Unknown option: $1" >&2; print_usage; exit 1 ;;
    *)
      echo "Unknown argument: $1" >&2; print_usage; exit 1 ;;
  esac
done

# validations
if [[ -z "$run_mode" ]]; then
  echo "Error: --run is required" >&2
  print_usage
  exit 1
fi

if [[ "$run_mode" != "annotation" && "$run_mode" != "talos" && "$run_mode" != "both" ]]; then
  echo "Error: --run must be one of: annotation, talos, both" >&2
  exit 1
fi

if [[ "$run_mode" == "annotation" || "$run_mode" == "both" ]]; then
  if [[ -z "$input_vcf_dir" ]]; then
    echo "Error: annotation requires --input_vcf_dir" >&2
    exit 1
  fi
  if [[ ! -f "$anno_config" && ! -d "$anno_config" && ! -r "$anno_config" ]]; then
    # still allow if config is not present (Nextflow will complain), but warn
    echo "Warning: annotation config '$anno_config' may not exist or be readable" >&2
  fi
fi

if [[ "$run_mode" == "talos" || "$run_mode" == "both" ]]; then
  if [[ -z "$matrix_table" || -z "$pedigree" ]]; then
    echo "Error: talos requires --matrix_table and --pedigree" >&2
    exit 1
  fi
  if [[ ! -f "$talos_config" && ! -d "$talos_config" && ! -r "$talos_config" ]]; then
    echo "Warning: talos config '$talos_config' may not exist or be readable" >&2
  fi
fi

# run workflows
if [[ "$run_mode" == "annotation" || "$run_mode" == "both" ]]; then
  echo "Running annotation workflow..."
  nextflow -c "$anno_config" run nextflow/annotation.nf --large_files "$large_files" --input_vcf_dir "$input_vcf_dir"
fi

if [[ "$run_mode" == "talos" || "$run_mode" == "both" ]]; then
  echo "Running talos workflow..."
  nextflow -c "$talos_config" run nextflow/talos.nf --matrix_table "$matrix_table" --pedigree "$pedigree"
fi

echo "Done."


































# module load singularity/v4.1.3
# module load nextflow/v24.04.3

# nextflow -c nextflow/annotation.config run nextflow/annotation.nf --large_files large_files/ --input_vcf_dir nextflow/inputs/individual_vcfs
# nextflow -c nextflow/talos.config run nextflow/talos.nf --matrix_table nextflow/cohort_outputs/cohort.mt --pedigree nextflow/inputs/pedigree.ped



# nextflow -c nextflow/annotation.config run nextflow/annotation.nf --large_files large_files/ --input_vcf_dir data_back
# nextflow -c nextflow/talos.config run nextflow/talos.nf --matrix_table nextflow/cohort_outputs/cohort.mt --pedigree ped_files/pedigree.ped