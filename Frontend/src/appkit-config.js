import { createAppKit } from '@reown/appkit/react'
import { EthersAdapter } from '@reown/appkit-adapter-ethers'
import { sepolia } from '@reown/appkit/networks'

// 1. Get projectId from environment variable
const projectId = import.meta.env.VITE_REOWN_PROJECT_ID

if (!projectId) {
    console.warn('⚠️ VITE_REOWN_PROJECT_ID not set. Please add it to your .env file.')
}

// 2. Create metadata for your dApp
const metadata = {
    name: 'Siaduan Protocol',
    description: 'Cross-Chain Lending Vault powered by Reactive Network',
    url: window.location.origin,
    icons: ['https://avatars.githubusercontent.com/u/37784886']
}

// 3. Create the AppKit instance
export const appKit = createAppKit({
    adapters: [new EthersAdapter()],
    metadata,
    networks: [sepolia],
    projectId: projectId || 'demo', // fallback for development
    features: {
        analytics: true,
        email: false, // Disable email login
        socials: false // Disable social login
    },
    themeMode: 'dark',
    themeVariables: {
        '--w3m-accent': '#6366f1', // Indigo accent color
        '--w3m-color-mix': '#1e1b4b',
        '--w3m-color-mix-strength': 40
    }
})

export default appKit
