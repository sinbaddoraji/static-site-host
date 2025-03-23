import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react-swc';
import path from 'path';

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => {
  // Load environment variables
  const env = loadEnv(mode, process.cwd(), '');
  
  return {
    plugins: [react()],
    define: {
      // Make environment variables available to the app
      'process.env': env
    },
    server: {
      port: 3000,
      host: '0.0.0.0', // Allow connections from outside container
      // Proxy API requests to the backend container
      proxy: {
        '/api': {
          target: 'http://backend:4000', // Use the service name from docker-compose
          changeOrigin: true,
          secure: false,
        },
        '/site': {
          target: 'http://backend:4000', // Use the service name from docker-compose
          changeOrigin: true,
          secure: false,
        }
      }
    },
    resolve: {
      alias: {
        '@': path.resolve(__dirname, './src'),
      },
    },
    build: {
      sourcemap: true,
      // Optimize chunks
      rollupOptions: {
        output: {
          manualChunks: {
            vendor: ['react', 'react-dom', 'react-router-dom', '@mui/material'],
            oidc: ['oidc-client-ts'],
          },
        },
      },
    },
  };
});