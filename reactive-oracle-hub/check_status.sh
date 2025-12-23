#!/bin/bash
set -a
[ -f .env ] && . ./.env
set +a

echo "Deployer Address:"
# Extracting deployer address from PK (safely)
~/.foundry/bin/cast wallet address --private-key $PRIVATE_KEY

echo "Deployer Balance:"
~/.foundry/bin/cast balance $(~/.foundry/bin/cast wallet address --private-key $PRIVATE_KEY) --rpc-url $REACTIVE_RPC_URL

echo "Origin Chain ID in Hub:"
~/.foundry/bin/cast call $HUB_ADDR "originChainId()(uint256)" --rpc-url $REACTIVE_RPC_URL
