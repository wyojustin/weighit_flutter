# CLAUDE.md - WeighIt Flutter Project Guide

## Project Overview

**WeighIt Flutter** is a food pantry scale application consisting of a Flutter desktop UI and a Python FastAPI backend. The architecture decouples the UI from the backend logic, allowing the Flutter app to provide a modern touch-friendly interface while the Python API wraps the existing weighit backend without modification.

### Core Purpose
- Track food donations by weight, source, and type
- Interface with a Dymo HID scale for real-time weight readings
- Log temperature data for perishable items
- Provide daily totals and historical donation data
- Support undo/redo functionality for data entry corrections

## Architecture

```
weighit_flutter/
├── weighit_api/          # Python FastAPI service
│   ├── main.py          # API server with all endpoints
│   ├── requirements.txt # Python dependencies
│   ├── .env.example     # Environment configuration template
│   └── README.md        # API-specific documentation
│
├── weighit_app/          # Flutter desktop application
│   └── lib/
│       └── services/
│           └── api_service.dart  # HTTP client for API communication
│
├── setup.sh             # Project initialization script
├── README.md            # Main project documentation
└── .gitignore          # Git ignore patterns
```

### Communication Flow
1. Flutter app makes HTTP requests to `http://127.0.0.1:8000`
2. FastAPI service processes requests
3. API imports and uses the original weighit package at `/home/justin/code/weighit/src`
4. Shared database and scale driver ensure consistency

## Technology Stack

### Backend (weighit_api/)
- **Python 3.x** - Primary language
- **FastAPI** (>=0.104.0) - Modern async web framework
- **Uvicorn** - ASGI server with standard extras
- **Pydantic** (>=2.0.0) - Data validation and serialization
- **Original weighit package** - Scale driver and business logic (external dependency)

### Frontend (weighit_app/)
- **Flutter/Dart** - Cross-platform UI framework (desktop Linux target)
- **http** package (^1.1.0) - HTTP client for API calls
- **provider** package (^6.1.0) - State management (planned)

## Key Files and Their Purposes

### weighit_api/main.py
**Primary API server implementation** (202 lines)

**Key Components:**
- `DymoHIDScale` singleton for hardware communication
- CORS middleware for localhost Flutter app
- 11 REST endpoints for all application functionality

**Important Patterns:**
- Global `scale` variable initialized on startup
- Graceful degradation when scale unavailable (returns mock data)
- Uses original weighit modules: `scale_backend`, `logger_core`, `db`

**Pydantic Models:**
```python
class LogEntryRequest(BaseModel):
    source: str
    type: str
    weight_lb: float
    temp_pickup_f: Optional[float] = None
    temp_dropoff_f: Optional[float] = None

class ScaleReadingResponse(BaseModel):
    value: float
    unit: str
    is_stable: bool
    available: bool
```

**Critical Note:** Path to original weighit package is configured via `WEIGHIT_PATH` environment variable (default: `/home/justin/code/weighit/src`)

### weighit_app/lib/services/api_service.dart
**Flutter API client** (128 lines)

**Key Classes:**
- `ApiService` - HTTP client wrapper with base URL configuration
- `ScaleReading` - Model for scale data with JSON serialization
- `FoodType` - Model for food type metadata

**API Methods:**
- `getScaleReading()` - Continuous weight monitoring
- `logEntry()` - Record donations
- `getSources()` / `getTypes()` - Fetch configuration data
- `getTodayTotals()` - Retrieve daily statistics
- `undo()` / `redo()` - Entry management

## API Endpoints Reference

### Scale Operations
- **GET `/scale/reading`** - Current scale reading (polled continuously)
  - Returns: `{value, unit, is_stable, available}`
  - Safe when scale unavailable (returns zeros)

- **GET `/scale/stable?timeout=2.0`** - Wait for stable weight
  - Used by LOG button workflow
  - 408 timeout or 503 if scale unavailable

### Data Management
- **POST `/log`** - Create donation entry
  - Body: `{source, type, weight_lb, temp_pickup_f?, temp_dropoff_f?}`
  - Validates required temperature for certain food types

- **POST `/undo`** - Undo last entry (404 if none)
- **POST `/redo`** - Redo last undo (404 if none)

### Configuration & Queries
- **GET `/sources`** - List of donation sources
- **GET `/types`** - Food types with `requires_temp` and `sort_order` metadata
- **GET `/totals/today?source=X`** - Today's totals by type (optional source filter)
- **GET `/history/recent?limit=15&source=X`** - Recent entries

### Health Check
- **GET `/`** - Service status and scale connection state

**Interactive Documentation:** Available at `http://127.0.0.1:8000/docs` when running

## Development Workflows

### Initial Setup
```bash
# 1. Set up Python API
cd weighit_api
pip install -r requirements.txt

# 2. Configure environment (optional)
cp .env.example .env
# Edit WEIGHIT_PATH if weighit package is not at default location

# 3. Initialize Flutter app (one-time)
cd ../weighit_app
flutter create .

# 4. Configure Flutter dependencies
# Edit pubspec.yaml to add http and provider packages
flutter pub get
```

