import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// Served from https://mihirajmera.github.io/guardduty-siem-automation/ and built into build/,
// the folder the Pages deploy workflow uploads.
export default defineConfig({
  base: '/guardduty-siem-automation/',
  plugins: [react()],
  // A single-page demo: Ant Design + Recharts are ~370 KB gzipped; splitting buys nothing here.
  build: { outDir: 'build', chunkSizeWarningLimit: 1400 },
});
