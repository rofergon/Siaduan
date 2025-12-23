# 🛠 Siaduan Protocol - Developer Scripts

Quick scripts to interact with the Siaduan Protocol. Perfect for developers who want to integrate or extend the oracle system.

## Quick Start

```bash
# 1. Copy the example config
cp .env.example .env

# 2. Edit .env with your private key and settings
nano .env

# 3. Make scripts executable
chmod +x *.sh
```

## Available Scripts

| Script | Description |
|--------|-------------|
| `1_deploy_proxy.sh` | Deploy a new FeedProxy on your destination chain |
| `2_register_feed.sh` | Register your proxy on the Siaduan Hub |
| `3_read_price.sh` | Read the latest price from any FeedProxy |
| `4_fund_hub.sh` | Send REACT tokens to keep the Hub running |
| `5_check_status.sh` | Check Hub balance and subscription status |

## Workflow

### Adding a New Price Feed

1. **Deploy Proxy**: Edit `1_deploy_proxy.sh` to set your `DESCRIPTION` and `DECIMALS`
   ```bash
   ./1_deploy_proxy.sh
   ```
2. **Update .env**: Copy the deployed address to `MY_PROXY_ADDR`
3. **Register Feed**: 
   ```bash
   ./2_register_feed.sh
   ```
4. **Verify**: 
   ```bash
   ./3_read_price.sh
   ```

### Maintaining the Hub

Check if the Hub needs more REACT:
```bash
./5_check_status.sh
```

Fund it if low:
```bash
./4_fund_hub.sh 5  # Sends 5 REACT
```

## Configuration

All scripts read from `.env`. Key variables:

| Variable | Description |
|----------|-------------|
| `PRIVATE_KEY` | Your wallet key (with 0x) |
| `MY_PROXY_ADDR` | Your deployed FeedProxy address |
| `CHAINLINK_AGGREGATOR` | Source Chainlink feed to mirror |
| `DEST_CHAIN_ID` | Target chain for your proxy |

## Requirements

- **Foundry** (forge, cast): [Install](https://book.getfoundry.sh/getting-started/installation)
- **WSL** (on Windows) or native Linux/macOS
- **REACT tokens** on Lasna testnet
- **SepoliaETH** for destination chain deployment
