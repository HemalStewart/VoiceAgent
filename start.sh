#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "=========================================================================="
# Color formatting
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting EnglishMind AI Tutoring Platform...${NC}"
echo "=========================================================================="

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo -e "⚠️  ${BLUE}Notice: 'ffmpeg' was not found on your system path.${NC}"
    echo -e "   To enable audio format transcoding in local/cloud voice processing,"
    echo -e "   please install it using Homebrew:"
    echo -e "   ${GREEN}brew install ffmpeg${NC}\n"
fi

# Ensure directories exist
mkdir -p backend/temp_uploads

# 1. Start FastAPI Backend in background
echo -e "${BLUE}[1/2] Starting FastAPI Backend on http://localhost:8000...${NC}"
if [ -d "backend/venv" ]; then
    source backend/venv/bin/activate
fi

# Run FastAPI
python3 -m uvicorn backend.app:app --host 0.0.0.0 --port 8000 --reload &
BACKEND_PID=$!

# 2. Start Next.js Frontend in background
echo -e "${BLUE}[2/2] Starting Next.js Frontend on http://localhost:3000...${NC}"
cd frontend
npm run dev &
FRONTEND_PID=$!

# Handle shutdown cleanly on Ctrl+C (SIGINT)
cleanup() {
    echo -e "\n${GREEN}Shutting down servers...${NC}"
    kill $BACKEND_PID 2>/dev/null || true
    kill $FRONTEND_PID 2>/dev/null || true
    echo -e "${GREEN}Cleanup complete. Goodbye!${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM

echo "=========================================================================="
echo -e "${GREEN}Servers are running! Press Ctrl+C to stop both.${NC}"
echo "=========================================================================="

# Keep script running and wait for background processes
wait $BACKEND_PID $FRONTEND_PID
