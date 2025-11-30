#!/bin/bash
# WeighIt Streamlit Launcher
# Starts the Streamlit app with configurable browser support
#
# Usage:
#   ./launch.sh                     # Launch with default browser
#   ./launch.sh --browser firefox   # Launch with Firefox
#   ./launch.sh --browser epiphany  # Launch with Epiphany
#   ./launch.sh --browser chromium  # Launch with Chromium

set -e

# Default browser
BROWSER="firefox"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --browser|-b)
            BROWSER="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [--browser BROWSER]"
            echo ""
            echo "Options:"
            echo "  --browser, -b    Browser to use (firefox, epiphany, chromium)"
            echo "  --help, -h       Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --browser firefox"
            echo "  $0 --browser epiphany"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate browser choice
case $BROWSER in
    firefox|epiphany|chromium)
        # Valid browser
        ;;
    *)
        echo "Error: Unsupported browser '$BROWSER'"
        echo "Supported browsers: firefox, epiphany, chromium"
        exit 1
        ;;
esac

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if app.py exists
APP_PATH="$SCRIPT_DIR/weighit_api/weigh/app.py"
if [ ! -f "$APP_PATH" ]; then
    echo "Error: Streamlit app not found at $APP_PATH"
    echo "Please create the app.py file first"
    exit 1
fi

echo "========================================="
echo "  WeighIt Food Pantry - Streamlit"
echo "========================================="
echo "Browser: $BROWSER"
echo "App: $APP_PATH"
echo ""

# Change to the app directory
cd "$SCRIPT_DIR/weighit_api/weigh"

# Activate virtual environment if it exists
if [ -d "$SCRIPT_DIR/weighit_api/venv" ]; then
    source "$SCRIPT_DIR/weighit_api/venv/bin/activate"
fi

# Launch Streamlit with the specified browser
echo "Starting Streamlit app with $BROWSER..."

# Set browser command based on choice
case $BROWSER in
    firefox)
        export BROWSER=firefox
        ;;
    epiphany)
        export BROWSER=epiphany
        ;;
    chromium)
        export BROWSER=chromium
        ;;
esac

# Launch Streamlit
# Streamlit will use the BROWSER environment variable to open the browser
streamlit run app.py --browser.gatherUsageStats=false

echo ""
echo "========================================="
echo "  Streamlit app stopped"
echo "========================================="
