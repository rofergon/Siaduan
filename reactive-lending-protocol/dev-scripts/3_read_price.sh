#!/bin/bash
# ============================================
# SIADUAN PROTOCOL - Read Price
# ============================================
# This script reads the latest price from a FeedProxy.

set -e

# Load environment
set -a
[ -f .env ] && . ./.env
set +a

# Allow passing proxy address as argument or use .env
PROXY_ADDR=${1:-$MY_PROXY_ADDR}
RPC_URL=${2:-$SEPOLIA_RPC_URL}

if [ -z "$PROXY_ADDR" ]; then
    echo "Usage: ./3_read_price.sh [PROXY_ADDRESS] [RPC_URL]"
    echo "Or set MY_PROXY_ADDR in .env"
    exit 1
fi

echo "============================================"
echo "  SIADUAN - Read Latest Price"
echo "============================================"
echo "Proxy Address: $PROXY_ADDR"
echo "RPC: $RPC_URL"
echo "============================================"
echo ""

# Read description
DESC=$(~/.foundry/bin/cast call $PROXY_ADDR "description()(string)" --rpc-url $RPC_URL)
echo "Feed: $DESC"

# Read decimals
DECIMALS=$(~/.foundry/bin/cast call $PROXY_ADDR "decimals()(uint8)" --rpc-url $RPC_URL)
echo "Decimals: $DECIMALS"

# Read latest round data
echo ""
echo "Latest Round Data:"
~/.foundry/bin/cast call $PROXY_ADDR "latestRoundData()(uint80,int256,uint256,uint256,uint80)" --rpc-url $RPC_URL

echo ""
echo "============================================"
