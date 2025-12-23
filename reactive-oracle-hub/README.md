# ReactOracle Hub (Universal Cross-Chain Oracle)

This project implements a permissionless cross-chain oracle hub on the Reactive Network. It allows anyone to register a Chainlink Price Feed on an origin chain (e.g., Ethereum Sepolia) and replicate its data to a destination chain (e.g., Sepolia, Polygon, etc.) via Reactive Smart Contracts.

## 🏆 Bounty Requirements Met
- **Reactive Network**: Uses RSC to listen to `AnswerUpdated` events.
- **AggregatorV3Interface**: Destination proxy is fully compatible.
- **Cross-Chain**: Demonstrates Origin -> Reactive -> Destination flow.
- **Universal**: Supports registration of ANY feed, not just one hardcoded.

## Architecture

1.  **Origin (Sepolia)**: Chainlink Aggregator (e.g., ETH/USD).
2.  **Reactive (Lasna)**: `ReactOracleHub` listens to events and multicasts callback.
3.  **Destination (Sepolia/Polygon)**: `FeedProxy` receives updates and serves data.

## Setup

1.  **Install Foundry**:
    ```bash
    curl -L https://foundry.paradigm.xyz | bash
    foundryup
    ```
2.  **Install Dependencies**:
    ```bash
    forge install
    ```
3.  **Configure Environment**:
    Fill in `.env` with:
    - `PRIVATE_KEY`: Your deployer wallet key.
    - `SEPOLIA_RPC_URL`: RPC for Sepolia.
    - `REACTIVE_RPC_URL`: RPC for Lasna (`https://lasna-rpc.rnk.dev/`).
    - `CALLBACK_PROXY_ADDR_SEPOLIA`: `0xc9f36411C9897e7F959D99ffca2a0Ba7ee0D7bDA`.

## Deployment

### 1. Deploy Destination Contract (FeedProxy)
```bash
forge script script/DeployDestination.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast
```
*Take note of the deployed FeedProxy address.*

### 2. Deploy Reactive Hub
```bash
forge script script/DeployHub.s.sol --rpc-url $REACTIVE_RPC_URL --broadcast --legacy
```
*Take note of the deployed ReactOracleHub address.*

### 3. Register Feed
Update `.env` with:
- `FEED_PROXY_ADDR=<address from step 1>`
- `HUB_ADDR=<address from step 2>`

Run registration:
```bash
forge script script/RegisterFeed.s.sol --rpc-url $REACTIVE_RPC_URL --broadcast --legacy
```

## Testing

Run unit tests:
```bash
forge test
```
