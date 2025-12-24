import { useState, useEffect, useCallback } from 'react';
import { BrowserProvider, Contract, formatUnits, parseUnits, MaxUint256 } from 'ethers';
import { useAppKit, useAppKitAccount, useAppKitProvider, useAppKitNetwork } from '@reown/appkit/react';
import { ADDRESSES, CHAIN_CONFIG } from './contracts/addresses';
import { MockERC20ABI, LendingVaultABI, RateCoordinatorABI } from './contracts/abis';
import './App.css';

function App() {
  // AppKit hooks for wallet connection
  const { open } = useAppKit();
  const { address, isConnected } = useAppKitAccount();
  const { walletProvider } = useAppKitProvider('eip155');
  const { chainId } = useAppKitNetwork();

  // Provider and signer derived from AppKit
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);

  // Balances and protocol state
  const [usdcBalance, setUsdcBalance] = useState('0');
  const [shares, setShares] = useState('0');
  const [sharePrice, setSharePrice] = useState('0');
  const [allocations, setAllocations] = useState({ allocA: '0', allocB: '0', idle: '0' });
  const [currentRates, setCurrentRates] = useState({ rateA: '0', rateB: '0' });

  // Form inputs
  const [mintAmount, setMintAmount] = useState('1000');
  const [depositAmount, setDepositAmount] = useState('100');
  const [withdrawShares, setWithdrawShares] = useState('50');
  const [rateA, setRateA] = useState('300');
  const [rateB, setRateB] = useState('800');

  // Loading states
  const [loading, setLoading] = useState({});

  // Setup provider and signer when wallet connects
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
        }
      } else {
        setProvider(null);
        setSigner(null);
      }
    };
    setupProvider();
  }, [isConnected, walletProvider]);

  // Refresh data
  const refreshData = useCallback(async () => {
    if (!provider || !address) return;

    try {
      // USDC Balance
      const usdc = new Contract(ADDRESSES.MOCK_USDC, MockERC20ABI, provider);
      const balance = await usdc.balanceOf(address);
      setUsdcBalance(formatUnits(balance, 6));

      // Vault data
      const vault = new Contract(ADDRESSES.LENDING_VAULT, LendingVaultABI, provider);
      const userShares = await vault.shares(address);
      const price = await vault.getSharePrice();
      const allocs = await vault.getAllocations();

      setShares(formatUnits(userShares, 6));
      setSharePrice(formatUnits(price, 18));
      setAllocations({
        allocA: formatUnits(allocs[0], 6),
        allocB: formatUnits(allocs[1], 6),
        idle: formatUnits(allocs[2], 6),
      });

      // Coordinator rates
      const coordinator = new Contract(ADDRESSES.RATE_COORDINATOR, RateCoordinatorABI, provider);
      const rA = await coordinator.rateA();
      const rB = await coordinator.rateB();
      setCurrentRates({ rateA: rA.toString(), rateB: rB.toString() });
    } catch (error) {
      console.error('Failed to refresh data:', error);
    }
  }, [provider, address]);

  useEffect(() => {
    if (provider && address) {
      refreshData();
      const interval = setInterval(refreshData, 10000);
      return () => clearInterval(interval);
    }
  }, [provider, address, refreshData]);

  // Mint tokens
  const handleMint = async () => {
    if (!signer) return;
    setLoading(prev => ({ ...prev, mint: true }));
    try {
      const usdc = new Contract(ADDRESSES.MOCK_USDC, MockERC20ABI, signer);
      const amount = parseUnits(mintAmount, 6);
      const tx = await usdc.mint(amount);
      await tx.wait();
      await refreshData();
    } catch (error) {
      console.error('Mint failed:', error);
      alert('Mint failed: ' + error.message);
    }
    setLoading(prev => ({ ...prev, mint: false }));
  };

  // Deposit to vault
  const handleDeposit = async () => {
    if (!signer) return;
    setLoading(prev => ({ ...prev, deposit: true }));
    try {
      const usdc = new Contract(ADDRESSES.MOCK_USDC, MockERC20ABI, signer);
      const vault = new Contract(ADDRESSES.LENDING_VAULT, LendingVaultABI, signer);
      const amount = parseUnits(depositAmount, 6);

      // Check and approve
      const allowance = await usdc.allowance(address, ADDRESSES.LENDING_VAULT);
      if (allowance < amount) {
        const approveTx = await usdc.approve(ADDRESSES.LENDING_VAULT, MaxUint256);
        await approveTx.wait();
      }

      const tx = await vault.deposit(amount);
      await tx.wait();
      await refreshData();
    } catch (error) {
      console.error('Deposit failed:', error);
      alert('Deposit failed: ' + error.message);
    }
    setLoading(prev => ({ ...prev, deposit: false }));
  };

  // Withdraw from vault
  const handleWithdraw = async () => {
    if (!signer) return;
    setLoading(prev => ({ ...prev, withdraw: true }));
    try {
      const vault = new Contract(ADDRESSES.LENDING_VAULT, LendingVaultABI, signer);
      const amount = parseUnits(withdrawShares, 6);
      const tx = await vault.withdraw(amount);
      await tx.wait();
      await refreshData();
    } catch (error) {
      console.error('Withdraw failed:', error);
      alert('Withdraw failed: ' + error.message);
    }
    setLoading(prev => ({ ...prev, withdraw: false }));
  };

  // Update rates
  const handleUpdateRates = async () => {
    if (!signer) return;
    setLoading(prev => ({ ...prev, rates: true }));
    try {
      const coordinator = new Contract(ADDRESSES.RATE_COORDINATOR, RateCoordinatorABI, signer);
      const tx = await coordinator.reportRates(rateA, rateB);
      await tx.wait();
      await refreshData();
      alert('Rates updated! Reactive Network will detect and trigger rebalance if needed.');
    } catch (error) {
      console.error('Rate update failed:', error);
      alert('Rate update failed: ' + error.message);
    }
    setLoading(prev => ({ ...prev, rates: false }));
  };

  const isWrongNetwork = chainId && chainId !== CHAIN_CONFIG.chainId;

  return (
    <div className="app">
      <header className="header">
        <h1>🏦 Siaduan Protocol</h1>
        <p className="subtitle">Cross-Chain Lending Vault powered by Reactive Network</p>
      </header>

      {/* Wallet Section */}
      <section className="card wallet-card">
        <h2>🔗 Wallet</h2>
        {!isConnected ? (
          <button className="btn btn-primary" onClick={() => open()}>
            Connect Wallet
          </button>
        ) : (
          <div className="wallet-info">
            <p><strong>Address:</strong> {address?.slice(0, 6)}...{address?.slice(-4)}</p>
            <p><strong>Network:</strong> {isWrongNetwork ? '❌ Wrong Network' : '✅ Sepolia'}</p>
            {isWrongNetwork && (
              <p className="warning">Please switch to Sepolia testnet</p>
            )}
            <button className="btn btn-secondary" onClick={() => open({ view: 'Account' })}>
              Manage Wallet
            </button>
          </div>
        )}
      </section>

      {isConnected && !isWrongNetwork && (
        <>
          {/* Token Faucet */}
          <section className="card">
            <h2>🚰 Token Faucet</h2>
            <p className="balance">Your mUSDC Balance: <strong>{parseFloat(usdcBalance).toLocaleString()}</strong></p>
            <div className="input-group">
              <input
                type="number"
                value={mintAmount}
                onChange={(e) => setMintAmount(e.target.value)}
                placeholder="Amount to mint"
              />
              <button
                className="btn btn-success"
                onClick={handleMint}
                disabled={loading.mint}
              >
                {loading.mint ? 'Minting...' : 'Mint mUSDC'}
              </button>
            </div>
          </section>

          {/* Rate Control */}
          <section className="card rate-control">
            <h2>📊 Rate Control</h2>
            <p className="current-rates">
              Current Rates: Pool A = <strong>{currentRates.rateA} bps</strong> | Pool B = <strong>{currentRates.rateB} bps</strong>
            </p>
            <div className="rate-inputs">
              <div className="rate-input">
                <label>Pool A Rate (bps)</label>
                <input
                  type="range"
                  min="0"
                  max="2000"
                  value={rateA}
                  onChange={(e) => setRateA(e.target.value)}
                />
                <span className="rate-value">{rateA} bps ({(rateA / 100).toFixed(2)}%)</span>
              </div>
              <div className="rate-input">
                <label>Pool B Rate (bps)</label>
                <input
                  type="range"
                  min="0"
                  max="2000"
                  value={rateB}
                  onChange={(e) => setRateB(e.target.value)}
                />
                <span className="rate-value">{rateB} bps ({(rateB / 100).toFixed(2)}%)</span>
              </div>
            </div>
            <button
              className="btn btn-warning"
              onClick={handleUpdateRates}
              disabled={loading.rates}
            >
              {loading.rates ? 'Updating...' : '⚡ Update Rates (Triggers Reactive)'}
            </button>
          </section>

          {/* Vault Interface */}
          <section className="card vault-section">
            <h2>🏛️ Lending Vault</h2>
            <div className="vault-stats">
              <div className="stat">
                <span className="label">Your Shares</span>
                <span className="value">{parseFloat(shares).toLocaleString()}</span>
              </div>
              <div className="stat">
                <span className="label">Share Price</span>
                <span className="value">{parseFloat(sharePrice).toFixed(4)}</span>
              </div>
            </div>
            <div className="vault-actions">
              <div className="action">
                <input
                  type="number"
                  value={depositAmount}
                  onChange={(e) => setDepositAmount(e.target.value)}
                  placeholder="Deposit amount"
                />
                <button
                  className="btn btn-success"
                  onClick={handleDeposit}
                  disabled={loading.deposit}
                >
                  {loading.deposit ? 'Depositing...' : 'Deposit'}
                </button>
              </div>
              <div className="action">
                <input
                  type="number"
                  value={withdrawShares}
                  onChange={(e) => setWithdrawShares(e.target.value)}
                  placeholder="Shares to withdraw"
                />
                <button
                  className="btn btn-danger"
                  onClick={handleWithdraw}
                  disabled={loading.withdraw}
                >
                  {loading.withdraw ? 'Withdrawing...' : 'Withdraw'}
                </button>
              </div>
            </div>
          </section>

          {/* Protocol Status */}
          <section className="card status-section">
            <h2>📈 Protocol Status</h2>
            <div className="allocations">
              <div className="allocation pool-a">
                <h3>Pool A</h3>
                <p className="amount">{parseFloat(allocations.allocA).toLocaleString()} mUSDC</p>
                <p className="rate">{currentRates.rateA} bps</p>
              </div>
              <div className="allocation pool-b">
                <h3>Pool B</h3>
                <p className="amount">{parseFloat(allocations.allocB).toLocaleString()} mUSDC</p>
                <p className="rate">{currentRates.rateB} bps</p>
              </div>
              <div className="allocation idle">
                <h3>Idle</h3>
                <p className="amount">{parseFloat(allocations.idle).toLocaleString()} mUSDC</p>
              </div>
            </div>
          </section>
        </>
      )}

      <footer className="footer">
        <p>Powered by <strong>Reactive Network</strong> | Built for the Cross-Chain Lending Bounty</p>
      </footer>
    </div>
  );
}

export default App;
