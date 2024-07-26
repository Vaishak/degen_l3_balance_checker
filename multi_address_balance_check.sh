#!/bin/bash

# Hardcoded values
proxy_address=0xa051a2cb19c00ecdffae94d0ff98c17758041d16
post_org_rpc=https://rpc.degen.tips
pre_org_rpc=https://pre-reorg-rpc-degen-mainnet-1.t.conduit.xyz
output_file="balance_output.csv"

# Function to display usage
usage() {
    echo "Usage: $0 <address_csv_file> <block_number>"
    echo "  <address_csv_file>: Path to the CSV file containing addresses"
    echo "  <block_number>: Block number to check balances at"
    exit 1
}

# Check if correct number of arguments is provided
if [ $# -ne 2 ]; then
    usage
fi

input_file=$1
block_number=$2

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

# Function to get balance
get_balance() {
    cast balance $1 --block $2 --rpc-url $3
}

# Function to get ERC20 balance
get_erc20_balance() {
    cast balance --erc20 $1 $2 --block $3 --rpc-url $4
}

# Function to convert wei to ether (1e18 conversion)
convert_to_ether() {
    echo "scale=18; $1 / 1000000000000000000" | bc
}

# Create CSV header
echo "address,block_number,pre_org_degen,post_org_degen,pre_org_proxy,post_org_proxy" > $output_file

# Read unique addresses from the input file, skipping the header
unique_addresses=$(tail -n +2 "$input_file" | sort -u)

# Process each unique address
total_addresses=$(echo "$unique_addresses" | wc -l)
current_address=0

for address in $unique_addresses; do
    current_address=$((current_address + 1))
    echo "Processing address $current_address of $total_addresses: $address"
    
    pre_org_degen=$(get_balance $address $block_number $pre_org_rpc)
    post_org_degen=$(get_balance $address $block_number $post_org_rpc)
    pre_org_proxy=$(get_erc20_balance $proxy_address $address $block_number $pre_org_rpc)
    post_org_proxy=$(get_erc20_balance $proxy_address $address $block_number $post_org_rpc)
    
    # Convert balances from wei to ether
    pre_org_degen=$(convert_to_ether $pre_org_degen)
    post_org_degen=$(convert_to_ether $post_org_degen)
    pre_org_proxy=$(convert_to_ether $pre_org_proxy)
    post_org_proxy=$(convert_to_ether $post_org_proxy)
    
    echo "$address,$block_number,$pre_org_degen,$post_org_degen,$pre_org_proxy,$post_org_proxy" >> $output_file
done

echo "Processing complete. Results saved to $output_file"
