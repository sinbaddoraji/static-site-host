@echo off
echo Finding your project structure...

echo.
echo =================================
echo DIRECTORIES:
echo =================================
dir /AD /B

echo.
echo =================================
echo FRONTEND STRUCTURE:
echo =================================
if exist frontend (
  dir frontend /B
  if exist frontend\src echo Frontend src directory exists
  if exist frontend\public echo Frontend public directory exists
  if exist frontend\package.json echo Frontend package.json exists
) else (
  echo No frontend directory found
  echo Looking for src at root level...
  if exist src echo src directory found at root level
  if exist public echo public directory found at root level
)

echo.
echo =================================
echo BACKEND STRUCTURE:
echo =================================
if exist backend (
  dir backend /B
  if exist backend\server.js echo Backend server.js exists
  if exist backend\package.json echo Backend package.json exists
) else (
  echo No backend directory found
)

echo.
echo =================================
echo PACKAGE.JSON:
echo =================================
if exist package.json (
  echo Root package.json exists:
  type package.json | findstr "\"build\"" | findstr ":"
)
if exist frontend\package.json (
  echo Frontend package.json exists:
  type frontend\package.json | findstr "\"build\"" | findstr ":"
)

echo.
echo =================================
echo OUTPUT DIRECTORIES:
echo =================================
if exist dist echo Root dist directory exists
if exist frontend\dist echo Frontend dist directory exists
if exist build echo Root build directory exists

echo.
echo Done! Please share this output to help diagnose your Docker issue.
