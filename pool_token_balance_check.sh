#!/bin/bash

# Hardcoded values
post_org_rpc=https://rpc.degen.tips
pre_org_rpc=https://pre-reorg-rpc-degen-mainnet-1.t.conduit.xyz
input_file="proxy_eligible_pools.csv"
output_file="pool_token_balances.csv"

# Function to display usage
usage() {
    echo "Usage: $0 <block_number>"
    echo "  <block_number>: Block number to check balances at"
    exit 1
}

# Check if block number is provided
if [ $# -ne 1 ]; then
    usage
fi

block_number=$1

# Check if block number is a valid number
if ! [[ "$block_number" =~ ^[0-9]+$ ]]; then
    echo "Error: Block number must be a valid integer."
    exit 1
fi

# Check if input file exists
if [ ! -f "$input_file" ]; then
    echo "Error: Input file '$input_file' not found."
    exit 1
fi

# Function to get ERC20 balance
get_erc20_balance() {
    local result=$(cast balance $1 --block $2 --erc20 $3 -r $4 2>&1)
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
echo "pool_address,token_1,token_2,token_1_name,token_2_name,block_number,pre_org_token1,post_org_token1,pre_org_token2,post_org_token2" > $output_file

# Read pool addresses and token addresses from the input file, skipping the header
while IFS=',' read -r pool_address token_1 token_2 token_1_name token_2_name || [ -n "$pool_address" ]
do
    # Skip the header
    if [[ $pool_address == "pool_address" ]]; then
        continue
    fi

    # Strip whitespace
    pool_address=$(echo $pool_address | tr -d '[:space:]')
    token_1=$(echo $token_1 | tr -d '[:space:]')
    token_2=$(echo $token_2 | tr -d '[:space:]')
    token_1_name=$(echo $token_1_name | tr -d '[:space:]')
    token_2_name=$(echo $token_2_name | tr -d '[:space:]')

    echo "Processing pool address: $pool_address"
    
    pre_org_token1=$(get_erc20_balance $pool_address $block_number $token_1 $pre_org_rpc)
    post_org_token1=$(get_erc20_balance $pool_address $block_number $token_1 $post_org_rpc)
    pre_org_token2=$(get_erc20_balance $pool_address $block_number $token_2 $pre_org_rpc)
    post_org_token2=$(get_erc20_balance $pool_address $block_number $token_2 $post_org_rpc)
    
    # Convert balances from wei to ether
    pre_org_token1=$(convert_to_ether $pre_org_token1)
    post_org_token1=$(convert_to_ether $post_org_token1)
    pre_org_token2=$(convert_to_ether $pre_org_token2)
    post_org_token2=$(convert_to_ether $post_org_token2)
    
    echo "$pool_address,$token_1,$token_2,$token_1_name,$token_2_name,$block_number,$pre_org_token1,$post_org_token1,$pre_org_token2,$post_org_token2" >> $output_file
done < "$input_file"

echo "Processing complete. Results saved to $output_file"
