#!/bin/bash
# ============================================
# SIADUAN PROTOCOL - Deploy FeedProxy
# ============================================
# This script deploys a new FeedProxy on your destination chain.
# Edit the variables below to customize your deployment.

set -e

# Load environment
set -a
[ -f .env ] && . ./.env
set +a

# ============================================
# CONFIGURATION (Edit these!)
# ============================================
DECIMALS=8                          # Price decimals (8 for USD feeds)
DESCRIPTION="ETH/USD (Siaduan)"     # Feed description
CALLBACK_PROXY=$CALLBACK_PROXY_SEPOLIA
RPC_URL=$SEPOLIA_RPC_URL

# Your deployer address is the authorized ReactVM ID
DEPLOYER=$(~/.foundry/bin/cast wallet address --private-key $PRIVATE_KEY)

echo "============================================"
echo "  SIADUAN - Deploy FeedProxy"
echo "============================================"
echo "Deployer (ReactVM ID): $DEPLOYER"
echo "Callback Proxy: $CALLBACK_PROXY"
echo "Decimals: $DECIMALS"
echo "Description: $DESCRIPTION"
echo "RPC: $RPC_URL"
echo "============================================"
echo ""

# Deploy using forge create
~/.foundry/bin/forge create \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    ../src/destination/FeedProxy.sol:FeedProxy \
    --constructor-args $CALLBACK_PROXY $DEPLOYER $DECIMALS "$DESCRIPTION"

echo ""
echo "============================================"
echo "  SUCCESS! Copy the 'Deployed to' address"
echo "  and add it to your .env as MY_PROXY_ADDR"
echo "============================================"
