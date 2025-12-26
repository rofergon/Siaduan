#!/bin/bash
set -a
[ -f .env ] && . ./.env
set +a

AGGREGATOR="0x694AA1769357215DE4FAC081bf1f309aDC325306"

echo "Registering via cast send..."
echo "Hub: $HUB_ADDR"
echo "Aggregator: $AGGREGATOR"
echo "Dest Chain: $SEPOLIA_CHAIN_ID"
echo "Proxy: $FEED_PROXY_ADDR"

~/.foundry/bin/cast send $HUB_ADDR "registerFeed(address,uint256,address)" $AGGREGATOR $SEPOLIA_CHAIN_ID $FEED_PROXY_ADDR --rpc-url $REACTIVE_RPC_URL --private-key $PRIVATE_KEY --legacy
