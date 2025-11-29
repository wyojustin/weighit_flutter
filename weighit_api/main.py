#!/usr/bin/env python3
"""
WeighIt FastAPI Service

Thin REST API wrapper around the existing weighit Python backend.
Imports from the original weighit package without modification.
"""
import sys
import os
from pathlib import Path
from typing import Optional
from datetime import datetime

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn

# Add the original weighit package to path
WEIGHIT_PATH = os.getenv('WEIGHIT_PATH', '/home/justin/code/weighit/src')
sys.path.insert(0, WEIGHIT_PATH)

# Import from existing weighit package
from weigh.scale_backend import DymoHIDScale, ScaleReading
from weigh import logger_core, db

# Configure database path
# Use local weighit.db if not specified
db_path = os.getenv('DB_PATH', os.path.abspath('weighit.db'))
db.DB_PATH = db_path
print(f"✓ Using database: {db.DB_PATH}")

# Initialize FastAPI
app = FastAPI(title="WeighIt API", version="1.0.0")

# Enable CORS for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize scale (singleton)
scale: Optional[DymoHIDScale] = None

from mock_scale import MockScale

@app.on_event("startup")
async def startup_event():
    """Initialize scale connection on startup"""
    global scale
    
    if os.getenv('USE_MOCK_SCALE', '').lower() == 'true':
        scale = MockScale()
        print("✓ Mock Scale initialized")
        return

    try:
        scale = DymoHIDScale()
        print("✓ Scale initialized successfully")
    except Exception as e:
        print(f"⚠ Warning: Could not initialize scale: {e}")
        scale = None

@app.on_event("shutdown")
async def shutdown_event():
    """Close scale connection on shutdown"""
    global scale
    if scale:
        scale.close()

# Pydantic models for request/response
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

# API Endpoints

@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "service": "WeighIt API",
        "status": "running",
        "scale_connected": scale is not None
    }

@app.get("/scale/reading", response_model=ScaleReadingResponse)
async def get_scale_reading():
    """Get current scale reading"""
    if not scale:
        return ScaleReadingResponse(
            value=0.0,
            unit="lb",
            is_stable=False,
            available=False
        )
    
    try:
        reading = scale.get_latest()
        if not reading:
            return ScaleReadingResponse(
                value=0.0,
                unit="lb",
                is_stable=False,
                available=False
            )
        
        return ScaleReadingResponse(
            value=reading.value,
            unit=reading.unit,
            is_stable=reading.is_stable,
            available=True
        )
    except Exception as e:
        print(f"Error reading scale: {e}")
        return ScaleReadingResponse(
            value=0.0,
            unit="lb",
            is_stable=False,
            available=False
        )

@app.get("/scale/stable")
async def get_stable_reading(timeout: float = 2.0):
    """Wait for stable reading (for LOG button)"""
    if not scale:
        raise HTTPException(status_code=503, detail="Scale not available")
    
    reading = scale.read_stable_weight(timeout_s=timeout)
    if not reading:
        raise HTTPException(status_code=408, detail="Timeout waiting for stable reading")
    
    return {
        "value": reading.value,
        "unit": reading.unit,
        "is_stable": reading.is_stable
    }

@app.get("/sources")
async def get_sources():
    """Get list of donation sources"""
    sources = logger_core.get_sources_dict()
    return {"sources": list(sources.keys())}

@app.get("/types")
async def get_types():
    """Get list of food types with metadata"""
    types = logger_core.get_types_dict()
    return {
        "types": [
            {
                "name": name,
                "requires_temp": info["requires_temp"],
                "sort_order": info["sort_order"]
            }
            for name, info in types.items()
        ]
    }

@app.post("/log")
async def log_entry(entry: LogEntryRequest):
    """Log a donation entry"""
    try:
        logger_core.log_entry(
            weight_lb=entry.weight_lb,
            source=entry.source,
            type_=entry.type,
            temp_pickup_f=entry.temp_pickup_f,
            temp_dropoff_f=entry.temp_dropoff_f
        )
        return {"status": "success", "message": "Entry logged"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/totals/today")
async def get_today_totals(source: Optional[str] = None):
    """Get today's totals by type"""
    totals = logger_core.totals_today_weight_per_type(source=source)
    total_weight = sum(totals.values())
    return {
        "totals_by_type": totals,
        "total_weight": total_weight,
        "date": datetime.now().date().isoformat()
    }

@app.get("/history/recent")
async def get_recent_history(limit: int = 15, source: Optional[str] = None):
    """Get recent donation entries"""
    entries = logger_core.get_recent_entries(limit=limit, source=source)
    return {"entries": entries}

@app.get("/reports/csv")
async def generate_csv_report(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    source: Optional[str] = None
):
    """Generate CSV report for date range and source"""
    from io import StringIO
    import csv
    from fastapi.responses import StreamingResponse
    
    # Get entries with filters
    entries = logger_core.get_entries_filtered(
        start_date=start_date,
        end_date=end_date,
        source=source
    )
    
    # Generate CSV
    output = StringIO()
    writer = csv.DictWriter(output, fieldnames=['id', 'timestamp', 'source', 'type', 'weight_lb', 'temp_pickup_f', 'temp_dropoff_f'])
    writer.writeheader()
    writer.writerows(entries)
    
    csv_content = output.getvalue()
    output.close()
    
    # Return as downloadable file
    return StreamingResponse(
        iter([csv_content]),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=weighit_report.csv"}
    )

@app.post("/reports/email")
async def email_report(
    recipient: Optional[str] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    source: Optional[str] = None
):
    """Email CSV report to recipient"""
    from io import StringIO
    import csv
    from email_reporter import send_report_email, load_email_config
    
    # Get entries with filters
    entries = logger_core.get_entries_filtered(
        start_date=start_date,
        end_date=end_date,
        source=source
    )
    
    # Generate CSV
    output = StringIO()
    writer = csv.DictWriter(output, fieldnames=['id', 'timestamp', 'source', 'type', 'weight_lb', 'temp_pickup_f', 'temp_dropoff_f'])
    writer.writeheader()
    writer.writerows(entries)
    csv_content = output.getvalue()
    output.close()
    
    # Get recipient
    if not recipient:
        config = load_email_config()
        recipient = config['default_recipient']
    
    # Create email body
    total_weight = sum(e.get('weight_lb', 0) for e in entries)
    body = f"""WeighIt Report
    
Date Range: {start_date or 'All'} to {end_date or 'All'}
Source: {source or 'All'}
Total Entries: {len(entries)}
Total Weight: {total_weight:.2f} lb

See attached CSV for details.
"""
    
    # Send email
    try:
        send_report_email(
            recipient=recipient,
            subject=f"WeighIt Report - {datetime.now().strftime('%Y-%m-%d')}",
            body=body,
            csv_data=csv_content
        )
        return {"status": "success", "recipient": recipient, "entries": len(entries)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to send email: {str(e)}")

@app.post("/undo")
async def undo_last():
    """Undo last entry"""
    entry_id = logger_core.undo_last_entry()
    if entry_id:
        return {"status": "success", "undone_id": entry_id}
    else:
        raise HTTPException(status_code=404, detail="No entry to undo")

@app.post("/redo")
async def redo_last():
    """Redo last undone entry"""
    entry_id = logger_core.redo_last_entry()
    if entry_id:
        return {"status": "success", "redone_id": entry_id}
    else:
        raise HTTPException(status_code=404, detail="No entry to redo")

if __name__ == "__main__":
    # Run with: python main.py
    uvicorn.run(app, host="127.0.0.1", port=8000)
