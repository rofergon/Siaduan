import { REACTIVE_ADDRESSES, REACTIVE_CONFIG } from '../contracts/addresses';
import { PieChart, Activity, ExternalLink } from 'lucide-react';

export function ProtocolStatus({ allocations, currentRates }) {
    return (
        <section className="card status-card glass-panel">
            <div className="card-header">
                <PieChart className="icon" />
                <h2>Protocol Status</h2>
            </div>

            <div className="allocations-grid">
                <div className="alloc-card pool-a">
                    <h3>Pool A</h3>
                    <div className="alloc-stats">
                        <span className="big-num">{parseFloat(allocations.allocA).toLocaleString()}</span>
                        <span className="currency">mUSDC</span>
                    </div>
                    <div className="rate-badge">{currentRates.rateA} bps</div>
                </div>

                <div className="alloc-card pool-b">
                    <h3>Pool B</h3>
                    <div className="alloc-stats">
                        <span className="big-num">{parseFloat(allocations.allocB).toLocaleString()}</span>
                        <span className="currency">mUSDC</span>
                    </div>
                    <div className="rate-badge">{currentRates.rateB} bps</div>
                </div>

                <div className="alloc-card idle">
                    <h3>Idle Funds</h3>
                    <div className="alloc-stats">
                        <span className="big-num">{parseFloat(allocations.idle).toLocaleString()}</span>
                        <span className="currency">mUSDC</span>
                    </div>
                    <span className="status-label">Buffer</span>
                </div>
            </div>

            <div className="reactive-network-info">
                <div className="rn-header">
                    <Activity size={18} className="rn-icon" />
                    <span>Reactive Network</span>
                </div>

                <div className="address-box">
                    <span className="label">Lending Rebalancer</span>
                    <code className="address">
                        {REACTIVE_ADDRESSES.LENDING_REBALANCER.slice(0, 10)}...{REACTIVE_ADDRESSES.LENDING_REBALANCER.slice(-8)}
                    </code>
                </div>

                <a
                    href={`${REACTIVE_CONFIG.reactscan}/address/0xab6e247b25463f76e81ababbb6b0b86b40d45d38/contract/${REACTIVE_ADDRESSES.LENDING_REBALANCER}?screen=transactions`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="btn btn-secondary full-width"
                >
                    View on Reactscan <ExternalLink size={14} />
                </a>
            </div>
        </section>
    );
}
