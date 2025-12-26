#!/bin/bash
# ============================================
# SIADUAN PROTOCOL - Register Feed
# ============================================
# This script registers your FeedProxy on the Siaduan Hub.
# Make sure you have:
#   1. Deployed a FeedProxy (run 1_deploy_proxy.sh first)
#   2. REACT tokens in your wallet on Lasna

set -e

# Load environment
set -a
[ -f .env ] && . ./.env
set +a

echo "============================================"
echo "  SIADUAN - Register Feed on Hub"
echo "============================================"
echo "Hub Address: $SIADUAN_HUB_ADDR"
echo "Chainlink Aggregator: $CHAINLINK_AGGREGATOR"
echo "Destination Chain: $DEST_CHAIN_ID"
echo "Your Proxy: $MY_PROXY_ADDR"
echo "============================================"
echo ""

if [ -z "$MY_PROXY_ADDR" ]; then
    echo "ERROR: MY_PROXY_ADDR is not set in .env"
    echo "Please deploy a proxy first using 1_deploy_proxy.sh"
    exit 1
fi

# Register on Hub
~/.foundry/bin/cast send $SIADUAN_HUB_ADDR \
    "registerFeed(address,uint256,address)" \
    $CHAINLINK_AGGREGATOR \
    $DEST_CHAIN_ID \
    $MY_PROXY_ADDR \
    --rpc-url $REACTIVE_RPC_URL \
    --private-key $PRIVATE_KEY \
    --legacy

echo ""
echo "============================================"
echo "  SUCCESS! Your feed is now registered."
echo "  The Hub will automatically push updates"
echo "  from Chainlink to your proxy."
echo "============================================"
