#!/bin/bash

# This script will fix dependencies by using older compatible versions of ESLint packages

# Remove node_modules and cache
echo "Cleaning up previous installation..."
rm -rf node_modules
rm -rf .npm-cache
rm -rf package-lock.json

# Create updated .npmrc
echo "Creating .npmrc file..."
cat > .npmrc << EOF
engine-strict=false
legacy-peer-deps=true
resolution-mode=highest
EOF

# Install npm-force-resolutions
echo "Installing npm-force-resolutions..."
npm install --no-save npm-force-resolutions

# Apply resolutions
echo "Applying resolutions..."
npx npm-force-resolutions

# Install dependencies
echo "Installing dependencies..."
npm install --legacy-peer-deps

echo "Done! Your dependencies should now be compatible with Node.js v20.5.0"