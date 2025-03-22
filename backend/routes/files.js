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