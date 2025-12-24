#!/bin/bash
# Deploy LendingVault system to Sepolia
# Prerequisites: 
#   - SEPOLIA_PRIVATE_KEY set in .env
#   - SEPOLIA_RPC set in .env
#   - Sufficient Sepolia ETH for gas

set -e

echo "Loading environment..."
source .env

echo "Deploying LendingVault to Sepolia..."

forge script script/DeployLendingVault.s.sol:DeployLendingVault \
    --rpc-url $SEPOLIA_RPC \
    --private-key $SEPOLIA_PRIVATE_KEY \
    --broadcast \
    --legacy \
    -vvv

echo ""
echo "Deployment complete! Save the contract addresses above."
echo "Next: Run deploy_rebalancer.sh after setting POOL_A_ADDRESS, POOL_B_ADDRESS, and VAULT_ADDRESS in .env"
