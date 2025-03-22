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

// Basic middleware
app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());

// Create site_files directory if it doesn't exist
(async () =
  try {
    await fs.mkdir(siteFilesDir, { recursive: true });
    console.log(`Created site files directory: ${siteFilesDir}`);
  } catch (err) {
    console.error('Error creating site files directory:', err);
  }
})();

// Serve static files from the site_files directory (the generated static site)
app.use('/site', express.static(siteFilesDir));

// API Routes
app.use('/api/files', auth, fileRoutes);

// Health check endpoint
app.get('/health', (req, res) =
  res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Error handling middleware
app.use((err, req, res, next) =
  console.error(err.stack);
    error: {
    }
  });
});

// Start the server
app.listen(PORT, () =
  console.log(`Server running on port ${PORT}`);
  console.log(`Static site available at: http://localhost:${PORT}/site`);
});
