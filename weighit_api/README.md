# WeighIt API Service

REST API wrapper for the WeighIt Python backend.

## Setup

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Configure environment (optional):
   ```bash
   cp .env.example .env
   # Edit .env if needed
   ```

3. Run the service:
   ```bash
   python main.py
   ```

   Or with uvicorn directly:
   ```bash
   uvicorn main:app --reload --host 127.0.0.1 --port 8000
   ```

## API Documentation

Once running, visit:
- Interactive docs: http://127.0.0.1:8000/docs
- Alternative docs: http://127.0.0.1:8000/redoc

## Endpoints

- `GET /` - Health check
- `GET /scale/reading` - Current scale reading
- `GET /scale/stable` - Wait for stable reading
- `GET /sources` - List donation sources
- `GET /types` - List food types
- `POST /log` - Log donation entry
- `GET /totals/today` - Today's totals
- `GET /history/recent` - Recent entries
- `POST /undo` - Undo last entry
- `POST /redo` - Redo last undo