### Running the Application

**Two-terminal approach (development):**

Terminal 1 - API Server:
```bash
cd weighit_api
python main.py
# Or: uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

Terminal 2 - Flutter App:
```bash
cd weighit_app
flutter run -d linux
```

**Verification:**
- API health: `curl http://127.0.0.1:8000`
- API docs: Open browser to `http://127.0.0.1:8000/docs`
- Scale status: Check startup output for "✓ Scale initialized" or "⚠ Warning: Could not initialize scale"

### Making Changes

**Backend Changes (Python API):**
1. Edit `weighit_api/main.py` or add new modules
2. If using `uvicorn --reload`, changes auto-reload
3. Test endpoints via `/docs` interactive UI or curl
4. **IMPORTANT:** Never modify files in `/home/justin/code/weighit/src` - this is the original weighit package

**Frontend Changes (Flutter):**
1. Edit Dart files in `weighit_app/lib/`
2. Hot reload available in Flutter (press 'r' in terminal)
3. Hot restart for major changes (press 'R')
4. Update `api_service.dart` when adding new endpoints

**Adding New API Endpoints:**
1. Add endpoint function to `main.py`
2. Create Pydantic models if needed
3. Add corresponding method to `api_service.dart`
4. Update model classes in Dart if response structure changes

### Git Workflow

**Current Branch:** `claude/claude-md-mijjztgg1iyvrwci-016zkF65jm5zRyeDLWYpd15z`

**Branch Naming Convention:**
- Feature branches: `claude/` prefix with session ID suffix
- Push only to designated branch: `git push -u origin <branch-name>`

**Commit Guidelines:**
- Clear, descriptive messages focusing on "why" not "what"
- Check git status and diff before committing
- Never commit secrets (.env files, credentials)
- Follow existing commit message style (see recent commits)

## Coding Conventions

### Python (weighit_api/)
- **Style:** Follow PEP 8
- **Async/Await:** All FastAPI endpoints are async
- **Error Handling:** Use HTTPException with appropriate status codes
  - 400: Bad request (validation errors)
  - 404: Resource not found
  - 408: Request timeout
  - 503: Service unavailable
- **Type Hints:** Use typing module for all function signatures
- **Docstrings:** Brief docstrings for all endpoints
- **Imports:** Group by stdlib, third-party, local (with blank lines between)

### Dart/Flutter (weighit_app/)
- **Style:** Follow Dart style guide (dartfmt)
- **Naming:**
  - Classes: PascalCase
  - Variables/methods: camelCase
  - Constants: lowerCamelCase (not SCREAMING_SNAKE_CASE)
- **Async:** Use Future/async-await for all API calls
- **Error Handling:** Throw exceptions on HTTP errors, catch in UI layer
- **JSON Serialization:** Factory constructors `fromJson()` for all models

### File Organization
- **API Services:** `weighit_app/lib/services/`
- **Data Models:** `weighit_app/lib/models/` (when created)
- **UI Screens:** `weighit_app/lib/screens/` (when created)
- **Widgets:** `weighit_app/lib/widgets/` (when created)

## External Dependencies

### Original WeighIt Package
**Location:** `/home/justin/code/weighit/src`
**Used Modules:**
- `weigh.scale_backend` - DymoHIDScale, ScaleReading classes
- `weigh.logger_core` - Business logic functions
- `weigh.db` - Database access

**CRITICAL RULES:**
1. **NEVER modify files in the original weighit package**
2. Configure path via `WEIGHIT_PATH` environment variable
3. The weighit package is added to sys.path at runtime
4. Database and configuration files are shared between apps

### Flutter Not Yet Initialized
The Flutter app structure is minimal - only `lib/services/api_service.dart` exists. Full Flutter project needs:
```bash
cd weighit_app && flutter create .
```

This will generate:
- `pubspec.yaml` - Dependencies and metadata
- `lib/main.dart` - Application entry point
- Platform-specific files for Linux desktop

## Environment Configuration

### Environment Variables (.env)
```bash
WEIGHIT_PATH=/home/justin/code/weighit/src  # Original package location
API_HOST=127.0.0.1                          # API bind address
API_PORT=8000                               # API port
# DB_PATH=/path/to/weigh.db                 # Optional DB override
```

**Loading .env:** Not currently implemented in code - variables read via `os.getenv()` with defaults

## Testing Guidelines

### API Testing
1. **Manual Testing:** Use FastAPI's `/docs` interface
2. **curl Examples:**
   ```bash
   # Health check
   curl http://127.0.0.1:8000

   # Get scale reading
   curl http://127.0.0.1:8000/scale/reading

   # Log entry
   curl -X POST http://127.0.0.1:8000/log \
     -H "Content-Type: application/json" \
     -d '{"source":"Test","type":"Produce","weight_lb":5.5}'
   ```
3. **Python tests:** Not yet implemented - consider pytest for future

