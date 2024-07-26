#!/bin/bash

# Hardcoded values
post_org_rpc=https://rpc.degen.tips
pre_org_rpc=https://pre-reorg-rpc-degen-mainnet-1.t.conduit.xyz
default_output_file="balance_output.csv"

# Function to display usage
usage() {
    echo "Usage: $0 <address_csv_file> <block_number> <token_address> [output_file]"
    echo "  <address_csv_file>: Path to the CSV file containing addresses"
    echo "  <block_number>: Block number to check balances at"
    echo "  <token_address>: Address of the ERC20 token to check balances for"
    echo "  [output_file]: Optional. Name of the output CSV file (default: $default_output_file)"
    exit 1
}

# Check if correct number of arguments is provided
if [ $# -lt 3 ] || [ $# -gt 4 ]; then
    usage
fi

input_file=$1
block_number=$2
token_address=$3
output_file=${4:-$default_output_file}

# Check if input file exists
if [ ! -f "$input_file" ]; then
    echo "Error: Input file '$input_file' not found."
    exit 1
fi

# Check if block number is a valid number
if ! [[ "$block_number" =~ ^[0-9]+$ ]]; then
    echo "Error: Block number must be a valid integer."
    exit 1
fi

# Function to get ERC20 balance
get_erc20_balance() {
    local result=$(cast balance --erc20 $1 $2 --block $3 --rpc-url $4 2>&1)
    if [[ $result == *"error"* ]]; then
        echo "Error: $result" >&2
        echo "0"
    else
        echo "$result"
    fi
}

# Function to convert wei to ether (1e18 conversion)
convert_to_ether() {
    echo "scale=18; $1 / 1000000000000000000" | bc
}

# Create CSV header
echo "address,block_number,pre_org_token,post_org_token" > "$output_file"

# Get unique addresses, skipping the header
unique_addresses=$(tail -n +2 "$input_file" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sort -u)

# Count total unique addresses
total_addresses=$(echo "$unique_addresses" | wc -l)

current_address=0
echo "$unique_addresses" | while IFS= read -r address; do
    current_address=$((current_address + 1))
    echo "Processing address $current_address of $total_addresses: $address"
    
    pre_org_token=$(get_erc20_balance $token_address $address $block_number $pre_org_rpc)
    post_org_token=$(get_erc20_balance $token_address $address $block_number $post_org_rpc)
    
    # Convert balances from wei to ether
    pre_org_token=$(convert_to_ether $pre_org_token)
    post_org_token=$(convert_to_ether $post_org_token)
    
    echo "$address,$block_number,$pre_org_token,$post_org_token" >> "$output_file"
done

echo "Processing complete. Results saved to $output_file"
