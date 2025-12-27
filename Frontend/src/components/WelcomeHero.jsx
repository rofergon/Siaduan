import { useAppKit } from '@reown/appkit/react';
import './welcomeHero.css';

export function WelcomeHero({ onLearnMore }) {
    const { open } = useAppKit();

    const handleConnectWallet = () => {
        open();
    };

    return (
        <div className="welcome-hero">
            {/* Animated Background */}
            <div className="hero-background">
                <div className="glow-orb orb-1"></div>
                <div className="glow-orb orb-2"></div>
                <div className="glow-orb orb-3"></div>
            </div>

            {/* Main Hero Content */}
            <section className="hero-main">
                <div className="hero-badge">
                    <span className="badge-icon">🌐</span>
                    <span>Powered by Reactive Network</span>
                </div>

                <h1 className="hero-title">
                    <span className="title-line">Maximize Your</span>
                    <span className="title-gradient">DeFi Yields</span>
                    <span className="title-line">Automatically</span>
                </h1>

                <p className="hero-description">
                    A cross-chain lending vault that monitors rates across multiple pools
                    and automatically rebalances your funds to the highest-yield opportunities.
                </p>

                <div className="hero-cta">
                    <button className="cta-primary" onClick={handleConnectWallet}>
                        <span className="cta-icon">🔗</span>
                        Connect Wallet
                    </button>
                    <button className="cta-secondary" onClick={onLearnMore}>
                        <span className="cta-icon">📖</span>
                        Learn More
                    </button>
                </div>
            </section>

            {/* Feature Cards */}
            <section className="features-section">
                <div className="feature-card float-1">
                    <div className="feature-icon-wrap">
                        <span className="feature-icon">⚡</span>
                    </div>
                    <h3>Auto-Optimize</h3>
                    <p>Funds automatically move to the highest-yield pool without manual intervention.</p>
                </div>

                <div className="feature-card float-2">
                    <div className="feature-icon-wrap">
                        <span className="feature-icon">🔗</span>
                    </div>
                    <h3>Cross-Chain</h3>
                    <p>Monitor and rebalance across multiple chains through Reactive Network callbacks.</p>
                </div>

                <div className="feature-card float-3">
                    <div className="feature-icon-wrap">
                        <span className="feature-icon">🛡️</span>
                    </div>
                    <h3>Decentralized</h3>
                    <p>Fully on-chain execution. No centralized servers, keepers, or manual triggers.</p>
                </div>
            </section>

            {/* Protocol Flow Animation */}
            <section className="flow-section">
                <h2>How It Works</h2>
                <div className="flow-steps">
                    <div className="flow-step">
                        <div className="step-circle">💰</div>
                        <span className="step-label">Deposit</span>
                        <span className="step-desc">Into Vault</span>
                    </div>
                    <div className="flow-connector">
                        <div className="connector-line"></div>
                        <div className="connector-dot"></div>
                    </div>
                    <div className="flow-step">
                        <div className="step-circle">📊</div>
                        <span className="step-label">Monitor</span>
                        <span className="step-desc">Pool Rates</span>
                    </div>
                    <div className="flow-connector">
                        <div className="connector-line"></div>
                        <div className="connector-dot"></div>
                    </div>
                    <div className="flow-step">
                        <div className="step-circle">🧠</div>
                        <span className="step-label">Detect</span>
                        <span className="step-desc">Opportunity</span>
                    </div>
                    <div className="flow-connector">
                        <div className="connector-line"></div>
                        <div className="connector-dot"></div>
                    </div>
                    <div className="flow-step">
                        <div className="step-circle">⚡</div>
                        <span className="step-label">Rebalance</span>
                        <span className="step-desc">Automatically</span>
                    </div>
                </div>
            </section>

            {/* Bottom Stats/Info Bar */}
            <section className="info-bar">
                <div className="info-item">
                    <span className="info-icon">🏦</span>
                    <span className="info-text">Sepolia Testnet</span>
                </div>
                <div className="info-divider"></div>
                <div className="info-item">
                    <span className="info-icon">⚙️</span>
                    <span className="info-text">2% Rebalance Threshold</span>
                </div>
                <div className="info-divider"></div>
                <div className="info-item">
                    <span className="info-icon">🔄</span>
                    <span className="info-text">50% Auto-Rebalance</span>
                </div>
            </section>
        </div>
    );
}
