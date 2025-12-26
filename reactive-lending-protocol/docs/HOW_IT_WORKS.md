# 🌐 ReactOracleHub - How It Works

## Overview

**ReactOracleHub** is a cross-chain oracle replication system that mirrors Chainlink price feeds from one blockchain (origin) to other blockchains (destinations) using the **Reactive Network**.

---

## Architecture

```
┌─────────────────────┐      ┌─────────────────────┐      ┌─────────────────────┐
│   ORIGIN CHAIN      │      │   REACTIVE NETWORK  │      │  DESTINATION CHAIN  │
│     (Sepolia)       │      │      (Lasna)        │      │   (Any EVM Chain)   │
│                     │      │                     │      │                     │
│  ┌───────────────┐  │      │  ┌───────────────┐  │      │  ┌───────────────┐  │
│  │   Chainlink   │  │ ───► │  │ ReactOracle   │  │ ───► │  │  FeedProxy    │  │
│  │  Aggregator   │  │Event │  │     Hub       │  │ Call │  │  (Your Proxy) │  │
│  │  (ETH/USD)    │  │      │  │   (ReactVM)   │  │ back │  │               │  │
│  └───────────────┘  │      │  └───────────────┘  │      │  └───────────────┘  │
│                     │      │                     │      │         │           │
│                     │      │                     │      │         ▼           │
│                     │      │                     │      │  ┌───────────────┐  │
│                     │      │                     │      │  │   Your DApp   │  │
│                     │      │                     │      │  └───────────────┘  │
└─────────────────────┘      └─────────────────────┘      └─────────────────────┘
```

---

## Data Flow

### Step 1: Initial Setup

1. **Deploy a `FeedProxy`** on your destination chain
2. **Register the feed** in `ReactOracleHub` on Reactive Network

```solidity
// On Reactive Network (Lasna)
hub.registerFeed(
    0x694AA...  // Chainlink ETH/USD aggregator on Sepolia
    421614,     // Destination Chain ID (e.g., Arbitrum Sepolia)
    0xABC...    // Your FeedProxy address on destination
);
```

### Step 2: Automatic Price Updates

```
1. 📡 Chainlink updates price on Sepolia
      └─→ Emits: AnswerUpdated(price, roundId, timestamp)
   
2. ⚡ Reactive Network captures the event
      └─→ ReactOracleHub.react() executes automatically
   
3. 🔄 ReactOracleHub constructs a callback
      └─→ Emits: Callback(destChainId, proxyAddr, payload)
   
4. 🎯 Reactive Network sends transaction to destination
      └─→ FeedProxy.updatePrice() is called
   
5. ✅ Price is now available on your chain
      └─→ Your DApp calls: proxy.latestRoundData()
```

---

## Core Contracts

### 1. ReactOracleHub
**Location:** Reactive Network (Lasna)  
**Role:** Listens to origin chain events, relays price updates to destinations

| Function | Description |
|----------|-------------|
| `registerFeed(aggregator, destChainId, proxy)` | Connect a Chainlink feed to a destination |
| `react(log)` | Automatically called when price updates occur |

### 2. FeedProxy
**Location:** Any EVM destination chain  
**Role:** Stores prices and exposes Chainlink-compatible interface

| Function | Description |
|----------|-------------|
| `updatePrice(...)` | Receives price updates (only from ReactOracleHub) |
| `latestRoundData()` | Returns the latest price data |
| `getRoundData(roundId)` | Returns historical price data |

### 3. FeedProxyFactory
**Location:** Destination chain (optional)  
**Role:** Factory for deploying multiple FeedProxy instances

---

## Security Model

```
┌─────────────────────────────────────────────────────────┐
│                    FeedProxy Security                   │
├─────────────────────────────────────────────────────────┤
│ Layer 1: Callback Proxy Verification                    │
│   └─→ require(msg.sender == callbackProxy)              │
│                                                         │
│ Layer 2: ReactVM Authorization                          │
│   └─→ require(_sender == authorizedReactVM)             │
│                                                         │
│ Layer 3: Freshness Check                                │
│   └─→ require(_roundId > latestRoundId)                 │
└─────────────────────────────────────────────────────────┘
```

- **Only the Callback Proxy** can call `updatePrice()`
- **Only the authorized ReactVM** (ReactOracleHub) can send valid updates
- **Stale data is rejected** - roundId must be strictly increasing

---

## Integration Example

```solidity
// Your contract on any destination chain
import "IAggregatorV3Interface.sol";

contract MyDeFiProtocol {
    IAggregatorV3Interface public priceFeed;
    
    constructor(address _feedProxy) {
        priceFeed = IAggregatorV3Interface(_feedProxy);
    }
    
    function getETHPrice() public view returns (int256) {
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        
        return answer; // ETH/USD price replicated from Sepolia
    }
}
```

---

## Use Cases

| Use Case | Description |
|----------|-------------|
| **DeFi on L2s** | Access Chainlink prices on rollups without native feeds |
| **New Chains** | Bring oracle data to emerging blockchains |
| **Price Consistency** | Same price across multiple chains simultaneously |
| **Cost Efficiency** | Pay only for the specific feeds you need |

---

## Contract Addresses

| Contract | Network | Address |
|----------|---------|---------|
| ReactOracleHub | Lasna (Reactive) | `<PENDING>` |
| FeedProxy (ETH/USD) | Sepolia | `<PENDING>` |
| Callback Proxy | Sepolia | `0x33Bbb7D0a2F1029550B0e91f653c4055DC9F4Dd8` |

---

## Technical Details

### Chainlink Event Listened

```solidity
event AnswerUpdated(
    int256 indexed current,    // topic_1: The updated price
    uint256 indexed roundId,   // topic_2: The round ID
    uint256 updatedAt          // data: Timestamp
);
```

**Event Topic 0:** `0x0559884fd3a460db3073b7fc896cc77986f16e378210ded43186175bf646fc5f`

### Callback Gas Limit

Default: `500,000 gas` per callback

---

## Fees

| Fee Type | Who Pays | Description |
|----------|----------|-------------|
| REACT tokens | ReactVM owner | Consumed for cross-chain callbacks |
| Destination gas | Reactive Network | Covered by REACT fee mechanism |

> **Note:** Ensure your ReactOracleHub contract has sufficient REACT balance for callbacks.
