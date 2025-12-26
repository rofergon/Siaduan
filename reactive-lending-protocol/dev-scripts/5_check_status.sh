#!/bin/bash
# ============================================
# SIADUAN PROTOCOL - Check Hub Status
# ============================================
# This script shows the current status of the Siaduan Hub.

set -e

# Load environment
set -a
[ -f .env ] && . ./.env
set +a

echo "============================================"
echo "  SIADUAN - Hub Status"
echo "============================================"
echo "Hub Address: $SIADUAN_HUB_ADDR"
echo "============================================"
echo ""

# Check Hub balance
echo "Hub REACT Balance:"
~/.foundry/bin/cast balance $SIADUAN_HUB_ADDR --rpc-url $REACTIVE_RPC_URL
echo ""

# Check origin chain ID
echo "Origin Chain ID:"
~/.foundry/bin/cast call $SIADUAN_HUB_ADDR "originChainId()(uint256)" --rpc-url $REACTIVE_RPC_URL
echo ""

# Check if a specific aggregator is subscribed
if [ ! -z "$CHAINLINK_AGGREGATOR" ]; then
    echo "Is $CHAINLINK_AGGREGATOR subscribed?"
    ~/.foundry/bin/cast call $SIADUAN_HUB_ADDR "isSubscribed(address)(bool)" $CHAINLINK_AGGREGATOR --rpc-url $REACTIVE_RPC_URL
fi

echo ""
echo "============================================"
