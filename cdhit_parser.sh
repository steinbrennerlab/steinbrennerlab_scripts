#!/bin/bash
#Sept 2024, ADS w/ Claude 3.5 Sonnet

# Function to print usage information
usage() {
    echo "Usage: $0 -i <input_file> -o <output_file>"
    echo "  -i, --input    Input CD-HIT cluster file"
    echo "  -o, --output   Output file for gene clusters"
    echo "  -h, --help     Display this help message"
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--input)
            input_file="$2"
            shift 2
            ;;
        -o|--output)
            output_file="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Check if input and output files are provided
if [ -z "$input_file" ] || [ -z "$output_file" ]; then
    echo "Error: Input and output files are required."
    usage
    exit 1
fi

# Define the species output file
species_output_file="${output_file%.*}_species.txt"

# Clear the output files if they already exist
> "$output_file"
> "$species_output_file"

# Add header to the first output file
echo -e "taxa\tcluster" > "${output_file%.*}.txt"

# Initialize variables
cluster_num=0
declare -A cluster_sizes
declare -A species_counts
declare -A species_list

# First pass: Identify all species
while IFS= read -r line; do
    if [[ $line == *"aa,"* ]]; then
        gene=$(echo "$line" | awk -F'>' '{print $2}' | awk '{print $1}' | sed 's/\.\.\.//')
        species=${gene:0:2}
        species_list[$species]=1
    fi
done < "$input_file"

# Process the input file
while IFS= read -r line; do
    if [[ $line == ">Cluster"* ]]; then
        # Extract cluster number
        cluster_num=$(echo "$line" | awk '{print $2}')
        cluster_sizes[$cluster_num]=0
        for sp in "${!species_list[@]}"; do
            species_counts[$cluster_num,$sp]=0
        done
    elif [[ $line == *"aa,"* ]]; then
        # Extract gene name
        gene=$(echo "$line" | awk -F'>' '{print $2}' | awk '{print $1}' | sed 's/\.\.\.//')
        
        # Write gene and cluster number to output file
        echo -e "${gene}\t${cluster_num}" >> "$output_file"
        
        # Increment cluster size
        ((cluster_sizes[$cluster_num]++))
        
        # Increment species count
        species=${gene:0:2}
        ((species_counts[$cluster_num,$species]++))
    fi
done < "$input_file"

echo "Processing complete. Results saved in $output_file"

# Output cluster sizes
echo -e "\nCluster sizes:"
for cluster in "${!cluster_sizes[@]}"; do
    echo "Cluster $cluster: ${cluster_sizes[$cluster]} genes"
done | sort -V

# Calculate and print total number of genes
total_genes=$(awk '{sum += $2} END {print sum}' <<< "$(for size in "${cluster_sizes[@]}"; do echo "0 $size"; done)")
echo -e "\nTotal number of genes: $total_genes"

# Write species distribution to the species output file
echo -n "Cluster" > "$species_output_file"
for sp in $(echo "${!species_list[@]}" | tr ' ' '\n' | sort); do
    echo -n -e "\t$sp" >> "$species_output_file"
done
echo "" >> "$species_output_file"

for cluster in $(echo "${!cluster_sizes[@]}" | tr ' ' '\n' | sort -n); do
    echo -n "$cluster" >> "$species_output_file"
    for sp in $(echo "${!species_list[@]}" | tr ' ' '\n' | sort); do
        echo -n -e "\t${species_counts[$cluster,$sp]}" >> "$species_output_file"
    done
    echo "" >> "$species_output_file"
done

echo "Species distribution saved in $species_output_file"