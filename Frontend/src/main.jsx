import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './appkit-config' // Initialize Reown AppKit (WalletConnect)
import './index.css'
import App from './App.jsx'

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
