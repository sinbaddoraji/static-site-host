@echo off
setlocal enabledelayedexpansion

REM Check if dependencies are installed
if not exist node_modules (
  echo Frontend dependencies not found. Installing...
  call fix-dependencies.bat
)

if not exist backend\node_modules (
  echo Backend dependencies not found. Installing...
  cd backend
  call npm install
  cd ..
)

REM Check if backend exists, if not, create it
if not exist backend (
  echo Creating backend directory...
  mkdir backend
  
  REM Initialize backend
  cd backend
  call npm init -y
  
  REM Create package.json with required dependencies
  echo {> package.json
  echo   "name": "static-site-generator-api",>> package.json
  echo   "version": "1.0.0",>> package.json
  echo   "description": "API for static site generator and file manager",>> package.json
  echo   "main": "server.js",>> package.json
  echo   "scripts": {>> package.json
  echo     "start": "node server.js",>> package.json
  echo     "dev": "nodemon server.js",>> package.json
  echo     "test": "echo \"Error: no test specified\" && exit 1">> package.json
  echo   },>> package.json
  echo   "dependencies": {>> package.json
  echo     "cors": "^2.8.5",>> package.json
  echo     "dotenv": "^16.3.1",>> package.json
  echo     "express": "^4.18.2",>> package.json
  echo     "express-jwt": "^8.4.1",>> package.json
  echo     "helmet": "^7.1.0",>> package.json
  echo     "jwks-rsa": "^3.1.0",>> package.json
  echo     "morgan": "^1.10.0",>> package.json
  echo     "multer": "^1.4.5-lts.1">> package.json
  echo   },>> package.json
  echo   "devDependencies": {>> package.json
  echo     "nodemon": "^3.0.1">> package.json
  echo   }>> package.json
  echo }>> package.json
  
  REM Install dependencies
  call npm install
  
  REM Create required directories
  mkdir middleware
  mkdir routes
  mkdir site_files
  
  REM Create auth.js middleware
  echo const { expressjwt: jwt } = require('express-jwt');> middleware\auth.js
  echo const jwksRsa = require('jwks-rsa');>> middleware\auth.js
  echo.>> middleware\auth.js
  echo // Authentication middleware>> middleware\auth.js
  echo const auth = jwt({>> middleware\auth.js
  echo   secret: jwksRsa.expressJwtSecret({>> middleware\auth.js
  echo     cache: true,>> middleware\auth.js
  echo     rateLimit: true,>> middleware\auth.js
  echo     jwksRequestsPerMinute: 5,>> middleware\auth.js
  echo     jwksUri: `${process.env.AUTH_ISSUER}/.well-known/jwks.json`>> middleware\auth.js
  echo   }),>> middleware\auth.js
  echo   audience: process.env.AUTH_AUDIENCE,>> middleware\auth.js
  echo   issuer: process.env.AUTH_ISSUER,>> middleware\auth.js
  echo   algorithms: ['RS256']>> middleware\auth.js
  echo });>> middleware\auth.js
  echo.>> middleware\auth.js
  echo // Add a conditional auth middleware for development>> middleware\auth.js
  echo const conditionalAuth = (req, res, next) => {>> middleware\auth.js
  echo   if (process.env.NODE_ENV === 'development' && process.env.SKIP_AUTH === 'true') {>> middleware\auth.js
  echo     return next();>> middleware\auth.js
  echo   }>> middleware\auth.js
  echo   return auth(req, res, next);>> middleware\auth.js
  echo };>> middleware\auth.js
  echo.>> middleware\auth.js
  echo module.exports = {>> middleware\auth.js
  echo   auth: conditionalAuth>> middleware\auth.js
  echo };>> middleware\auth.js

  REM Create files.js routes
  echo const express = require('express');> routes\files.js
  echo const router = express.Router();>> routes\files.js
  echo const multer = require('multer');>> routes\files.js
  echo const path = require('path');>> routes\files.js
  echo const fs = require('fs').promises;>> routes\files.js
  echo.>> routes\files.js
  echo // Configure storage for uploaded files>> routes\files.js
  echo const siteFilesDir = process.env.SITE_FILES_DIR || './site_files';>> routes\files.js
  echo const storage = multer.diskStorage({>> routes\files.js
  echo   destination: (req, file, cb) => {>> routes\files.js
  echo     cb(null, siteFilesDir);>> routes\files.js
  echo   },>> routes\files.js
  echo   filename: (req, file, cb) => {>> routes\files.js
  echo     // Use the original filename>> routes\files.js
  echo     cb(null, file.originalname);>> routes\files.js
  echo   }>> routes\files.js
  echo });>> routes\files.js
  
  REM Add more code to files.js
  echo.>> routes\files.js
  echo // File filter to restrict file types if needed>> routes\files.js
  echo const fileFilter = (req, file, cb) => {>> routes\files.js
  echo   // Optional: Validate file types>> routes\files.js
  echo   // For a static site, we might want to allow common web files>> routes\files.js
  echo   const allowedTypes = [>> routes\files.js
  echo     '.html', '.css', '.js', '.json', '.txt', '.md',>> routes\files.js
  echo     '.jpg', '.jpeg', '.png', '.gif', '.svg', '.webp',>> routes\files.js
  echo     '.pdf', '.ico', '.xml', '.woff', '.woff2', '.ttf', '.eot'>> routes\files.js
  echo   ];>> routes\files.js
  echo   >> routes\files.js
  echo   const ext = path.extname(file.originalname).toLowerCase();>> routes\files.js
  echo   if (allowedTypes.includes(ext)) {>> routes\files.js
  echo     cb(null, true);>> routes\files.js
  echo   } else {>> routes\files.js
  echo     cb(new Error(`File type not allowed: ${ext}`));>> routes\files.js
  echo   }>> routes\files.js
  echo };>> routes\files.js
  echo.>> routes\files.js
  echo // Configure multer upload>> routes\files.js
  echo const upload = multer({>> routes\files.js
  echo   storage: storage,>> routes\files.js
  echo   fileFilter: fileFilter,>> routes\files.js
  echo   limits: {>> routes\files.js
  echo     fileSize: 10 * 1024 * 1024 // 10 MB limit>> routes\files.js
  echo   }>> routes\files.js
  echo });>> routes\files.js
  
  REM Add routes to files.js
  echo.>> routes\files.js
  echo /**>> routes\files.js
  echo  * @route GET /api/files>> routes\files.js
  echo  * @desc Get a list of all files in the site directory>> routes\files.js
  echo  */>> routes\files.js
  echo router.get('/', async (req, res, next) => {>> routes\files.js
  echo   try {>> routes\files.js
  echo     const files = await fs.readdir(siteFilesDir);>> routes\files.js
  echo     >> routes\files.js
  echo     // Get file stats (size, date modified, etc.)>> routes\files.js
  echo     const fileDetails = await Promise.all(>> routes\files.js
  echo       files.map(async (filename) => {>> routes\files.js
  echo         const filePath = path.join(siteFilesDir, filename);>> routes\files.js
  echo         const stats = await fs.stat(filePath);>> routes\files.js
  echo         return {>> routes\files.js
  echo           name: filename,>> routes\files.js
  echo           size: stats.size,>> routes\files.js
  echo           modified: stats.mtime,>> routes\files.js
  echo           url: `/site/${filename}`>> routes\files.js
  echo         };>> routes\files.js
  echo       })>> routes\files.js
  echo     );>> routes\files.js
  echo     >> routes\files.js
  echo     res.json(fileDetails);>> routes\files.js
  echo   } catch (err) {>> routes\files.js
  echo     next(err);>> routes\files.js
  echo   }>> routes\files.js
  echo });>> routes\files.js
  
  REM More routes in files.js
  echo.>> routes\files.js
  echo /**>> routes\files.js
  echo  * @route POST /api/files/upload>> routes\files.js
  echo  * @desc Upload one or more files for the static site>> routes\files.js
  echo  */>> routes\files.js
  echo router.post('/upload', upload.array('files'), async (req, res, next) => {>> routes\files.js
  echo   try {>> routes\files.js
  echo     if (!req.files || req.files.length === 0) {>> routes\files.js
  echo       return res.status(400).json({ error: 'No files uploaded' });>> routes\files.js
  echo     }>> routes\files.js
  echo     >> routes\files.js
  echo     const uploadedFiles = req.files.map(file => ({>> routes\files.js
  echo       name: file.originalname,>> routes\files.js
  echo       size: file.size,>> routes\files.js
  echo       url: `/site/${file.originalname}`>> routes\files.js
  echo     }));>> routes\files.js
  echo     >> routes\files.js
  echo     res.status(201).json({>> routes\files.js
  echo       message: `Successfully uploaded ${req.files.length} file(s)`,>> routes\files.js
  echo       files: uploadedFiles>> routes\files.js
  echo     });>> routes\files.js
  echo   } catch (err) {>> routes\files.js
  echo     next(err);>> routes\files.js
  echo   }>> routes\files.js
  echo });>> routes\files.js
  
  REM Final routes and export in files.js
  echo.>> routes\files.js
  echo /**>> routes\files.js
  echo  * @route DELETE /api/files/:filename>> routes\files.js
  echo  * @desc Delete a specific file from the static site>> routes\files.js
  echo  */>> routes\files.js
  echo router.delete('/:filename', async (req, res, next) => {>> routes\files.js
  echo   try {>> routes\files.js
  echo     const filename = req.params.filename;>> routes\files.js
  echo     >> routes\files.js
  echo     // Sanitize filename to prevent path traversal attacks>> routes\files.js
  echo     const sanitizedFilename = path.basename(filename);>> routes\files.js
  echo     const filePath = path.join(siteFilesDir, sanitizedFilename);>> routes\files.js
  echo     >> routes\files.js
  echo     // Check if the file exists>> routes\files.js
  echo     await fs.access(filePath);>> routes\files.js
  echo     >> routes\files.js
  echo     // Delete the file>> routes\files.js
  echo     await fs.unlink(filePath);>> routes\files.js
  echo     >> routes\files.js
  echo     res.json({>> routes\files.js
  echo       message: `Successfully deleted ${sanitizedFilename}`>> routes\files.js
  echo     });>> routes\files.js
  echo   } catch (err) {>> routes\files.js
  echo     if (err.code === 'ENOENT') {>> routes\files.js
  echo       return res.status(404).json({ error: 'File not found' });>> routes\files.js
  echo     }>> routes\files.js
  echo     next(err);>> routes\files.js
  echo   }>> routes\files.js
  echo });>> routes\files.js
  echo.>> routes\files.js
  echo /**>> routes\files.js
  echo  * @route GET /api/files/:filename>> routes\files.js
  echo  * @desc Get information about a specific file>> routes\files.js
  echo  */>> routes\files.js
  echo router.get('/:filename', async (req, res, next) => {>> routes\files.js
  echo   try {>> routes\files.js
  echo     const filename = req.params.filename;>> routes\files.js
  echo     >> routes\files.js
  echo     // Sanitize filename to prevent path traversal attacks>> routes\files.js
  echo     const sanitizedFilename = path.basename(filename);>> routes\files.js
  echo     const filePath = path.join(siteFilesDir, sanitizedFilename);>> routes\files.js
  echo     >> routes\files.js
  echo     // Get file stats>> routes\files.js
  echo     const stats = await fs.stat(filePath);>> routes\files.js
  echo     >> routes\files.js
  echo     res.json({>> routes\files.js
  echo       name: sanitizedFilename,>> routes\files.js
  echo       size: stats.size,>> routes\files.js
  echo       modified: stats.mtime,>> routes\files.js
  echo       url: `/site/${sanitizedFilename}`>> routes\files.js
  echo     });>> routes\files.js
  echo   } catch (err) {>> routes\files.js
  echo     if (err.code === 'ENOENT') {>> routes\files.js
  echo       return res.status(404).json({ error: 'File not found' });>> routes\files.js
  echo     }>> routes\files.js
  echo     next(err);>> routes\files.js
  echo   }>> routes\files.js
  echo });>> routes\files.js
  echo.>> routes\files.js
  echo module.exports = router;>> routes\files.js
  
  REM Create server.js
  echo require('dotenv').config();> server.js
  echo const express = require('express');>> server.js
  echo const cors = require('cors');>> server.js
  echo const helmet = require('helmet');>> server.js
  echo const morgan = require('morgan');>> server.js
  echo const path = require('path');>> server.js
  echo const fs = require('fs').promises;>> server.js
  echo const { auth } = require('./middleware/auth');>> server.js
  echo const fileRoutes = require('./routes/files');>> server.js
  echo.>> server.js
  echo // Create Express app>> server.js
  echo const app = express();>> server.js
  echo.>> server.js
  echo // Basic middleware>> server.js
  echo app.use(helmet());>> server.js
  echo app.use(cors());>> server.js
  echo app.use(morgan('dev'));>> server.js
  echo app.use(express.json());>> server.js
  echo.>> server.js
  echo // Create site_files directory if it doesn't exist>> server.js
  echo const siteFilesDir = process.env.SITE_FILES_DIR || './site_files';>> server.js
  echo (async () => {>> server.js
  echo   try {>> server.js
  echo     await fs.mkdir(siteFilesDir, { recursive: true });>> server.js
  echo     console.log(`Created site files directory: ${siteFilesDir}`);>> server.js
  echo   } catch (err) {>> server.js
  echo     console.error('Error creating site files directory:', err);>> server.js
  echo   }>> server.js
  echo })();>> server.js
  echo.>> server.js
  echo // Serve static files from the site_files directory (the generated static site)>> server.js
  echo app.use('/site', express.static(siteFilesDir));>> server.js
  echo.>> server.js
  echo // API Routes>> server.js
  echo app.use('/api/files', auth, fileRoutes);>> server.js
  echo.>> server.js
  echo // Health check endpoint>> server.js
  echo app.get('/health', (req, res) => {>> server.js
  echo   res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });>> server.js
  echo });>> server.js
  echo.>> server.js
  echo // Error handling middleware>> server.js
  echo app.use((err, req, res, next) => {>> server.js
  echo   console.error(err.stack);>> server.js
  echo   res.status(err.status || 500).json({>> server.js
  echo     error: {>> server.js
  echo       message: err.message || 'Internal Server Error',>> server.js
  echo       status: err.status || 500>> server.js
  echo     }>> server.js
  echo   });>> server.js
  echo });>> server.js
  echo.>> server.js
  echo // Start the server>> server.js
  echo const PORT = process.env.PORT || 4000;>> server.js
  echo app.listen(PORT, () => {>> server.js
  echo   console.log(`Server running on port ${PORT}`);>> server.js
  echo   console.log(`Static site available at: http://localhost:${PORT}/site`);>> server.js
  echo });>> server.js
  
  REM Create .env file
  echo # Server configuration> .env
  echo PORT=4000>> .env
  echo NODE_ENV=development>> .env
  echo SKIP_AUTH=true>> .env
  echo.>> .env
  echo # Static site configuration>> .env
  echo SITE_FILES_DIR=./site_files>> .env
  echo PUBLIC_SITE_URL=http://localhost:3000>> .env
  echo.>> .env
  echo # OIDC Auth Configuration>> .env
  echo AUTH_ISSUER=https://sso.garri.ovh/>> .env
  echo AUTH_AUDIENCE=312364566321364995>> .env
  
  REM Return to project root
  cd ..
)

echo Starting services...

REM Start both services using start command to open new command windows
start cmd /c "cd backend && npm run dev"

REM Wait for backend to start
timeout /t 2 /nobreak > nul

start cmd /c "npm run dev --legacy-peer-deps"

echo Services are running. Close the command windows to stop the services.