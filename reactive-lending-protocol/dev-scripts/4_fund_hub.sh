#!/bin/bash
# ============================================
# SIADUAN PROTOCOL - Fund Hub
# ============================================
# This script sends REACT tokens to the Siaduan Hub.
# The Hub needs REACT to pay for cross-chain callbacks.

set -e

# Load environment
set -a
[ -f .env ] && . ./.env
set +a

# Amount to send (in REACT, will be converted to wei)
AMOUNT_REACT=${1:-1}
AMOUNT_WEI=$(echo "$AMOUNT_REACT * 1000000000000000000" | bc)

echo "============================================"
echo "  SIADUAN - Fund Hub with REACT"
echo "============================================"
echo "Hub Address: $SIADUAN_HUB_ADDR"
echo "Amount: $AMOUNT_REACT REACT ($AMOUNT_WEI wei)"
echo "============================================"
echo ""

# Check current balance
echo "Current Hub Balance:"
~/.foundry/bin/cast balance $SIADUAN_HUB_ADDR --rpc-url $REACTIVE_RPC_URL

echo ""
echo "Sending $AMOUNT_REACT REACT..."

# Send REACT
~/.foundry/bin/cast send $SIADUAN_HUB_ADDR \
    --value $AMOUNT_WEI \
    --rpc-url $REACTIVE_RPC_URL \
    --private-key $PRIVATE_KEY \
    --legacy

echo ""
echo "New Hub Balance:"
~/.foundry/bin/cast balance $SIADUAN_HUB_ADDR --rpc-url $REACTIVE_RPC_URL

echo ""
echo "============================================"
echo "  SUCCESS! Hub has been funded."
echo "============================================"
