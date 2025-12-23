#!/bin/bash
set -a
[ -f .env ] && . ./.env
set +a

echo "Deploying ReactOracleHub to Lasna..."
~/.foundry/bin/forge script script/DeployHub.s.sol --rpc-url $REACTIVE_RPC_URL --broadcast --legacy
