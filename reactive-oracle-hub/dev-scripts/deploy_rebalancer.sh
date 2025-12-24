#!/bin/bash
# Deploy LendingRebalancer to Reactive Network (Lasna)
# Prerequisites:
#   - REACTIVE_PRIVATE_KEY set in .env
#   - POOL_A_ADDRESS, POOL_B_ADDRESS, VAULT_ADDRESS set in .env (from Sepolia deployment)
#   - Sufficient REACT tokens for deployment and callbacks

set -e

echo "Loading environment..."
source .env

# Validate required env vars
if [ -z "$POOL_A_ADDRESS" ] || [ -z "$POOL_B_ADDRESS" ] || [ -z "$VAULT_ADDRESS" ]; then
    echo "Error: Missing required addresses. Set POOL_A_ADDRESS, POOL_B_ADDRESS, and VAULT_ADDRESS in .env"
    exit 1
fi

echo "Deploying LendingRebalancer to Lasna..."
echo "  Pool A: $POOL_A_ADDRESS"
echo "  Pool B: $POOL_B_ADDRESS"  
echo "  Vault: $VAULT_ADDRESS"

forge script script/DeployLendingRebalancer.s.sol:DeployLendingRebalancer \
    --rpc-url https://lasna-rpc.rnk.dev/ \
    --private-key $REACTIVE_PRIVATE_KEY \
    --broadcast \
    --legacy \
    -vvv

echo ""
echo "Deployment complete!"
echo ""
echo "IMPORTANT: Fund the LendingRebalancer with REACT tokens:"
echo "  cast send <REBALANCER_ADDRESS> --value 5ether --rpc-url https://lasna-rpc.rnk.dev/ --private-key \$REACTIVE_PRIVATE_KEY --legacy"
echo ""
echo "Then update the vault's authorizedReactVM on Sepolia:"
echo "  cast send $VAULT_ADDRESS 'setAuthorizedReactVM(address)' <DEPLOYER_ADDRESS> --rpc-url \$SEPOLIA_RPC --private-key \$SEPOLIA_PRIVATE_KEY"
