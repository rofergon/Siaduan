import { Toaster } from 'react-hot-toast';

export function Layout({ children, activeView, onViewChange }) {
    return (
        <div className="app-container">
            <Toaster
                position="top-right"
                toastOptions={{
                    style: {
                        background: '#1e293b', // var(--bg-card)
                        color: '#f8fafc', // var(--text-primary)
                        border: '1px solid #334155',
                    },
                }}
            />

            <header className="header glass-panel">
                <div className="header-content">
                    <div className="header-title-row">
                        <img src="/SiduonIcon.png" alt="Siaduan" className="header-logo" />
                        <h1>Siaduan Protocol</h1>
                    </div>
                    <p className="subtitle">Cross-Chain Lending Vault powered by Reactive Network</p>
                </div>
                <nav className="header-nav">
                    <button
                        className={`nav-tab ${activeView === 'dashboard' ? 'active' : ''}`}
                        onClick={() => onViewChange('dashboard')}
                    >
                        📊 Dashboard
                    </button>
                    <button
                        className={`nav-tab ${activeView === 'how-it-works' ? 'active' : ''}`}
                        onClick={() => onViewChange('how-it-works')}
                    >
                        📖 How It Works
                    </button>
                </nav>
            </header>

            <main className="main-content">
                {children}
            </main>

            <footer className="footer">
                <p>Powered by <strong>Reactive Network</strong> | Cross-Chain Lending Bounty</p>
            </footer>
        </div>
    );
}
