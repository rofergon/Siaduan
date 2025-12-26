import { useState, useCallback, useEffect } from 'react';
import { Contract, formatUnits, BrowserProvider } from 'ethers';
import { useAppKitAccount, useAppKitProvider } from '@reown/appkit/react';
import { ADDRESSES } from '../contracts/addresses';
import { MockERC20ABI, LendingVaultABI, RateCoordinatorABI } from '../contracts/abis';

export function useProtocolData() {
    const { address, isConnected } = useAppKitAccount();
    const { walletProvider } = useAppKitProvider('eip155');

    const [data, setData] = useState({
        usdcBalance: '0',
        shares: '0',
        sharePrice: '0',
        allocations: { allocA: '0', allocB: '0', idle: '0' },
        currentRates: { rateA: '0', rateB: '0' },
    });

    const [provider, setProvider] = useState(null);
    const [signer, setSigner] = useState(null);

    // Setup Provider and Signer
    useEffect(() => {
        const setupProvider = async () => {
            if (isConnected && walletProvider) {
                try {
                    const ethersProvider = new BrowserProvider(walletProvider);
                    const ethersSigner = await ethersProvider.getSigner();
                    setProvider(ethersProvider);
                    setSigner(ethersSigner);
                } catch (error) {
                    console.error('Failed to setup provider:', error);
                    setProvider(null);
                    setSigner(null);
                }
            } else {
                setProvider(null);
                setSigner(null);
            }
        };
        setupProvider();
    }, [isConnected, walletProvider]);

    const refreshData = useCallback(async () => {
        if (!provider || !address) return;

        try {
            // Contracts
            const usdc = new Contract(ADDRESSES.MOCK_USDC, MockERC20ABI, provider);
            const vault = new Contract(ADDRESSES.LENDING_VAULT, LendingVaultABI, provider);
            const coordinator = new Contract(ADDRESSES.RATE_COORDINATOR, RateCoordinatorABI, provider);

            // Fetch all data in parallel
            const [
                balance,
                userShares,
                price,
                allocs,
                rA,
                rB
            ] = await Promise.all([
                usdc.balanceOf(address),
                vault.shares(address),
                vault.getSharePrice(),
                vault.getAllocations(),
                coordinator.rateA(),
                coordinator.rateB()
            ]);

            setData({
                usdcBalance: formatUnits(balance, 6),
                shares: formatUnits(userShares, 6),
                sharePrice: formatUnits(price, 18),
                allocations: {
                    allocA: formatUnits(allocs[0], 6),
                    allocB: formatUnits(allocs[1], 6),
                    idle: formatUnits(allocs[2], 6),
                },
                currentRates: {
                    rateA: rA.toString(),
                    rateB: rB.toString()
                },
            });

        } catch (error) {
            console.error('Failed to refresh data:', error);
        }
    }, [provider, address]);

    // Auto-refresh
    useEffect(() => {
        if (provider && address) {
            refreshData();
            const interval = setInterval(refreshData, 10000);
            return () => clearInterval(interval);
        }
    }, [provider, address, refreshData]);

    return {
        ...data,
        provider,
        signer,
        refreshData,
        isConnected,
        address
    };
}
