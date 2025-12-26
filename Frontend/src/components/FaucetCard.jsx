import { useState } from 'react';
import { Contract, parseUnits } from 'ethers';
import { ADDRESSES } from '../contracts/addresses';
import { MockERC20ABI } from '../contracts/abis';
import { Droplets, Loader2 } from 'lucide-react';
import toast from 'react-hot-toast';

export function FaucetCard({ signer, usdcBalance, refreshData }) {
    const [amount, setAmount] = useState('1000');
    const [loading, setLoading] = useState(false);

    const handleMint = async () => {
        if (!signer) return toast.error('Wallet not connected');

        setLoading(true);
        try {
            const usdc = new Contract(ADDRESSES.MOCK_USDC, MockERC20ABI, signer);
            const val = parseUnits(amount, 6);

            const tx = await usdc.mint(val);
            toast.loading('Minting tokens...', { id: 'mint' });
            await tx.wait();

            toast.success('Tokens minted successfully!', { id: 'mint' });
            await refreshData();
            setAmount('');
        } catch (error) {
            console.error('Mint failed:', error);
            toast.error('Mint failed: ' + (error.reason || error.message), { id: 'mint' });
        } finally {
            setLoading(false);
        }
    };

    return (
        <section className="card glass-panel">
            <div className="card-header">
                <Droplets className="icon" />
                <h2>Token Faucet</h2>
            </div>

            <div className="card-content">
                <div className="balance-display">
                    <span className="label">Your Balance</span>
                    <span className="value">{parseFloat(usdcBalance).toLocaleString()} <small>mUSDC</small></span>
                </div>

                <div className="input-with-action">
                    <input
                        type="number"
                        value={amount}
                        onChange={(e) => setAmount(e.target.value)}
                        placeholder="Amount to mint"
                        disabled={loading}
                    />
                    <button
                        className="btn btn-primary"
                        onClick={handleMint}
                        disabled={loading || !amount}
                    >
                        {loading ? <Loader2 className="spin" size={20} /> : 'Mint'}
                    </button>
                </div>
            </div>
        </section>
    );
}
