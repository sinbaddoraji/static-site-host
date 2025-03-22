#!/bin/bash

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "Node.js is required but not installed. Please install Node.js and try again."
    exit 1
fi

# Check if backend directory exists, if not create it
if [ ! -d "backend" ]; then
    echo "Creating backend directory..."
    mkdir -p backend
    
    # Initialize backend
    cd backend
    npm init -y
    
    # Create package.json with required dependencies
    cat > package.json << EOF
{
  "name": "static-site-generator-api",
  "version": "1.0.0",
  "description": "API for static site generator and file manager",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "echo \\"Error: no test specified\\" && exit 1"
  },
  "dependencies": {
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "express": "^4.18.2",
    "express-jwt": "^8.4.1",
    "helmet": "^7.1.0",
    "jwks-rsa": "^3.1.0",
    "morgan": "^1.10.0",
    "multer": "^1.4.5-lts.1"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
EOF
    
    # Install dependencies
    npm install
    
    cd ..
fi

# Check if necessary files exist in backend, if not create them
if [ ! -f "backend/server.js" ]; then
    echo "Creating backend files..."
    
    # Create middleware directory
    mkdir -p backend/middleware
    
    # Create routes directory
    mkdir -p backend/routes
    
    # Create auth.js middleware
    cat > backend/middleware/auth.js << 'EOF'
const { expressjwt: jwt } = require('express-jwt');
const jwksRsa = require('jwks-rsa');

// Authentication middleware
const auth = jwt({
  secret: jwksRsa.expressJwtSecret({
    cache: true,
    rateLimit: true,
    jwksRequestsPerMinute: 5,
    jwksUri: `${process.env.AUTH_ISSUER}/.well-known/jwks.json`
  }),
  audience: process.env.AUTH_AUDIENCE,
  issuer: process.env.AUTH_ISSUER,
  algorithms: ['RS256']
});

// Add a conditional auth middleware for development
const conditionalAuth = (req, res, next) => {
  if (process.env.NODE_ENV === 'development' && process.env.SKIP_AUTH === 'true') {
    return next();
  }
  return auth(req, res, next);
};

module.exports = {
  auth: conditionalAuth
};
EOF
    
    # Create files.js routes
    cat > backend/routes/files.js << 'EOF'
const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs').promises;

// Configure storage for uploaded files
const siteFilesDir = process.env.SITE_FILES_DIR || './site_files';
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, siteFilesDir);
  },
  filename: (req, file, cb) => {
    // Use the original filename
    cb(null, file.originalname);
  }
});

// File filter to restrict file types if needed
const fileFilter = (req, file, cb) => {
  // Optional: Validate file types
  // For a static site, we might want to allow common web files
  const allowedTypes = [
    '.html', '.css', '.js', '.json', '.txt', '.md',
    '.jpg', '.jpeg', '.png', '.gif', '.svg', '.webp',
    '.pdf', '.ico', '.xml', '.woff', '.woff2', '.ttf', '.eot'
  ];
  
  const ext = path.extname(file.originalname).toLowerCase();
  if (allowedTypes.includes(ext)) {
    cb(null, true);
  } else {
    cb(new Error(`File type not allowed: ${ext}`));
  }
};

// Configure multer upload
const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024 // 10 MB limit
  }
});

/**
 * @route GET /api/files
 * @desc Get a list of all files in the site directory
 */
router.get('/', async (req, res, next) => {
  try {
    const files = await fs.readdir(siteFilesDir);
    
    // Get file stats (size, date modified, etc.)
    const fileDetails = await Promise.all(
      files.map(async (filename) => {
        const filePath = path.join(siteFilesDir, filename);
        const stats = await fs.stat(filePath);
        return {
          name: filename,
          size: stats.size,
          modified: stats.mtime,
          url: `/site/${filename}`
        };
      })
    );
    
    res.json(fileDetails);
  } catch (err) {
    next(err);
  }
});

/**
 * @route POST /api/files/upload
 * @desc Upload one or more files for the static site
 */
router.post('/upload', upload.array('files'), async (req, res, next) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ error: 'No files uploaded' });
    }
    
    const uploadedFiles = req.files.map(file => ({
      name: file.originalname,
      size: file.size,
      url: `/site/${file.originalname}`
    }));
    
    res.status(201).json({
      message: `Successfully uploaded ${req.files.length} file(s)`,
      files: uploadedFiles
    });
  } catch (err) {
    next(err);
  }
});

/**
 * @route DELETE /api/files/:filename
 * @desc Delete a specific file from the static site
 */
router.delete('/:filename', async (req, res, next) => {
  try {
    const filename = req.params.filename;
    
    // Sanitize filename to prevent path traversal attacks
    const sanitizedFilename = path.basename(filename);
    const filePath = path.join(siteFilesDir, sanitizedFilename);
    
    // Check if the file exists
    await fs.access(filePath);
    
    // Delete the file
    await fs.unlink(filePath);
    
    res.json({
      message: `Successfully deleted ${sanitizedFilename}`
    });
  } catch (err) {
    if (err.code === 'ENOENT') {
      return res.status(404).json({ error: 'File not found' });
    }
    next(err);
  }
});

