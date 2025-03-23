require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
const fs = require('fs').promises;
const { auth } = require('./middleware/auth');
const fileRoutes = require('./routes/files');

// Create Express app
const app = express();

// Print environment variables for debugging
console.log('Environment variables:');
console.log('NODE_ENV:', process.env.NODE_ENV);
console.log('SKIP_AUTH:', process.env.SKIP_AUTH);
console.log('PORT:', process.env.PORT);

// Basic middleware
app.use(helmet({
  contentSecurityPolicy: false, // Disable CSP for development
  crossOriginEmbedderPolicy: false // Allow cross-origin embedding
}));
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());

// Create site_files directory if it doesn't exist
const siteFilesDir = process.env.SITE_FILES_DIR || './site_files';
(async () => {
  try {
    await fs.mkdir(siteFilesDir, { recursive: true });
    console.log(`Created site files directory: ${siteFilesDir}`);
  } catch (err) {
    console.error('Error creating site files directory:', err);
  }
})();

// Serve static files from the site_files directory (the generated static site)
app.use('/site', express.static(siteFilesDir));

// Temporary route for testing without auth
app.get('/api/test', (req, res) => {
  res.json({ message: 'API is working correctly!' });
});

// API Routes
app.use('/api/files', auth, fileRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    environment: {
      NODE_ENV: process.env.NODE_ENV,
      SKIP_AUTH: process.env.SKIP_AUTH,
      PORT: process.env.PORT
    }
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error encountered:', err.name, err.message);
  console.error(err.stack);
  res.status(err.status || 500).json({
    error: {
      name: err.name,
      message: err.message || 'Internal Server Error',
      status: err.status || 500
    }
  });
});

// Start the server
const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Static site available at: http://localhost:${PORT}/site`);
  console.log(`API available at: http://localhost:${PORT}/api`);
  console.log(`Health check at: http://localhost:${PORT}/health`);
});