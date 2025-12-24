// Stub for @base-org/account - this is an optional dependency for Coinbase Smart Wallet
// The feature will gracefully fail if this is not available

export const createBaseAccountSDK = async () => {
    throw new Error('Coinbase Smart Wallet SDK not available - install @base-org/account to enable')
}
