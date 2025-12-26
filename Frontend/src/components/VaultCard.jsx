import { useState } from 'react';
import { Contract, parseUnits, MaxUint256 } from 'ethers';
import { ADDRESSES } from '../contracts/addresses';
import { LendingVaultABI, MockERC20ABI } from '../contracts/abis';
import { Landmark, ArrowRightLeft, Loader2, Wallet } from 'lucide-react';
import toast from 'react-hot-toast';

export function VaultCard({ signer, address, shares, sharePrice, usdcBalance, refreshData }) {
    const [activeTab, setActiveTab] = useState('deposit');
    const [amount, setAmount] = useState('');
    const [loading, setLoading] = useState(false);

    const handleAction = async () => {
        if (!signer) return toast.error('Wallet not connected');
        if (!amount || parseFloat(amount) <= 0) return toast.error('Invalid amount');

        setLoading(true);
        const toastId = activeTab === 'deposit' ? 'deposit' : 'withdraw';

        try {
            const vault = new Contract(ADDRESSES.LENDING_VAULT, LendingVaultABI, signer);
            const val = parseUnits(amount, 6);

            if (activeTab === 'deposit') {
                const usdc = new Contract(ADDRESSES.MOCK_USDC, MockERC20ABI, signer);

                // Check allowance
                const allowance = await usdc.allowance(address, ADDRESSES.LENDING_VAULT);
                if (allowance < val) {
                    toast.loading('Approving USDC...', { id: toastId });
                    const appTx = await usdc.approve(ADDRESSES.LENDING_VAULT, MaxUint256);
                    await appTx.wait();
                }

                toast.loading('Depositing...', { id: toastId });
                const tx = await vault.deposit(val);
                await tx.wait();
                toast.success('Deposit successful!', { id: toastId });
            } else {
                toast.loading('Withdrawing...', { id: toastId });
                const tx = await vault.withdraw(val);
                await tx.wait();
                toast.success('Withdraw successful!', { id: toastId });
            }

            await refreshData();
            setAmount('');
        } catch (error) {
            console.error(activeTab + ' failed:', error);
            toast.error(activeTab.charAt(0).toUpperCase() + activeTab.slice(1) + ' failed: ' + (error.reason || error.message), { id: toastId });
        } finally {
            setLoading(false);
        }
    };

    const setMax = () => {
        if (activeTab === 'deposit') {
            setAmount(usdcBalance);
        } else {
            setAmount(shares);
        }
    };

    return (
        <section className="card vault-card glass-panel">
            <div className="card-header">
                <Landmark className="icon" />
                <h2>Lending Vault</h2>
            </div>

            <div className="vault-stats-grid">
                <div className="stat-box">
                    <span className="label">My Shares</span>
                    <span className="value">{parseFloat(shares).toLocaleString(undefined, { maximumFractionDigits: 4 })}</span>
                </div>
                <div className="stat-box">
                    <span className="label">Share Price</span>
                    <span className="value">{parseFloat(sharePrice).toFixed(4)} USDC</span>
                </div>
            </div>

            <div className="tabs">
                <button
                    className={`tab-btn ${activeTab === 'deposit' ? 'active' : ''}`}
                    onClick={() => setActiveTab('deposit')}
                >
                    Deposit
                </button>
                <button
                    className={`tab-btn ${activeTab === 'withdraw' ? 'active' : ''}`}
                    onClick={() => setActiveTab('withdraw')}
                >
                    Withdraw
                </button>
            </div>

            <div className="action-area">
                <div className="input-label-row">
                    <label>{activeTab === 'deposit' ? 'Amount to Deposit (USDC)' : 'Shares to Withdraw'}</label>
                    <button className="max-btn" onClick={setMax}>
                        Max: {activeTab === 'deposit' ? parseFloat(usdcBalance).toLocaleString() : parseFloat(shares).toLocaleString()}
                    </button>
                </div>

                <div className="input-wrapper">
                    <input
                        type="number"
                        value={amount}
                        onChange={(e) => setAmount(e.target.value)}
                        placeholder="0.00"
                        disabled={loading}
                    />
                </div>

                <button
                    className={`btn full-width ${activeTab === 'deposit' ? 'btn-success' : 'btn-danger'}`}
                    onClick={handleAction}
                    disabled={loading || !amount}
                >
                    {loading ? <Loader2 className="spin" /> : (
                        <>
                            {activeTab === 'deposit' ? 'Deposit' : 'Withdraw'} <ArrowRightLeft size={16} />
                        </>
                    )}
                </button>
            </div>
        </section>
    );
}
