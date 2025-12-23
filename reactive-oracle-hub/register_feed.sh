#!/bin/bash
set -a
[ -f .env ] && . ./.env
set +a

echo "Registering Feed on Lasna..."
~/.foundry/bin/forge script script/RegisterFeed.s.sol --rpc-url $REACTIVE_RPC_URL --broadcast --legacy -vvvv
