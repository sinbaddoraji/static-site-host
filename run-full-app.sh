#!/bin/bash

# This script runs both the backend and frontend with compatibility fixes

# Check if dependencies are installed
if [ ! -d "node_modules" ]; then
  echo "Frontend dependencies not found. Installing..."
  bash ./fix-dependencies.sh
fi

if [ ! -d "backend/node_modules" ]; then
  echo "Backend dependencies not found. Installing..."
  cd backend
  npm install
  cd ..
fi

# Set up backend if needed
if [ ! -d "backend" ]; then
  echo "Backend not found. Setting up backend..."
  source ./run-dev.sh
else
  # Start both services
  echo "Starting services..."
  
  # Start backend
  cd backend && npm run dev &
  BACKEND_PID=$!
  
  # Wait for backend to initialize
  sleep 2
  
  # Start frontend
  cd .. && npm run dev --legacy-peer-deps &
  FRONTEND_PID=$!
  
  # Handle termination
  function cleanup() {
    echo -e "\nStopping services..."
    kill $BACKEND_PID $FRONTEND_PID
    exit 0
  }
  
  trap cleanup SIGINT SIGTERM
  
  echo "Services are running. Press Ctrl+C to stop."
  wait
fi