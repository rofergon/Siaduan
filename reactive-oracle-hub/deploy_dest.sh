#!/bin/bash
set -a
[ -f .env ] && . ./.env
set +a

echo "Deploying Destination..."
~/.foundry/bin/forge script script/DeployDestination.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast
