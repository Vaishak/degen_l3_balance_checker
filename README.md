# Degen L3 Balance Checker

This project contains a set of bash scripts for checking token balances on the Degen L3 blockchain. It's designed to compare balances before and after a network reorganization (reorg) event.

## Prerequisites

Before you begin, ensure you have the following installed:
- Bash (Unix shell)
- Foundry (for the `cast` command)

## Installation

1. Install Foundry:
   ```
   curl -L https://foundry.paradigm.xyz | bash
   ```
   Follow the on-screen instructions to complete the installation.

2. Clone this repository:
   ```
   git clone <repository-url>
   cd <repository-name>
   ```

3. Make the scripts executable:
   ```
   chmod +x *.sh
   ```

## Scripts

### 1. multi_address_balance_check.sh

This script checks the balance of multiple addresses for both DEGEN and PROXY tokens.

Usage:
```
./multi_address_balance_check.sh <address_csv_file> <block_number>
```

### 2. pool_token_balance_check.sh

This script checks the balance of token pairs in liquidity pools.

Usage:
```
./pool_token_balance_check.sh <block_number>
```

### 3. token_balance_check.sh

This script checks the balance of a specific ERC20 token for multiple addresses.

Usage:
```
./token_balance_check.sh <address_csv_file> <block_number> <token_address> [output_file]
```

## Input Files

1. `address_list.csv`: Contains a list of addresses to check balances for.
2. `proxy_eligible_pools.csv`: Contains information about liquidity pools, including pool addresses and token pairs.

## Output

All scripts generate CSV files with balance information. The default output file is `balance_output.csv` unless specified otherwise.

## Notes

- The scripts use two RPC endpoints:
  - Pre-reorg: https://pre-reorg-rpc-degen-mainnet-1.t.conduit.xyz
  - Post-reorg: https://rpc.degen.tips
- Balances are converted from wei to ether (1e18 conversion) in the output.
- Error handling is implemented to manage RPC call failures.
