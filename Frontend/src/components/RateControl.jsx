import { useState, useEffect } from 'react';
import { Contract } from 'ethers';
import { ADDRESSES } from '../contracts/addresses';
import { RateCoordinatorABI } from '../contracts/abis';
import { Settings, Zap, Loader2 } from 'lucide-react';
import toast from 'react-hot-toast';

export function RateControl({ signer, currentRates, refreshData }) {
    const [rateA, setRateA] = useState('300');
    const [rateB, setRateB] = useState('800');
    const [loading, setLoading] = useState(false);

    // Sync with current rates on load (optional, but good UX)
    // But usually users want to set NEW rates, so maybe default is fine.
    // Let's keep separate state for "proposed" rates vs "current" rates.

    const handleUpdate = async () => {
        if (!signer) return toast.error('Wallet not connected');

        setLoading(true);
        try {
            const coordinator = new Contract(ADDRESSES.RATE_COORDINATOR, RateCoordinatorABI, signer);

            const tx = await coordinator.reportRates(rateA, rateB);
            toast.loading('Updating rates...', { id: 'rates' });
            await tx.wait();

            toast.success('Rates updated! Reactive Network notified.', { id: 'rates' });
            await refreshData();
        } catch (error) {
            console.error('Rate update failed:', error);
            toast.error('Update failed: ' + (error.reason || error.message), { id: 'rates' });
        } finally {
            setLoading(false);
        }
    };

    return (
        <section className="card rate-control glass-panel">
            <div className="card-header">
                <Settings className="icon" />
                <h2>Rate Control</h2>
            </div>

            <div className="current-rates-display">
                <div className="rate-item">
                    <span className="label">Pool A Current</span>
                    <span className="val">{currentRates.rateA} bps</span>
                </div>
                <div className="rate-item">
                    <span className="label">Pool B Current</span>
                    <span className="val">{currentRates.rateB} bps</span>
                </div>
            </div>

            <div className="sliders-container">
                <div className="slider-group">
                    <div className="slider-header">
                        <label>Set Pool A Rate</label>
                        <span className="badge">{rateA} bps ({(rateA / 100).toFixed(2)}%)</span>
                    </div>
                    <input
                        type="range"
                        min="0" max="2000"
                        value={rateA}
                        onChange={e => setRateA(e.target.value)}
                    />
                </div>

                <div className="slider-group">
                    <div className="slider-header">
                        <label>Set Pool B Rate</label>
                        <span className="badge">{rateB} bps ({(rateB / 100).toFixed(2)}%)</span>
                    </div>
                    <input
                        type="range"
                        min="0" max="2000"
                        value={rateB}
                        onChange={e => setRateB(e.target.value)}
                    />
                </div>
            </div>

            <button
                className="btn btn-accent full-width"
                onClick={handleUpdate}
                disabled={loading}
            >
                {loading ? (
                    <><Loader2 className="spin" /> Updating...</>
                ) : (
                    <><Zap size={18} /> Update Rates & Trigger Rebalance</>
                )}
            </button>

        </section>
    );
}
