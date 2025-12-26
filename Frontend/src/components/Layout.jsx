import { Toaster } from 'react-hot-toast';

export function Layout({ children }) {
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
                    <h1>🏦 Siaduan Protocol</h1>
                    <p className="subtitle">Cross-Chain Lending Vault powered by Reactive Network</p>
                </div>
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
