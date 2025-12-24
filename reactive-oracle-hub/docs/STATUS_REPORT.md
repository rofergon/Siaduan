# Cross-Chain Lending Vault - Status Report

**Date**: December 23, 2025  
**Project**: reactive-oracle-hub  
**Bounty**: Cross-Chain Lending Automation (2,000 USD in REACT)

---

## Current Status: ✅ DEPLOYED - CONFIGURATION PENDING

Bug **ReactVM Stateless** solucionado mediante patrón RateCoordinator.
Contratos desplegados. Configuración final requerida manualmente.

---

## Deployed Contracts

### Sepolia (Chain ID: 11155111)

| Contract | Address |
|----------|---------|
| **LendingVault** | `0xa968EEB8d2897464E41De673D79f1e289A3B0b7d` |
| **RateCoordinator** | `0x8d8159e74eE9c987925a2B5b21Cc6D6970513648` |
| **MockLendingPool A** | `0x242f6bcCA3208ff2b81F57Af6B9DC281bf1EabF4` |
| **MockLendingPool B** | `0x7952AD383bC3B3443E36d58eC585C49824E4e489` |

### Lasna/Reactive (Chain ID: 5318007)

| Contract | Address |
|----------|---------|
| **LendingRebalancer** | `0x8e5e742779cee74cba58eda528e38a5a145a3b17` |

---

## Pending Configuration (Manual Steps)

Debido a problemas leyendo `.env` en el entorno híbrido, ejecuta estos comandos en tu terminal WSL:

```bash
# Variables
export RATE_COORDINATOR=0x8d8159e74eE9c987925a2B5b21Cc6D6970513648
export LENDING_REBALANCER=0x8e5e742779cee74cba58eda528e38a5a145a3b17
export LENDING_VAULT=0xa968EEB8d2897464E41De673D79f1e289A3B0b7d
export MY_WALLET=0xaB6E247B25463F76E81aBAbBb6b0b86B40d45D38

# Cargar claves
source .env

# 1. Suscribir Rebalancer (Lasna)
~/.foundry/bin/cast send $LENDING_REBALANCER "subscribeToCoordinator()" \
  --rpc-url https://lasna-rpc.rnk.dev/ \
  --private-key $PRIVATE_KEY --legacy

# 2. Autorizar tu Wallet en el Vault (Sepolia)
# (Autorizamos tu wallet porque el script original lo hacía así para testing)
~/.foundry/bin/cast send $LENDING_VAULT "setAuthorizedReactVM(address)" $MY_WALLET \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# 3. Test Rebalance (Sepolia)
~/.foundry/bin/cast send $RATE_COORDINATOR "reportRates(uint256,uint256)" 300 800 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

> **Nota**: Espera 2-3 minutos después del paso 3 para ver el rebalance en el Vault.

---

## Files Modified during Fix

1. **`src/reactive/LendingRebalancer.sol`** - Refactored to use RateCoordinator
2. **`script/DeployRateCoordinator.s.sol`** - NEW: Deploy script
3. **`script/DeployLendingRebalancer.s.sol`** - Updated for new constructor
4. **`test/LendingRebalancer.t.sol`** - Updated tests (9/9 pass)

---

## Wallet

- **Address**: `0xaB6E247B25463F76E81aBAbBb6b0b86B40d45D38`
- **Balance**: Sufficient
