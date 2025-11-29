#!/bin/bash
# WeighIt Launcher Script
# Starts both the API and Flutter app for kiosk mode

set -e

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
echo "  WeighIt Food Pantry - Kiosk Mode"
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
echo "Starting Flutter app..."
cd "$SCRIPT_DIR/weighit_app"

# Run Flutter in release mode for better performance
flutter run -d linux --release &
FLUTTER_PID=$!

echo ""
echo "========================================="
echo "  WeighIt is now running!"
echo "  - API: http://127.0.0.1:8000"
echo "  - Press Ctrl+C to exit"
echo "========================================="
echo ""

# Wait for Flutter app to exit
wait $FLUTTER_PID

# Cleanup when Flutter exits
cleanup
