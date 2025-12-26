# 🏦 Cross-Chain Lending Automation Vault

## Overview

The **Lending Automation Vault** is a cross-chain automated yield optimization system built on **Reactive Network**. It monitors lending pool rates and automatically rebalances funds between pools to maximize yield.

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                           SEPOLIA (Destination)                              │
│                                                                              │
│  ┌────────────┐         ┌─────────────────┐         ┌────────────┐          │
│  │   User     │ deposit │  LendingVault   │ supply  │  Pool A    │          │
│  │            ├────────►│                 ├────────►│ (3% APY)   │          │
│  └────────────┘         │ • Holds shares  │         └────────────┘          │
│                         │ • Tracks alloc  │                                  │
│                         │ • Rebalances    │         ┌────────────┐          │
│                         │                 ├────────►│  Pool B    │          │
│                         └────────▲────────┘ supply  │ (5% APY)   │          │
│                                  │                  └─────┬──────┘          │
│                                  │ rebalance()            │                  │
│                                  │ (callback)             │ emit             │
└──────────────────────────────────┼────────────────────────┼──────────────────┘
                                   │                        │ PoolRateUpdated
                          Reactive Callback                 │
                                   │                        │
┌──────────────────────────────────┼────────────────────────┼──────────────────┐
│                         REACTIVE NETWORK (Lasna)          │                  │
│                                  │                        │                  │
│  ┌───────────────────────────────┴────────────────────────┴─────────┐       │
│  │                    LendingRebalancer (ReactVM)                   │       │
│  │  • Subscribes to PoolRateUpdated events from both pools          │       │
│  │  • Compares yields: if |rateA - rateB| > 2% → rebalance          │       │
│  │  • Emits Callback → triggers LendingVault.rebalance()            │       │
│  └──────────────────────────────────────────────────────────────────┘       │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Contracts

### LendingVault (Sepolia)
Main vault where users deposit funds.

| Function | Description |
|----------|-------------|
| `deposit(amount)` | Deposit tokens, receive shares |
| `withdraw(shares)` | Burn shares, receive tokens |
| `rebalance(...)` | Move funds between pools (Reactive only) |
| `getTotalAssets()` | Total value locked |
| `getSharePrice()` | Current share price |

### LendingRebalancer (Lasna)
Reactive contract that monitors rates and triggers rebalancing.

| Function | Description |
|----------|-------------|
| `react(log)` | Processes rate update events |
| `getRates()` | Returns current rates for both pools |
| `getRateDifferential()` | Returns rate difference in basis points |
| `setConfig(...)` | Configure threshold, interval |

### MockLendingPool (Sepolia)
Simulated lending pool with configurable rates.

| Function | Description |
|----------|-------------|
| `deposit(asset, amount)` | Deposit tokens |
| `withdraw(asset, amount)` | Withdraw tokens |
| `setSupplyRate(asset, rate)` | Set APY (owner only) |
| `getSupplyRate(asset)` | Get current APY |

---

## Rebalancing Logic

```
1. Pool A has 3% APY, Pool B has 5% APY
2. Rate differential = (5-3)/3 = 66% > 2% threshold
3. LendingRebalancer detects this via PoolRateUpdated events
4. Emits Callback to LendingVault with direction=A→B
5. LendingVault withdraws from Pool A, deposits to Pool B
6. User's funds now earn higher yield automatically
```

---

## Deployment

### Step 1: Deploy to Sepolia
```bash
./dev-scripts/deploy_vault.sh
```

This deploys:
- MockUSDC token (test token)
- Pool Alpha (MockLendingPool)
- Pool Beta (MockLendingPool)  
- LendingVault

### Step 2: Deploy to Lasna
```bash
# First, set addresses in .env from Step 1
export POOL_A_ADDRESS=0x...
export POOL_B_ADDRESS=0x...
export VAULT_ADDRESS=0x...

./dev-scripts/deploy_rebalancer.sh
```

### Step 3: Fund Rebalancer
```bash
cast send <REBALANCER_ADDRESS> --value 5ether \
  --rpc-url https://lasna-rpc.rnk.dev/ \
  --private-key $REACTIVE_PRIVATE_KEY --legacy
```

### Step 4: Authorize ReactVM
```bash
cast send <VAULT_ADDRESS> 'setAuthorizedReactVM(address)' <DEPLOYER_ADDRESS> \
  --rpc-url $SEPOLIA_RPC \
  --private-key $SEPOLIA_PRIVATE_KEY
```

---

## Testing

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vv

# Run specific test file
forge test --match-path test/LendingVault.t.sol
```

**Test Coverage:**
- `LendingVault.t.sol` - 14 tests
- `MockLendingPool.t.sol` - 9 tests
- `LendingRebalancer.t.sol` - 8 tests

---

## Demo Flow

1. **User deposits 1000 USDC** into LendingVault
2. **Vault allocates** to Pool A (default)
3. **Pool B rate increases** to 8% (changed by owner)
4. **LendingRebalancer detects** rate differential > 2%
5. **Emits Callback** to LendingVault
6. **Vault rebalances** from Pool A to Pool B
7. **User earns higher yield** automatically

---

## Bounty Requirements Checklist

- [x] ✅ Integrate with at least two lending pools (Pool A, Pool B)
- [x] ✅ Use Reactive Smart Contracts to listen to events (PoolRateUpdated)
- [x] ✅ Trigger rebalancing based on configurable condition (2% threshold)
- [x] ✅ Single vault interface for users (deposit/withdraw)
- [x] ✅ Automatic allocation based on strategy
