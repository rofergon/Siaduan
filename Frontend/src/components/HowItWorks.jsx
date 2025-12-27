import './howItWorks.css';

export function HowItWorks() {
    const deployedContracts = {
        sepolia: [
            { name: 'LendingVault', address: '0xf8Af4B57A22328Af51448A43eEF1bbdE8542852D', description: 'Main vault that holds user deposits' },
            { name: 'RateCoordinator', address: '0x8d8159e74eE9c987925a2B5b21Cc6D6970513648', description: 'Aggregates and reports pool rates' },
            { name: 'MockUSDC', address: '0xf044c58496693C106a7EaE5460d39c1E99ABE074', description: 'Test token for deposits' },
            { name: 'Pool A', address: '0x242f6bcCA3208ff2b81F57Af6B9DC281bf1EabF4', description: 'Mock lending pool (lower rate)' },
            { name: 'Pool B', address: '0x7952AD383bC3B3443E36d58eC585C49824E4e489', description: 'Mock lending pool (higher rate)' },
            { name: 'Callback Proxy', address: '0xc9f36411C9897e7F959D99ffca2a0Ba7ee0D7bDA', description: 'Reactive Network callback receiver' },
        ],
        lasna: [
            { name: 'LendingRebalancer', address: '0x8cC046205284913b2844995fB01281E2945DF76f', description: 'Monitors events & triggers rebalances' },
        ]
    };

    const copyToClipboard = (text) => {
        navigator.clipboard.writeText(text);
    };

    return (
        <div className="how-it-works">
            {/* Hero Section */}
            <section className="hero-section glass-panel">
                <div className="hero-content">
                    <h1>🔄 How Siaduan Protocol Works</h1>
                    <p className="hero-subtitle">
                        Automated cross-chain yield optimization powered by <strong>Reactive Network</strong>
                    </p>
                    <div className="hero-features">
                        <div className="feature-badge">
                            <span className="feature-icon">⚡</span>
                            <span>Automatic Rebalancing</span>
                        </div>
                        <div className="feature-badge">
                            <span className="feature-icon">🔗</span>
                            <span>Cross-Chain</span>
                        </div>
                        <div className="feature-badge">
                            <span className="feature-icon">🛡️</span>
                            <span>Decentralized</span>
                        </div>
                    </div>
                </div>
            </section>

            {/* Architecture Diagram */}
            <section className="diagram-section glass-panel">
                <h2>📐 Protocol Architecture</h2>
                <p className="section-desc">
                    The diagram below shows how funds flow through the protocol. Users deposit into the LendingVault,
                    and the Reactive Network monitors rates across multiple pools to optimize yield automatically.
                </p>
                <div className="diagram-container">
                    <img
                        src="/protocol-architecture.jpg"
                        alt="Siaduan Protocol Architecture"
                        className="architecture-diagram"
                    />
                </div>
                <div className="diagram-legend">
                    <div className="legend-item">
                        <span className="legend-color vault"></span>
                        <span>LendingVault - Entry point for deposits</span>
                    </div>
                    <div className="legend-item">
                        <span className="legend-color reactive"></span>
                        <span>Reactive Network - Monitors & triggers rebalancing</span>
                    </div>
                    <div className="legend-item">
                        <span className="legend-color pools"></span>
                        <span>Lending Pools - Where funds earn yield</span>
                    </div>
                </div>
            </section>

            {/* How It Works Steps */}
            <section className="steps-section glass-panel">
                <h2>🚀 The Rebalancing Flow</h2>
                <div className="steps-grid">
                    <div className="step-card">
                        <div className="step-number">1</div>
                        <div className="step-icon">💰</div>
                        <h3>Deposit</h3>
                        <p>Users deposit USDC into the LendingVault. Funds are initially allocated to Pool A.</p>
                    </div>
                    <div className="step-arrow">→</div>
                    <div className="step-card">
                        <div className="step-number">2</div>
                        <div className="step-icon">📊</div>
                        <h3>Monitor</h3>
                        <p>RateCoordinator tracks supply rates from all pools and emits <code>RatesUpdated</code> events.</p>
                    </div>
                    <div className="step-arrow">→</div>
                    <div className="step-card">
                        <div className="step-number">3</div>
                        <div className="step-icon">🧠</div>
                        <h3>Detect</h3>
                        <p>LendingRebalancer on Reactive Network detects rate differentials &gt;2% between pools.</p>
                    </div>
                    <div className="step-arrow">→</div>
                    <div className="step-card">
                        <div className="step-number">4</div>
                        <div className="step-icon">⚡</div>
                        <h3>Rebalance</h3>
                        <p>Cross-chain callback triggers the vault to move funds to the higher-yield pool.</p>
                    </div>
                </div>
            </section>

            {/* Reactive Network Explanation */}
            <section className="reactive-section glass-panel">
                <h2>🌐 Understanding Reactive Network</h2>
                <div className="reactive-grid">
                    <div className="reactive-card">
                        <div className="reactive-icon">📡</div>
                        <h3>Event-Driven Architecture</h3>
                        <p>
                            Reactive Network contracts subscribe to events on other chains. When an event is emitted,
                            the reactive contract's <code>react()</code> function is automatically called.
                        </p>
                    </div>
                    <div className="reactive-card">
                        <div className="reactive-icon">🔄</div>
                        <h3>Cross-Chain Callbacks</h3>
                        <p>
                            Reactive contracts can emit <code>Callback</code> events that trigger function calls on
                            destination chains, enabling seamless cross-chain automation.
                        </p>
                    </div>
                    <div className="reactive-card">
                        <div className="reactive-icon">💾</div>
                        <h3>Stateless ReactVM</h3>
                        <p>
                            Each <code>react()</code> call executes with clean state. That's why we use RateCoordinator
                            to emit both rates in a single event - ensuring all data is available in one call.
                        </p>
                    </div>
                </div>

                <div className="code-flow">
                    <h4>The Technical Flow</h4>
                    <div className="code-flow-steps">
                        <div className="code-block">
                            <span className="code-label">Sepolia</span>
                            <code>RateCoordinator.reportRates()</code>
                            <span className="code-arrow">↓</span>
                            <code>emit RatesUpdated(rateA, rateB)</code>
                        </div>
                        <div className="flow-arrow-horizontal">→</div>
                        <div className="code-block">
                            <span className="code-label">Reactive Network</span>
                            <code>LendingRebalancer.react(log)</code>
                            <span className="code-arrow">↓</span>
                            <code>emit Callback(vault, rebalance)</code>
                        </div>
                        <div className="flow-arrow-horizontal">→</div>
                        <div className="code-block">
                            <span className="code-label">Sepolia</span>
                            <code>LendingVault.rebalance()</code>
                            <span className="code-arrow">↓</span>
                            <span className="code-result">Funds moved! ✓</span>
                        </div>
                    </div>
                </div>
            </section>

            {/* Deployed Contracts */}
            <section className="contracts-section glass-panel">
                <h2>📋 Deployed Contracts</h2>

                <div className="network-group">
                    <h3>
                        <span className="network-icon sepolia">◆</span>
                        Sepolia Testnet
                        <span className="chain-id">(Chain ID: 11155111)</span>
                    </h3>
                    <div className="contracts-table">
                        <div className="table-header">
                            <span>Contract</span>
                            <span>Address</span>
                            <span>Description</span>
                        </div>
                        {deployedContracts.sepolia.map((contract, idx) => (
                            <div className="table-row" key={idx}>
                                <span className="contract-name">{contract.name}</span>
                                <span className="contract-address">
                                    <code>{contract.address}</code>
                                    <button
                                        className="copy-btn"
                                        onClick={() => copyToClipboard(contract.address)}
                                        title="Copy address"
                                    >
                                        📋
                                    </button>
                                    <a
                                        href={`https://sepolia.etherscan.io/address/${contract.address}`}
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        className="explorer-link"
                                        title="View on Etherscan"
                                    >
                                        ↗
                                    </a>
                                </span>
                                <span className="contract-desc">{contract.description}</span>
                            </div>
                        ))}
                    </div>
                </div>

                <div className="network-group">
                    <h3>
                        <span className="network-icon lasna">◆</span>
                        Lasna (Reactive Network Testnet)
                        <span className="chain-id">(Chain ID: 5318007)</span>
                    </h3>
                    <div className="contracts-table">
                        <div className="table-header">
                            <span>Contract</span>
                            <span>Address</span>
                            <span>Description</span>
                        </div>
                        {deployedContracts.lasna.map((contract, idx) => (
                            <div className="table-row" key={idx}>
                                <span className="contract-name">{contract.name}</span>
                                <span className="contract-address">
                                    <code>{contract.address}</code>
                                    <button
                                        className="copy-btn"
                                        onClick={() => copyToClipboard(contract.address)}
                                        title="Copy address"
                                    >
                                        📋
                                    </button>
                                    <a
                                        href={`https://lasna.reactscan.net/address/0xab6e247b25463f76e81ababbb6b0b86b40d45d38/contract/${contract.address.toLowerCase()}`}
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        className="explorer-link"
                                        title="View on Reactscan"
                                    >
                                        ↗
                                    </a>
                                </span>
                                <span className="contract-desc">{contract.description}</span>
                            </div>
                        ))}
                    </div>
                </div>
            </section>

            {/* Getting Started */}
            <section className="getting-started-section glass-panel">
                <h2>🎯 Getting Started</h2>
                <div className="getting-started-steps">
                    <div className="gs-step">
                        <div className="gs-step-num">1</div>
                        <div className="gs-step-content">
                            <h4>Connect Your Wallet</h4>
                            <p>Click the "Connect Wallet" button in the header. Make sure you're on <strong>Sepolia testnet</strong>.</p>
                        </div>
                    </div>
                    <div className="gs-step">
                        <div className="gs-step-num">2</div>
                        <div className="gs-step-content">
                            <h4>Get Test Tokens</h4>
                            <p>Use the <strong>Token Faucet</strong> to mint MockUSDC for testing. Click "Mint 1000 Tokens".</p>
                        </div>
                    </div>
                    <div className="gs-step">
                        <div className="gs-step-num">3</div>
                        <div className="gs-step-content">
                            <h4>Deposit into the Vault</h4>
                            <p>Enter an amount in the <strong>Lending Vault</strong> panel and click "Deposit". Your funds will be allocated to Pool A.</p>
                        </div>
                    </div>
                    <div className="gs-step">
                        <div className="gs-step-num">4</div>
                        <div className="gs-step-content">
                            <h4>Trigger Rebalancing</h4>
                            <p>Use the <strong>Rate Control</strong> panel to simulate rate changes. Set Pool B higher than Pool A and click "Update Rates".</p>
                        </div>
                    </div>
                    <div className="gs-step">
                        <div className="gs-step-num">5</div>
                        <div className="gs-step-content">
                            <h4>Watch the Magic ✨</h4>
                            <p>The <strong>Protocol Status</strong> panel will update automatically as funds are rebalanced to the higher-yield pool!</p>
                        </div>
                    </div>
                </div>
            </section>

            {/* Resources */}
            <section className="resources-section glass-panel">
                <h2>🔗 Resources</h2>
                <div className="resources-grid">
                    <a href="https://dev.reactive.network/" target="_blank" rel="noopener noreferrer" className="resource-card">
                        <span className="resource-icon">📚</span>
                        <span className="resource-title">Reactive Network Docs</span>
                        <span className="resource-desc">Official documentation</span>
                    </a>
                    <a href="https://lasna.reactscan.net/" target="_blank" rel="noopener noreferrer" className="resource-card">
                        <span className="resource-icon">🔍</span>
                        <span className="resource-title">Reactscan Explorer</span>
                        <span className="resource-desc">View reactive transactions</span>
                    </a>
                    <a href="https://sepoliafaucet.com/" target="_blank" rel="noopener noreferrer" className="resource-card">
                        <span className="resource-icon">🚰</span>
                        <span className="resource-title">Sepolia Faucet</span>
                        <span className="resource-desc">Get testnet ETH</span>
                    </a>
                    <a href="https://github.com/rofergon/Siaduan" target="_blank" rel="noopener noreferrer" className="resource-card">
                        <span className="resource-icon">📦</span>
                        <span className="resource-title">GitHub Repo</span>
                        <span className="resource-desc">Source code</span>
                    </a>
                </div>
            </section>
        </div>
    );
}
