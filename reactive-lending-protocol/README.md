# Siaduan Protocol

> **Cross-Chain Automated Lending Vault with Reactive Rebalancing**

Siaduan Protocol is a DeFi lending vault that automatically rebalances funds between lending pools to optimize yield. It uses [Reactive Network](https://reactive.network/) for cross-chain event monitoring and automated callbacks.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        SEPOLIA CHAIN                            │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │   Pool A     │◄───│ LendingVault │───►│   Pool B     │       │
│  │  (3% APY)    │    │              │    │  (8% APY)    │       │
│  └──────────────┘    └──────┬───────┘    └──────────────┘       │
│                             │                                   │
│                    ┌────────▼────────┐                          │
│                    │ RateCoordinator │ ───► Emits RatesUpdated  │
│                    └─────────────────┘                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                    Events monitored by
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    REACTIVE NETWORK (LASNA)                     │
│           ┌─────────────────────────────────────┐               │
│           │       LendingRebalancer             │               │
│           │  • Monitors RatesUpdated events     │               │
│           │  • Calculates optimal allocation    │               │
│           │  • Sends rebalance callbacks        │               │
│           └─────────────────────────────────────┘               │
└─────────────────────────────────────────────────────────────────┘
                              │
                    Callback via Proxy
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        SEPOLIA CHAIN                            │
│     Callback Proxy ──► LendingVault.rebalance() executed        │
│     Funds automatically moved to higher-yield pool              │
└─────────────────────────────────────────────────────────────────┘
```

## 📋 Deployed Contracts

### Sepolia Testnet (Chain ID: 11155111)

| Contract | Address | Description |
|----------|---------|-------------|
| **LendingVault** | `0xf8Af4B57A22328Af51448A43eEF1bbdE8542852D` | Main vault that holds user deposits |
| **RateCoordinator** | `0x8d8159e74eE9c987925a2B5b21Cc6D6970513648` | Aggregates and reports pool rates |
| **MockUSDC** | `0xf044c58496693C106a7EaE5460d39c1E99ABE074` | Test token for deposits |
| **Pool A** | `0x242f6bcCA3208ff2b81F57Af6B9DC281bf1EabF4` | Mock lending pool (lower rate) |
| **Pool B** | `0x7952AD383bC3B3443E36d58eC585C49824E4e489` | Mock lending pool (higher rate) |
| **Callback Proxy** | `0xc9f36411C9897e7F959D99ffca2a0Ba7ee0D7bDA` | Reactive Network callback receiver |

### Lasna (Reactive Network Testnet, Chain ID: 5318007)

| Contract | Address | Description |
|----------|---------|-------------|
| **LendingRebalancer** | `0x8cC046205284913b2844995fB01281E2945DF76f` | Monitors events & triggers rebalances |

## 🔄 How It Works

### 1. Deposit Funds
Users deposit USDC into the LendingVault. Funds are automatically allocated to Pool A by default.

### 2. Rate Monitoring
The RateCoordinator tracks supply rates from both lending pools and emits `RatesUpdated` events when rates change.

### 3. Reactive Detection
The LendingRebalancer on Reactive Network monitors these events. When it detects a significant rate differential (>2%), it triggers a rebalance.

### 4. Automatic Rebalancing
The rebalancer sends a callback to Sepolia, instructing the LendingVault to move funds from the lower-yield pool to the higher-yield pool.

## 🚀 Quick Start

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Sepolia testnet ETH
- REACT tokens (Reactive Network testnet)

### 1. Clone & Install
```bash
git clone https://github.com/your-repo/siaduan-protocol
cd siaduan-protocol
forge install
```

### 2. Set Environment
```bash
cp .env.example .env
# Edit .env with your PRIVATE_KEY
```

### 3. Get Test Tokens

**Mint MockUSDC:**
```bash
cast send 0xf044c58496693C106a7EaE5460d39c1E99ABE074 \
  "mint(uint256)" 10000000000 \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
  --private-key $PRIVATE_KEY
```

### 4. Deposit to Vault
```bash
# Approve
cast send 0xf044c58496693C106a7EaE5460d39c1E99ABE074 \
  "approve(address,uint256)" 0xf8Af4B57A22328Af51448A43eEF1bbdE8542852D 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
  --private-key $PRIVATE_KEY

# Deposit
cast send 0xf8Af4B57A22328Af51448A43eEF1bbdE8542852D \
  "deposit(uint256)" 1000000000 \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
  --private-key $PRIVATE_KEY
```

### 5. Trigger Rate Update (for testing)
```bash
cast send 0x8d8159e74eE9c987925a2B5b21Cc6D6970513648 \
  "reportRates(uint256,uint256)" 300 1200 \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
  --private-key $PRIVATE_KEY
```

### 6. Check Allocations
```bash
cast call 0xf8Af4B57A22328Af51448A43eEF1bbdE8542852D \
  "getAllocations()" \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com
```

## 📊 Monitoring

### Reactscan (Reactive Network Explorer)
Monitor the LendingRebalancer transactions:
- [View on Reactscan](https://lasna.reactscan.net/address/0x8cC046205284913b2844995fB01281E2945DF76f)

### Etherscan (Sepolia)
- [LendingVault](https://sepolia.etherscan.io/address/0xf8Af4B57A22328Af51448A43eEF1bbdE8542852D)
- [RateCoordinator](https://sepolia.etherscan.io/address/0x8d8159e74eE9c987925a2B5b21Cc6D6970513648)

## ⚙️ Configuration

### Rebalance Parameters
The LendingRebalancer uses these default parameters:

| Parameter | Value | Description |
|-----------|-------|-------------|
| `rebalanceThreshold` | 200 (2%) | Minimum rate differential to trigger rebalance |
| `minRebalanceInterval` | 60 seconds | Cooldown between rebalances |
| `rebalancePercentage` | 5000 (50%) | Percentage of funds to move |

### Callback Payment
The vault must have ETH deposited via the Callback Proxy to pay for callbacks:
```bash
cast send 0xc9f36411C9897e7F959D99ffca2a0Ba7ee0D7bDA \
  "depositTo(address)" 0xf8Af4B57A22328Af51448A43eEF1bbdE8542852D \
  --value 0.05ether \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
  --private-key $PRIVATE_KEY
```

## 🔐 Security Considerations

- **authorizedReactVM**: Only the deployer's address can trigger rebalance callbacks
- **Ownable**: Admin functions are restricted to contract owner
- **ReentrancyGuard**: Protects against reentrancy attacks on deposit/withdraw

## 📁 Project Structure

```
siaduan-protocol/
├── src/
│   ├── destination/
│   │   ├── LendingVault.sol      # Main vault contract
│   │   ├── RateCoordinator.sol   # Rate aggregator
│   │   └── adapters/
│   │       └── MockLendingPool.sol
│   ├── reactive/
│   │   └── LendingRebalancer.sol # Reactive contract
│   └── mocks/
│       └── MockERC20.sol
├── script/
│   ├── DeployLendingVault.s.sol
│   └── RedeployLendingRebalancer.s.sol
└── Frontend/
    └── src/
        └── contracts/addresses.js
```

## 🔗 Links

- [Reactive Network Documentation](https://dev.reactive.network/)
- [Reactscan Explorer](https://lasna.reactscan.net/)
- [Sepolia Faucet](https://sepoliafaucet.com/)

## 📄 License

MIT License
