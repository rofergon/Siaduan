# 🌐 Siaduan Protocol: Complete Technical Documentation

> **Siaduan** is a decentralized, permissionless cross-chain oracle infrastructure powered by **Reactive Network**. It replicates Chainlink price feeds from any origin chain to any destination chain with near-zero latency.

---

## Table of Contents
1.  [Architecture Overview](#-architecture-overview)
2.  [Core Contracts](#-core-contracts)
3.  [Fee Model & REACT Tokens](#-fee-model--react-tokens)
4.  [Integration Guide (Consumers)](#-integration-guide-consumers)
5.  [Registration Guide (Operators)](#-registration-guide-operators)
6.  [Security Model](#-security-model)
7.  [Network Parameters](#-network-parameters)

---

## 🏗 Architecture Overview

Siaduan operates across three distinct layers:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              ORIGIN CHAIN                                   │
│                        (e.g., Ethereum Sepolia)                             │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │        Chainlink Aggregator (ETH/USD)                               │    │
│  │        Emits: AnswerUpdated(int256 price, uint256 roundId, ...)     │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ Event Subscription
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           REACTIVE NETWORK                                  │
│                              (Lasna)                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                    ReactOracleHub (Siaduan Hub)                     │    │
│  │  • Subscribes to Chainlink events on Origin chain                   │    │
│  │  • Maintains registry of Destination proxies                        │    │
│  │  • Emits Callback events → triggers cross-chain txs                 │    │
│  │  • PAYS for callbacks using its REACT balance                       │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ Reactive Callback (cross-chain tx)
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          DESTINATION CHAIN                                  │
│                   (e.g., Sepolia, Polygon, Arbitrum)                        │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         FeedProxy                                   │    │
│  │  • Implements AggregatorV3Interface (Chainlink-compatible)          │    │
│  │  • Stores historical round data                                     │    │
│  │  • Only accepts updates from authorized ReactVM                     │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                    │                                        │
│                                    ▼                                        │
│                          ┌─────────────────┐                                │
│                          │   Your DApp     │                                │
│                          │ (reads oracle)  │                                │
│                          └─────────────────┘                                │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📄 Core Contracts

### 1. ReactOracleHub (Reactive Network)
**Address (Lasna Testnet):** `0x7dfb4000f1dd4292857d9bc2629bf5543f4bedf7`

| Function | Description |
|----------|-------------|
| `registerFeed(address aggregator, uint256 destChainId, address proxy)` | Registers a new price feed for cross-chain replication |
| `react(LogRecord calldata log)` | Internal: Processes incoming events and emits callbacks |
| `feedDestinations(address)` | View: Returns registered destinations for an aggregator |
| `isSubscribed(address)` | View: Checks if an aggregator is being monitored |

**Key Constants:**
- `CALLBACK_GAS_LIMIT`: 500,000 gas per callback
- `ANSWER_UPDATED_TOPIC_0`: Chainlink event signature hash

### 2. FeedProxy (Destination Chain)
**Address (Sepolia Testnet):** `0x103a023d4f4fffa48106345f9e40f86ae7278286`

| Function | Description |
|----------|-------------|
| `latestRoundData()` | Returns the most recent price data (Chainlink-compatible) |
| `getRoundData(uint80 roundId)` | Returns historical data for a specific round |
| `decimals()` | Returns price precision (e.g., 8 for USD feeds) |
| `description()` | Returns feed description (e.g., "ETH/USD") |

**Security:**
- `onlyReactive` modifier: Only accepts calls from Callback Proxy
- `authorizedReactVM` check: Verifies the caller's ReactVM ID matches the Hub

---

## 💰 Fee Model & REACT Tokens

### How Fees Work

The Siaduan Protocol operates on a **post-factum payment model**:

1. **No upfront gas for ReactVM**: When the Hub's `react()` function executes inside the ReactVM, there's no gas cost at that moment.
2. **Callback costs are charged later**: Each `Callback` event generates a real transaction on the destination chain. The cost is calculated as:
   ```
   Callback Cost = BaseFee × GasUsed
   ```
3. **Payment from Hub balance**: The Hub contract's REACT balance on Lasna is debited to cover these costs.

### Funding the Hub

> ⚠️ **CRITICAL**: If the Hub runs out of REACT, callbacks will stop and the contract may be blocklisted.

**To fund the Hub:**
```bash
# Send REACT tokens directly to the Hub address on Lasna
cast send 0x7dfb4000f1dd4292857d9bc2629bf5543f4bedf7 --value <amount_in_wei> --rpc-url https://lasna-rpc.rnk.dev/ --private-key $PRIVATE_KEY --legacy
```

**Recommended balance:** 10+ REACT for sustained operation (allows hundreds of price updates).

### Cost Estimation

| Action | Estimated Cost |
|--------|----------------|
| Register Feed | ~0.01 REACT (one-time) |
| Each Price Update (per destination) | ~0.05-0.15 REACT |
| Hub operational reserve | 5-10 REACT minimum |

---

## ⚡ Integration Guide (Consumers)

If you want to **read prices** from Siaduan in your DApp:

### Step 1: Import Interface
```solidity
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
```

### Step 2: Connect to Proxy
```solidity
AggregatorV3Interface internal priceFeed;

constructor() {
    // Siaduan ETH/USD Proxy on Sepolia
    priceFeed = AggregatorV3Interface(0x103a023d4f4fffa48106345f9e40f86ae7278286);
}
```

### Step 3: Read Price
```solidity
function getLatestPrice() public view returns (int256) {
    (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) = priceFeed.latestRoundData();
    
    // Optional: Validate freshness
    require(updatedAt > block.timestamp - 1 hours, "Stale price");
    
    return answer; // 8 decimals for USD feeds
}
```

---

## 🛠 Registration Guide (Operators)

If you want to **add a new price feed** to Siaduan:

### Prerequisites
1. Deploy a `FeedProxy` on your destination chain
2. Have REACT tokens on Lasna for fees
3. Know the Chainlink Aggregator address on the origin chain

### Step 1: Deploy FeedProxy
```solidity
FeedProxy proxy = new FeedProxy(
    0xc9f36411C9897e7F959D99ffca2a0Ba7ee0D7bDA, // Callback Proxy (Sepolia)
    0xaB6E247B25463F76E81aBAbBb6b0b86B40d45D38, // Your deployer address (ReactVM ID)
    8,                                           // Decimals
    "BTC/USD (Siaduan)"                          // Description
);
```

### Step 2: Register on Hub
```bash
cast send 0x7dfb4000f1dd4292857d9bc2629bf5543f4bedf7 \
  "registerFeed(address,uint256,address)" \
  <CHAINLINK_AGGREGATOR> \
  <DEST_CHAIN_ID> \
  <YOUR_PROXY_ADDRESS> \
  --rpc-url https://lasna-rpc.rnk.dev/ \
  --private-key $PRIVATE_KEY \
  --legacy
```

### Step 3: Fund the Hub
Ensure the Hub has sufficient REACT balance for ongoing operations.

---

## 🔒 Security Model

### Authentication Flow
```
Chainlink → Reactive Network → Callback Proxy → FeedProxy → DApp
                                    │
                              Injects ReactVM ID
                              (deployer address)
```

### Security Checks

| Layer | Check | Purpose |
|-------|-------|---------|
| FeedProxy | `msg.sender == callbackProxy` | Ensures call comes from official Reactive infrastructure |
| FeedProxy | `_sender == authorizedReactVM` | Verifies the ReactVM identity matches the Hub deployer |
| FeedProxy | `_roundId > latestRoundId` | Prevents replay/stale data attacks |
| ReactOracleHub | `vmOnly` modifier | Ensures `react()` only runs inside ReactVM sandbox |

### Trust Assumptions
- **Reactive Network infrastructure** is trusted to deliver callbacks correctly
- **Chainlink Aggregators** on origin chains are the source of truth
- **Hub deployer** controls which destinations receive updates

---

## 🔗 Network Parameters

### Testnet Configuration

| Network | Parameter | Value |
|---------|-----------|-------|
| **Reactive (Lasna)** | RPC URL | `https://lasna-rpc.rnk.dev/` |
| | Chain ID | `5318007` |
| | Explorer | `https://lasna-explorer.rnk.dev/` |
| | Siaduan Hub | `0x7dfb4000f1dd4292857d9bc2629bf5543f4bedf7` |
| **Sepolia** | Chain ID | `11155111` |
| | Callback Proxy | `0xc9f36411C9897e7F959D99ffca2a0Ba7ee0D7bDA` |
| | Siaduan ETH/USD Proxy | `0x103a023d4f4fffa48106345f9e40f86ae7278286` |
| | Chainlink ETH/USD Feed | `0x694AA1769357215DE4FAC081bf1f309aDC325306` |

### Supported Chains
The protocol can bridge to any chain supported by Reactive Network's callback infrastructure. Check [Reactive Network Docs](https://docs.reactive.network/origins-and-destinations) for the full list.

---

## 📚 Additional Resources

- **GitHub Repository**: [reactive-oracle-hub](./reactive-oracle-hub/)
- **Reactive Network Docs**: [https://docs.reactive.network](https://docs.reactive.network)
- **Chainlink Feed Registry**: [https://docs.chain.link/data-feeds](https://docs.chain.link/data-feeds)

---

*Built for the Reactive Network Hackathon 2024* 🏆