### Flutter Testing
- **Unit tests:** Not yet implemented
- **Widget tests:** Not yet implemented
- **Integration tests:** Not yet implemented
- **Manual testing:** `flutter run -d linux` and interact with UI

## Deployment Considerations

### Production Deployment (Tablet)
**Target:** Linux tablet device
**Approach:** Create launcher script that starts both services

Example launcher:
```bash
#!/bin/bash
# Start API in background
cd /path/to/weighit_api
source venv/bin/activate
python main.py &
API_PID=$!

# Wait for API to be ready
sleep 2

# Start Flutter app
cd /path/to/weighit_app
flutter run -d linux --release

# Cleanup on exit
kill $API_PID
```

### Build for Production
```bash
# Flutter release build
cd weighit_app
flutter build linux --release
# Binary at: build/linux/x64/release/bundle/
```

### Security Notes
- API uses CORS with `allow_origins=["*"]` - **restrict in production**
- No authentication currently implemented
- Localhost-only binding (127.0.0.1) prevents external access
- Consider adding API key or token for production

## Common Issues and Solutions

### Scale Not Detected
**Symptoms:** API logs "⚠ Warning: Could not initialize scale"
**Solutions:**
1. Check USB connection
2. Verify scale permissions: `ls -l /dev/hidraw*`
3. May need udev rules for non-root access
4. API gracefully continues with mock data

### Import Error: Cannot find weighit package
**Cause:** WEIGHIT_PATH incorrect or weighit not installed
**Solution:**
1. Verify path: `ls /home/justin/code/weighit/src/weigh`
2. Set environment variable: `export WEIGHIT_PATH=/correct/path`
3. Check that weighit has `__init__.py` files

### Flutter app can't connect to API
**Symptoms:** Connection refused errors
**Solutions:**
1. Verify API is running: `curl http://127.0.0.1:8000`
2. Check firewall/localhost restrictions
3. Verify baseUrl in `api_service.dart` matches API host:port

### CORS Errors
**Cause:** Browser security (shouldn't affect desktop Flutter)
**Solution:** CORS middleware already configured in main.py

## Future Development Areas

### Planned Features (from README)
1. Complete Flutter UI implementation
2. State management with Provider
3. Main app screens (logging, history, totals)
4. Packaging for tablet deployment

### Potential Enhancements
- [ ] Authentication/authorization
- [ ] WebSocket for real-time scale updates (instead of polling)
- [ ] Offline mode with sync
- [ ] Data export functionality
- [ ] Multi-language support
- [ ] Automated tests (pytest for API, flutter test for app)
- [ ] Docker containerization
- [ ] Configuration UI for sources/types
- [ ] Reports and analytics

## AI Assistant Guidelines

When working on this codebase:

1. **Read Before Modifying:** Always read existing code before making changes
2. **Respect Architecture:** Keep UI and API separate - no direct hardware access from Flutter
3. **Don't Over-Engineer:** Make only requested changes, avoid unnecessary abstractions
4. **Test Incrementally:** Verify API changes via `/docs` before updating Flutter code
5. **Check Scale Availability:** Always handle cases where scale may be unavailable
6. **Maintain Compatibility:** Don't break existing API contracts without updating Flutter client
7. **Use Type Safety:** Leverage Pydantic and Dart type systems
8. **Document Public APIs:** Keep API documentation accurate
9. **Avoid Secrets:** Never commit .env files or credentials
10. **Follow Conventions:** Match existing code style and patterns

### When Adding Features
1. Determine if change is backend, frontend, or both
2. Start with API endpoint if backend change needed
3. Test endpoint in isolation
4. Update Flutter client
5. Consider error cases and edge conditions
6. Update relevant README files if user-facing

### When Debugging
1. Check API logs first (terminal 1)
2. Test API directly with curl or /docs
3. Then check Flutter console (terminal 2)
4. Verify request/response payloads match expected structure
5. Check for null/undefined values in optional fields

## Quick Reference

### Start Development
```bash
# Terminal 1
cd weighit_api && python main.py

# Terminal 2
cd weighit_app && flutter run -d linux
```

### Key URLs
- API Health: http://127.0.0.1:8000
- API Docs: http://127.0.0.1:8000/docs
- API Redoc: http://127.0.0.1:8000/redoc

### Important Paths
- Original weighit: `/home/justin/code/weighit/src`
- Database: Default from weighit config (~/weighit/weigh.db typically)
- Project root: `/home/user/weighit_flutter` (current workspace)

### Git Branch
- Current: `claude/claude-md-mijjztgg1iyvrwci-016zkF65jm5zRyeDLWYpd15z`
- Push command: `git push -u origin claude/claude-md-mijjztgg1iyvrwci-016zkF65jm5zRyeDLWYpd15z`

---

**Last Updated:** 2025-11-29
**Project Status:** Initial setup complete, Flutter UI not yet implemented
**Next Steps:** Build Flutter UI screens, implement state management, package for deployment
