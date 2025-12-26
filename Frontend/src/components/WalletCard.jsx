import { useAppKit, useAppKitNetwork } from '@reown/appkit/react';
import { CHAIN_CONFIG } from '../contracts/addresses';
import { Wallet, Unplug, AlertTriangle } from 'lucide-react';

export function WalletCard({ address, isConnected }) {
    const { open } = useAppKit();
    const { chainId } = useAppKitNetwork();

    const isWrongNetwork = chainId && chainId !== CHAIN_CONFIG.chainId;

    return (
        <section className="card wallet-card glass-panel">
            <div className="card-header">
                <Wallet className="icon" />
                <h2>Wallet Connection</h2>
            </div>

            {!isConnected ? (
                <div className="wallet-actions">
                    <button className="btn btn-primary" onClick={() => open()}>
                        Connect Wallet
                    </button>
                </div>
            ) : (
                <div className="wallet-info">
                    <div className="info-row">
                        <span className="label">Address</span>
                        <span className="value code">
                            {address?.slice(0, 6)}...{address?.slice(-4)}
                        </span>
                    </div>

                    <div className="info-row">
                        <span className="label">Network</span>
                        <span className={`value status-badge ${isWrongNetwork ? 'error' : 'success'}`}>
                            {isWrongNetwork ? (
                                <>
                                    <AlertTriangle size={14} /> Wrong Network
                                </>
                            ) : (
                                'Sepolia Testnet'
                            )}
                        </span>
                    </div>

                    {isWrongNetwork && (
                        <div className="network-warning">
                            <p>Please switch to Sepolia to interact with the protocol.</p>
                        </div>
                    )}

                    <button className="btn btn-secondary btn-sm" onClick={() => open({ view: 'Account' })}>
                        Manage Wallet
                    </button>
                </div>
            )}
        </section>
    );
}
