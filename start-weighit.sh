#!/bin/bash
# WeighIt Launcher Script
# Starts both the API and Flutter app for kiosk mode
#
# Usage:
#   ./start-weighit.sh           # Launch in release mode (default)
#   ./start-weighit.sh --debug   # Launch in debug mode (faster startup)
#   ./start-weighit.sh -d        # Launch in debug mode (short form)

set -e

# Parse command line arguments
FLUTTER_MODE="--release"
MODE_NAME="Release"

if [ "$1" = "--debug" ] || [ "$1" = "-d" ]; then
    FLUTTER_MODE=""
    MODE_NAME="Debug"
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Store PIDs for cleanup
API_PID=""
FLUTTER_PID=""

# Cleanup function
cleanup() {
    echo "Shutting down WeighIt..."

    if [ ! -z "$FLUTTER_PID" ]; then
        echo "Stopping Flutter app..."
        kill $FLUTTER_PID 2>/dev/null || true
    fi

    if [ ! -z "$API_PID" ]; then
        echo "Stopping API server..."
        kill $API_PID 2>/dev/null || true
    fi

    echo "Shutdown complete"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

echo "========================================="
echo "  WeighIt Food Pantry - $MODE_NAME Mode"
echo "========================================="
echo ""

# Start API server
echo "Starting API server..."
cd "$SCRIPT_DIR/weighit_api"

# Activate virtual environment if it exists
if [ -d "venv" ]; then
    source venv/bin/activate
fi

# Start API in background
python main.py &
API_PID=$!

# Wait for API to be ready
echo "Waiting for API to start..."
for i in {1..10}; do
    if curl -s http://127.0.0.1:8000 > /dev/null 2>&1; then
        echo "✓ API server is ready"
        break
    fi
    sleep 1
done

# Start Flutter app
echo "Starting Flutter app in $MODE_NAME mode..."
cd "$SCRIPT_DIR/weighit_app"

# Run Flutter with selected mode
if [ -z "$FLUTTER_MODE" ]; then
    # Debug mode - faster startup, hot reload available
    flutter run -d linux &
else
    # Release mode - optimized performance for production
    flutter run -d linux $FLUTTER_MODE &
fi
FLUTTER_PID=$!

echo ""
echo "========================================="
echo "  WeighIt is now running! ($MODE_NAME)"
echo "  - API: http://127.0.0.1:8000"
echo "  - Mode: $MODE_NAME"
echo "  - Press Ctrl+C to exit"
echo "========================================="
echo ""

# Wait for Flutter app to exit
wait $FLUTTER_PID

# Cleanup when Flutter exits
cleanup
