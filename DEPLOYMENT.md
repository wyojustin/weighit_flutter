# WeighIt Flutter - Deployment Guide

## Overview

This guide explains how to deploy the WeighIt Flutter application to a Linux device (such as the PineTab2).

## Prerequisites

- Linux device with Python 3.8+ and Flutter installed
- Virtual environment support for Python
- Network connectivity for initial setup

## Quick Start (PineTab2)

### 1. Clone the Repository

```bash
cd ~
git clone <repository-url> weighit_flutter
cd weighit_flutter
```

### 2. Set Up Python API

```bash
cd weighit_api

# Create and activate virtual environment
python -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Test the API
python main.py
```

You should see:
```
✓ Using database: /path/to/weighit.db
✓ Scale initialized
INFO:     Started server process [12345]
INFO:     Uvicorn running on http://127.0.0.1:8000
```

Press Ctrl+C to stop the server for now.

### 3. Set Up Flutter App

```bash
cd ../weighit_app

# Get Flutter dependencies
flutter pub get

# Test the Flutter app
flutter run -d linux
```

## Architecture

The application consists of two components:

1. **weighit_api/** - Python FastAPI backend service
   - Handles database operations
   - Manages scale hardware communication
   - Provides REST API endpoints
   - Now includes bundled `weigh` package for deployment

2. **weighit_app/** - Flutter desktop UI
   - Provides touch-friendly interface
   - Communicates with API via HTTP

## Bundled vs External WeighIt Package

### Deployment Mode (Default)

The API now includes a bundled `weigh` package located at `weighit_api/weigh/`:
- `scale_backend.py` - Scale driver with HID support and mock fallback
- `logger_core.py` - Business logic for logging and data retrieval
- `db.py` - Database operations

This bundled package allows the application to run without requiring an external weighit installation.

### Development Mode (Optional)

If you're developing alongside the original weighit package, you can use an external version:

```bash
export WEIGHIT_PATH=/path/to/weighit/src
python main.py
```

## Database

The database file `weighit.db` is included in `weighit_api/` and contains:
- Entry logs (donations)
- Sources (donation providers)
- Food types (with temperature requirements)
- Undo/redo stack

To reset the database, simply delete `weighit.db` and it will be recreated with default data on next startup.

## Scale Hardware

### Supported Scales

- Dymo M25 Digital Postal Scale (USB HID)
- Dymo M10 Digital Postal Scale (USB HID)
- Other Dymo USB scales (may work)

### Mock Scale Fallback

If no physical scale is detected, the application automatically uses a mock scale for testing:
- Simulates weight readings around 5.0 lb
- Includes stability simulation
- Allows full testing without hardware

### Scale Permissions (Linux)

If you encounter permission errors accessing the scale:

```bash
# Check device permissions
ls -l /dev/hidraw*

# Add udev rule for non-root access
sudo nano /etc/udev/rules.d/99-dymo-scale.rules
```

Add this line (replace `alarm` with your username):
```
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="0922", MODE="0666", GROUP="alarm"
```

Then reload udev rules:
```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

## Running in Production

### Option 1: Systemd Services (Recommended)

Create a systemd service for the API:

```bash
sudo nano /etc/systemd/system/weighit-api.service
```

Contents:
```ini
[Unit]
Description=WeighIt API Service
After=network.target

[Service]
Type=simple
User=alarm
WorkingDirectory=/home/alarm/weighit_flutter/weighit_api
Environment="PATH=/home/alarm/weighit_flutter/weighit_api/venv/bin"
ExecStart=/home/alarm/weighit_flutter/weighit_api/venv/bin/python main.py
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable weighit-api
sudo systemctl start weighit-api
sudo systemctl status weighit-api
```

### Option 2: Launcher Script

Create a launcher script that starts both components:

```bash
nano ~/start-weighit.sh
```

Contents:
```bash
#!/bin/bash

# Start API in background
cd ~/weighit_flutter/weighit_api
source venv/bin/activate
python main.py &
API_PID=$!

# Wait for API to be ready
sleep 2

# Start Flutter app in foreground
cd ~/weighit_flutter/weighit_app
flutter run -d linux --release

# Cleanup when Flutter app exits
kill $API_PID
```

Make it executable:
```bash
chmod +x ~/start-weighit.sh
```

Run it:
```bash
~/start-weighit.sh
```

### Option 3: Desktop Entry

Create a desktop launcher:

```bash
nano ~/.local/share/applications/weighit.desktop
```

Contents:
```ini
[Desktop Entry]
Name=WeighIt Food Pantry
Comment=Food pantry donation tracker
Exec=/home/alarm/start-weighit.sh
Icon=/home/alarm/weighit_flutter/weighit_app/assets/pantry_logo.png
Terminal=false
Type=Application
Categories=Utility;
```

## Configuration

### Environment Variables

Create a `.env` file in `weighit_api/` (optional):

```bash
# Database path (default: weighit_api/weighit.db)
DB_PATH=/custom/path/to/weighit.db

# External weighit package path (optional, for development)
# WEIGHIT_PATH=/home/user/code/weighit/src

# API server settings (defaults shown)
# API_HOST=127.0.0.1
# API_PORT=8000
```

### Email Reporting (Optional)

To enable email reports, configure `weighit_api/secrets.toml`:

```bash
cd weighit_api
cp secrets.toml.template secrets.toml
nano secrets.toml
```

Fill in your SMTP settings:
```toml
[email]
smtp_server = "smtp.gmail.com"
smtp_port = 587
username = "your-email@gmail.com"
password = "your-app-password"
default_recipient = "recipient@example.com"
```

## Troubleshooting

### API Won't Start - Module Not Found Error

**Problem:** `ModuleNotFoundError: No module named 'weigh'`

**Solution:** This has been fixed. The `weigh` package is now bundled in `weighit_api/weigh/`. Make sure you have the latest code:

```bash
git pull
cd weighit_api
python main.py
```

### Scale Not Detected

**Symptoms:** "Note: Using mock scale" in startup output

**Solutions:**
1. Check USB connection
2. Verify scale is powered on
3. Check device permissions (see Scale Permissions section above)
4. Confirm scale model is supported (Dymo M25, M10, etc.)

The application will continue to work with the mock scale for testing.

### Flutter App Can't Connect to API

**Symptoms:** Connection errors in Flutter app

**Solutions:**
1. Verify API is running: `curl http://127.0.0.1:8000`
2. Check API logs for errors
3. Ensure no firewall is blocking localhost connections
4. Verify port 8000 is not in use by another application

### Database Errors

**Symptoms:** SQL errors or missing tables

**Solutions:**
1. Delete `weighit.db` and restart API (will recreate with defaults)
2. Check database file permissions
3. Ensure enough disk space

### Flutter Build Errors

**Symptoms:** Build failures when running `flutter run`

**Solutions:**
```bash
cd weighit_app
flutter clean
flutter pub get
flutter run -d linux
```

## Updating the Application

```bash
cd ~/weighit_flutter

# Pull latest changes
git pull

# Update Python dependencies
cd weighit_api
source venv/bin/activate
pip install -r requirements.txt

# Update Flutter dependencies
cd ../weighit_app
flutter pub get

# Restart services
sudo systemctl restart weighit-api  # If using systemd
```

## Data Backup

### Manual Backup

```bash
# Backup database
cp weighit_api/weighit.db weighit_api/weighit.db.backup

# Or with timestamp
cp weighit_api/weighit.db weighit_api/weighit.db.$(date +%Y%m%d)
```

### Automated Backup Script

```bash
nano ~/backup-weighit.sh
```

Contents:
```bash
#!/bin/bash
BACKUP_DIR=~/weighit_backups
mkdir -p $BACKUP_DIR
DATE=$(date +%Y%m%d_%H%M%S)
cp ~/weighit_flutter/weighit_api/weighit.db $BACKUP_DIR/weighit_$DATE.db
# Keep only last 30 backups
ls -t $BACKUP_DIR/weighit_*.db | tail -n +31 | xargs rm -f
```

Add to crontab for daily backups:
```bash
crontab -e
# Add: 0 2 * * * /home/alarm/backup-weighit.sh
```

## Performance Optimization

### For PineTab2 and Resource-Constrained Devices

1. **Use Release Mode for Flutter:**
   ```bash
   flutter run -d linux --release
   ```

2. **Reduce API Log Verbosity:**
   Edit `main.py` to use `log_level="warning"`:
   ```python
   uvicorn.run(app, host="127.0.0.1", port=8000, log_level="warning")
   ```

3. **Database Optimization:**
   Periodically vacuum the database:
   ```bash
   sqlite3 weighit_api/weighit.db "VACUUM;"
   ```

## Security Considerations

### Production Checklist

- [ ] Change CORS settings in `main.py` from `allow_origins=["*"]` to specific origins
- [ ] Use HTTPS if exposing API beyond localhost (not recommended)
- [ ] Secure `secrets.toml` file permissions: `chmod 600 secrets.toml`
- [ ] Regular database backups
- [ ] Keep system and dependencies updated

### Current Security Posture

- API binds to `127.0.0.1` (localhost only) - not accessible from network
- No authentication required (designed for single-user kiosk mode)
- Database stored locally with standard file permissions

## Support and Development

### Logs

- **API Logs:** Check terminal where `python main.py` is running, or `sudo journalctl -u weighit-api` if using systemd
- **Flutter Logs:** Check terminal where `flutter run` is running
- **Database:** Can be inspected with: `sqlite3 weighit_api/weighit.db`

### Development Mode

For active development:

```bash
# Terminal 1 - API with auto-reload
cd weighit_api
source venv/bin/activate
uvicorn main:app --reload --host 127.0.0.1 --port 8000

# Terminal 2 - Flutter with hot reload
cd weighit_app
flutter run -d linux
```

Hot reload in Flutter: Press 'r' in terminal for hot reload, 'R' for hot restart

## Testing the Deployment

### 1. Test API Endpoints

```bash
# Health check
curl http://127.0.0.1:8000

# Scale reading
curl http://127.0.0.1:8000/scale/reading

# Get sources
curl http://127.0.0.1:8000/sources

# Get food types
curl http://127.0.0.1:8000/types

# Log a test entry
curl -X POST http://127.0.0.1:8000/log \
  -H "Content-Type: application/json" \
  -d '{"source":"Test","type":"Produce","weight_lb":5.5}'

# Get today's totals
curl http://127.0.0.1:8000/totals/today
```

### 2. Test Flutter App

1. Launch the app
2. Select a source
3. Click a food type button
4. Verify scale reading displays
5. Click LOG to record entry
6. Check history table updates

## Files and Directories

```
weighit_flutter/
├── weighit_api/
│   ├── weigh/                    # Bundled weighit package (NEW)
│   │   ├── __init__.py
│   │   ├── scale_backend.py      # Scale driver
│   │   ├── db.py                 # Database operations
│   │   └── logger_core.py        # Business logic
│   ├── main.py                   # API server
│   ├── email_reporter.py         # Email functionality
│   ├── requirements.txt          # Python dependencies
│   ├── weighit.db               # SQLite database
│   ├── secrets.toml             # Email config (if used)
│   └── venv/                    # Virtual environment
│
├── weighit_app/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/
│   │   ├── screens/
│   │   ├── services/
│   │   └── widgets/
│   ├── assets/
│   └── linux/
│
├── DEPLOYMENT.md                 # This file
├── CLAUDE.md                     # Development guide
└── README.md                     # Project overview
```

## Next Steps

After successful deployment:

1. Customize sources and food types in the database
2. Set up automated backups
3. Configure email reporting if needed
4. Create desktop launcher for easy access
5. Test with actual scale hardware

For development guidance, see `CLAUDE.md`.
For project overview, see `README.md`.
