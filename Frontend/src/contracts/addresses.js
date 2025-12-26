// Contract addresses on Sepolia testnet (Updated Dec 26, 2025)
export const ADDRESSES = {
  MOCK_USDC: "0xf044c58496693C106a7EaE5460d39c1E99ABE074",
  LENDING_VAULT: "0xf8Af4B57A22328Af51448A43eEF1bbdE8542852D",
  RATE_COORDINATOR: "0x8d8159e74eE9c987925a2B5b21Cc6D6970513648",
  POOL_A: "0x242f6bcCA3208ff2b81F57Af6B9DC281bf1EabF4",
  POOL_B: "0x7952AD383bC3B3443E36d58eC585C49824E4e489",
};

// Reactive Network (Lasna) - LendingRebalancer listens to RateCoordinator events
export const REACTIVE_ADDRESSES = {
  LENDING_REBALANCER: "0x8cC046205284913b2844995fB01281E2945DF76f",
};

// Chain configuration
export const CHAIN_CONFIG = {
  chainId: 11155111,
  name: "Sepolia",
  rpcUrl: "https://ethereum-sepolia-rpc.publicnode.com",
  blockExplorer: "https://sepolia.etherscan.io",
};

// Reactive Network configuration
export const REACTIVE_CONFIG = {
  chainId: 5318007,
  name: "Lasna (Reactive Testnet)",
  rpcUrl: "https://lasna-rpc.rnk.dev/",
  reactscan: "https://lasna.reactscan.net",
};
