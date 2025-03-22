@echo off
echo Cleaning up previous installation...
if exist node_modules rmdir /s /q node_modules
if exist .npm-cache rmdir /s /q .npm-cache
if exist package-lock.json del /f package-lock.json

echo Creating .npmrc file...
echo engine-strict=false > .npmrc
echo legacy-peer-deps=true >> .npmrc
echo resolution-mode=highest >> .npmrc

echo Installing npm-force-resolutions...
call npm install --no-save npm-force-resolutions

echo Applying resolutions...
call npx npm-force-resolutions

echo Installing dependencies...
call npm install --legacy-peer-deps

echo Done! Your dependencies should now be compatible with Node.js v20.5.0