import { useProtocolData } from './hooks/useProtocolData';
import { Layout } from './components/Layout';
import { WalletCard } from './components/WalletCard';
import { FaucetCard } from './components/FaucetCard';
import { RateControl } from './components/RateControl';
import { VaultCard } from './components/VaultCard';
import { ProtocolStatus } from './components/ProtocolStatus';
import './App.css';

function App() {
  const {
    signer,
    address,
    isConnected,
    usdcBalance,
    shares,
    sharePrice,
    allocations,
    currentRates,
    refreshData
  } = useProtocolData();

  return (
    <Layout>
      <div className="dashboard-grid">
        <div className="col-left">
          <WalletCard address={address} isConnected={isConnected} />

          {isConnected && (
            <>
              <VaultCard
                signer={signer}
                address={address}
                shares={shares}
                sharePrice={sharePrice}
                usdcBalance={usdcBalance}
                refreshData={refreshData}
              />
              <FaucetCard
                signer={signer}
                usdcBalance={usdcBalance}
                refreshData={refreshData}
              />
            </>
          )}
        </div>

        <div className="col-right">
          {isConnected && (
            <>
              <ProtocolStatus
                allocations={allocations}
                currentRates={currentRates}
              />
              <RateControl
                signer={signer}
                currentRates={currentRates}
                refreshData={refreshData}
              />
            </>
          )}
        </div>
      </div>

      {!isConnected && (
        <div className="welcome-screen">
          <h2>Welcome to Siaduan</h2>
          <p>Please connect your wallet to start interacting with the cross-chain lending protocol.</p>
        </div>
      )}
    </Layout>
  );
}

export default App;
