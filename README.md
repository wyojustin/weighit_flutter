# WeighIt Flutter

Flutter-based UI for the WeighIt food pantry scale application.

## Architecture

This project consists of two components:

1. **weighit_api/** - Python FastAPI service that wraps the existing weighit backend
2. **weighit_app/** - Flutter desktop application (UI)

The Flutter app communicates with the Python API service via REST API calls over localhost.

## Benefits

- ✅ **Zero modification** to existing weighit Python code
- ✅ **Independent development** - work on Flutter without affecting Streamlit version
- ✅ **Shared backend** - both apps use same database and scale driver
- ✅ **Native performance** - Flutter provides better touch support and performance
- ✅ **Clean separation** - UI and backend are properly decoupled

## Setup

### 1. Python API Service

```bash
cd weighit_api
pip install -r requirements.txt
python main.py
```

The API will be available at http://127.0.0.1:8000

API documentation: http://127.0.0.1:8000/docs

### 2. Flutter Application

First, initialize the Flutter app (one-time setup):

```bash
cd weighit_app
flutter create .
```

Add dependencies to `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  provider: ^6.1.0
```

Then run:
```bash
flutter pub get
flutter run -d linux
```

## Running Both Together

**Terminal 1 - Start API:**
```bash
cd weighit_api
python main.py
```

**Terminal 2 - Start Flutter:**
```bash
cd weighit_app
flutter run -d linux
```

## Deployment

For production deployment on the tablet, you can create a launcher script that starts both services.

## Development

The API service imports from the original weighit package at `/home/justin/code/weighit/src`. This path can be configured via the `WEIGHIT_PATH` environment variable.

## Next Steps

1. Test the API service locally
2. Build the Flutter UI components
3. Implement the main app screens
4. Package for deployment on tablet
