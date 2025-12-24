import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { fileURLToPath } from 'url'
import { dirname, resolve } from 'path'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  optimizeDeps: {
    include: ['@reown/appkit', '@reown/appkit-adapter-ethers'],
    esbuildOptions: {
      target: 'esnext',
    },
  },
  resolve: {
    alias: {
      // Stub out the @base-org/account dynamic import (optional feature for Coinbase Smart Wallet)
      '@base-org/account': resolve(__dirname, 'src/stubs/base-org-account.js'),
    },
  },
})