/**
 * @route GET /api/files/:filename
 * @desc Get information about a specific file
 */
router.get('/:filename', async (req, res, next) => {
  try {
    const filename = req.params.filename;
    
    // Sanitize filename to prevent path traversal attacks
    const sanitizedFilename = path.basename(filename);
    const filePath = path.join(siteFilesDir, sanitizedFilename);
    
    // Get file stats
    const stats = await fs.stat(filePath);
    
    res.json({
      name: sanitizedFilename,
      size: stats.size,
      modified: stats.mtime,
      url: `/site/${sanitizedFilename}`
    });
  } catch (err) {
    if (err.code === 'ENOENT') {
      return res.status(404).json({ error: 'File not found' });
    }
    next(err);
  }
});

module.exports = router;
EOF
    
    # Create server.js
    cat > backend/server.js << 'EOF'
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

// API Routes
app.use('/api/files', auth, fileRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({
    error: {
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
});
EOF
    
    # Create .env file
    cat > backend/.env << EOF
# Server configuration
PORT=4000
NODE_ENV=development
SKIP_AUTH=true

# Static site configuration
SITE_FILES_DIR=./site_files
PUBLIC_SITE_URL=http://localhost:3000

# OIDC Auth Configuration
AUTH_ISSUER=https://sso.garri.ovh/
AUTH_AUDIENCE=312364566321364995
EOF
fi

# Create site_files directory if it doesn't exist
mkdir -p backend/site_files

# Check if frontend API service exists
if [ ! -d "src/api" ]; then
    mkdir -p src/api
    
    # Create fileService.ts
    cat > src/api/fileService.ts << 'EOF'
import { getUser } from '../auth/oidc-config';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:4000/api';

/**
 * Get authentication token from OIDC user
 */
const getAuthToken = async (): Promise<string | null> => {
  try {
    const user = await getUser();
    return user?.access_token || null;
  } catch (error) {
    console.error('Error getting auth token:', error);
    return null;
  }
};

/**
 * Get headers with authentication token
 */
const getAuthHeaders = async (): Promise<HeadersInit> => {
  const token = await getAuthToken();
  const headers: HeadersInit = {
    'Content-Type': 'application/json',
  };
  
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }
  
  return headers;
};

/**
 * Get a list of all files
 */
export const getFiles = async () => {
  const headers = await getAuthHeaders();
  const response = await fetch(`${API_URL}/files`, { 
    method: 'GET',
    headers 
  });
  
  if (!response.ok) {
    throw new Error(`Error fetching files: ${response.statusText}`);
  }
  
  return await response.json();
};

/**
 * Upload files to the static site
 */
export const uploadFiles = async (files: File[]) => {
  const token = await getAuthToken();
  const formData = new FormData();
  
  files.forEach(file => {
    formData.append('files', file);
  });
  
  const response = await fetch(`${API_URL}/files/upload`, {
    method: 'POST',
    headers: {
      'Authorization': token ? `Bearer ${token}` : '',
      // Don't set Content-Type for FormData, the browser will set it with the boundary
    },
    body: formData
  });
  
  if (!response.ok) {
    throw new Error(`Error uploading files: ${response.statusText}`);
  }
  
  return await response.json();
};

/**
 * Delete a file from the static site
 */
export const deleteFile = async (filename: string) => {
  const headers = await getAuthHeaders();
  const response = await fetch(`${API_URL}/files/${encodeURIComponent(filename)}`, {
    method: 'DELETE',
    headers
  });
  
  if (!response.ok) {
    throw new Error(`Error deleting file: ${response.statusText}`);
  }
  
  return await response.json();
};

/**
 * Get information about a specific file
 */
export const getFileInfo = async (filename: string) => {
  const headers = await getAuthHeaders();
  const response = await fetch(`${API_URL}/files/${encodeURIComponent(filename)}`, {
    method: 'GET',
    headers
  });
  
  if (!response.ok) {
    throw new Error(`Error getting file info: ${response.statusText}`);
  }
  
  return await response.json();
};
EOF
fi

# Start both backend and frontend in parallel
echo "Starting backend and frontend services..."

# Start backend
cd backend && npm run dev &
BACKEND_PID=$!

# Wait a moment for backend to start
sleep 2

# Start frontend
cd .. && npm run dev &
FRONTEND_PID=$!

# Function to handle script termination
function cleanup() {
    echo -e "\nStopping services..."
    kill $BACKEND_PID $FRONTEND_PID
    exit 0
}

# Set up the trap to catch termination signals
trap cleanup SIGINT SIGTERM

# Keep the script running
echo "Services are running. Press Ctrl+C to stop."
wait