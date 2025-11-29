"""
Logger Core Module

Business logic for weighit application.
"""

import sqlite3
from typing import Optional, Dict, List, Any
from datetime import datetime, date
from . import db


# Default data - can be customized via database
DEFAULT_SOURCES = {
    "NFCC": "North Fayette Community Council",
    "SHOAF": "Shoaf Food Bank",
    "GBFB": "Greater Boston Food Bank",
    "ACFB": "Allegheny County Food Bank",
    "Other": "Other Source"
}

DEFAULT_TYPES = {
    "Produce": {"requires_temp": False, "sort_order": 1},
    "Dairy": {"requires_temp": True, "sort_order": 2},
    "Meat": {"requires_temp": True, "sort_order": 3},
    "Frozen": {"requires_temp": True, "sort_order": 4},
    "Bread": {"requires_temp": False, "sort_order": 5},
    "Canned": {"requires_temp": False, "sort_order": 6},
    "Dry Goods": {"requires_temp": False, "sort_order": 7},
    "Other": {"requires_temp": False, "sort_order": 8},
}


def get_sources_dict() -> Dict[str, str]:
    """Get dictionary of donation sources"""
    try:
        conn = db.get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT name FROM sources WHERE is_active = 1 ORDER BY name")
        sources = {row[0]: row[0] for row in cursor.fetchall()}
        conn.close()

        if not sources:
            # No sources in DB, use defaults
            return DEFAULT_SOURCES
        return sources
    except Exception as e:
        print(f"Error getting sources from DB: {e}, using defaults")
        return DEFAULT_SOURCES


def get_types_dict() -> Dict[str, Dict[str, Any]]:
    """Get dictionary of food types with metadata"""
    try:
        conn = db.get_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT name, requires_temp, sort_order
            FROM food_types
            WHERE is_active = 1
            ORDER BY sort_order
        """)

        types = {}
        for row in cursor.fetchall():
            types[row[0]] = {
                "requires_temp": bool(row[1]),
                "sort_order": row[2]
            }
        conn.close()

        if not types:
            # No types in DB, use defaults
            return DEFAULT_TYPES
        return types
    except Exception as e:
        print(f"Error getting types from DB: {e}, using defaults")
        return DEFAULT_TYPES


def log_entry(
    weight_lb: float,
    source: str,
    type_: str,
    temp_pickup_f: Optional[float] = None,
    temp_dropoff_f: Optional[float] = None
) -> int:
    """
    Log a donation entry to the database.
    Returns the entry ID.
    """
    # Validate temperature requirements
    types = get_types_dict()
    if type_ in types and types[type_]["requires_temp"]:
        if temp_pickup_f is None or temp_dropoff_f is None:
            raise ValueError(f"{type_} requires pickup and dropoff temperatures")

    timestamp = datetime.now().isoformat()

    conn = db.get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        INSERT INTO entries (timestamp, source, type, weight_lb, temp_pickup_f, temp_dropoff_f)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (timestamp, source, type_, weight_lb, temp_pickup_f, temp_dropoff_f))

    entry_id = cursor.lastrowid

    # Clear redo stack when new entry is made
    cursor.execute("DELETE FROM undo_stack")

    conn.commit()
    conn.close()

    return entry_id


def totals_today_weight_per_type(source: Optional[str] = None) -> Dict[str, float]:
    """
    Get today's total weight by type.
    Optionally filter by source.
    """
    today = date.today().isoformat()

    conn = db.get_connection()
    cursor = conn.cursor()

    if source:
        cursor.execute("""
            SELECT type, SUM(weight_lb) as total
            FROM entries
            WHERE DATE(timestamp) = ? AND source = ? AND is_deleted = 0
            GROUP BY type
        """, (today, source))
    else:
        cursor.execute("""
            SELECT type, SUM(weight_lb) as total
            FROM entries
            WHERE DATE(timestamp) = ? AND is_deleted = 0
            GROUP BY type
        """, (today,))

    totals = {row[0]: row[1] for row in cursor.fetchall()}
    conn.close()

    return totals


def get_recent_entries(limit: int = 15, source: Optional[str] = None) -> List[Dict[str, Any]]:
    """Get recent donation entries"""
    conn = db.get_connection()
    cursor = conn.cursor()

    if source:
        cursor.execute("""
            SELECT id, timestamp, source, type, weight_lb, temp_pickup_f, temp_dropoff_f
            FROM entries
            WHERE is_deleted = 0 AND source = ?
            ORDER BY timestamp DESC
            LIMIT ?
        """, (source, limit))
    else:
        cursor.execute("""
            SELECT id, timestamp, source, type, weight_lb, temp_pickup_f, temp_dropoff_f
            FROM entries
            WHERE is_deleted = 0
            ORDER BY timestamp DESC
            LIMIT ?
        """, (limit,))

    entries = []
    for row in cursor.fetchall():
        entries.append({
            "id": row[0],
            "timestamp": row[1],
            "source": row[2],
            "type": row[3],
            "weight_lb": row[4],
            "temp_pickup_f": row[5],
            "temp_dropoff_f": row[6]
        })

    conn.close()
    return entries


def get_entries_filtered(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    source: Optional[str] = None
) -> List[Dict[str, Any]]:
    """Get entries with optional date range and source filters"""
    conn = db.get_connection()
    cursor = conn.cursor()

    query = "SELECT id, timestamp, source, type, weight_lb, temp_pickup_f, temp_dropoff_f FROM entries WHERE is_deleted = 0"
    params = []

    if start_date:
        query += " AND DATE(timestamp) >= ?"
        params.append(start_date)

    if end_date:
        query += " AND DATE(timestamp) <= ?"
        params.append(end_date)

    if source:
        query += " AND source = ?"
        params.append(source)

    query += " ORDER BY timestamp DESC"

    cursor.execute(query, params)

    entries = []
    for row in cursor.fetchall():
        entries.append({
            "id": row[0],
            "timestamp": row[1],
            "source": row[2],
            "type": row[3],
            "weight_lb": row[4],
            "temp_pickup_f": row[5],
            "temp_dropoff_f": row[6]
        })

    conn.close()
    return entries


def undo_last_entry() -> Optional[int]:
    """
    Undo the last entry (soft delete).
    Returns the entry ID that was undone, or None if nothing to undo.
    """
    conn = db.get_connection()
    cursor = conn.cursor()

    # Find the most recent non-deleted entry
    cursor.execute("""
        SELECT id FROM entries
        WHERE is_deleted = 0
        ORDER BY timestamp DESC
        LIMIT 1
    """)

    row = cursor.fetchone()
    if not row:
        conn.close()
        return None

    entry_id = row[0]

    # Soft delete the entry
    cursor.execute("UPDATE entries SET is_deleted = 1 WHERE id = ?", (entry_id,))

    # Add to undo stack
    cursor.execute("""
        INSERT INTO undo_stack (entry_id, operation, timestamp)
        VALUES (?, 'undo', ?)
    """, (entry_id, datetime.now().isoformat()))

    conn.commit()
    conn.close()

    return entry_id


def redo_last_entry() -> Optional[int]:
    """
    Redo the last undone entry (restore from soft delete).
    Returns the entry ID that was redone, or None if nothing to redo.
    """
    conn = db.get_connection()
    cursor = conn.cursor()

    # Get the most recent undo operation
    cursor.execute("""
        SELECT entry_id FROM undo_stack
        WHERE operation = 'undo'
        ORDER BY timestamp DESC
        LIMIT 1
    """)

    row = cursor.fetchone()
    if not row:
        conn.close()
        return None

    entry_id = row[0]

    # Restore the entry
    cursor.execute("UPDATE entries SET is_deleted = 0 WHERE id = ?", (entry_id,))

    # Remove from undo stack
    cursor.execute("DELETE FROM undo_stack WHERE entry_id = ? AND operation = 'undo'", (entry_id,))

    conn.commit()
    conn.close()

    return entry_id


# Initialize default data if database is empty
def init_default_data():
    """Populate database with default sources and types if empty"""
    try:
        conn = db.get_connection()
        cursor = conn.cursor()

        # Add default sources if none exist
        cursor.execute("SELECT COUNT(*) FROM sources")
        if cursor.fetchone()[0] == 0:
            for source_name in DEFAULT_SOURCES.keys():
                cursor.execute("INSERT OR IGNORE INTO sources (name) VALUES (?)", (source_name,))

        # Add default food types if none exist
        cursor.execute("SELECT COUNT(*) FROM food_types")
        if cursor.fetchone()[0] == 0:
            for type_name, attrs in DEFAULT_TYPES.items():
                cursor.execute("""
                    INSERT OR IGNORE INTO food_types (name, requires_temp, sort_order)
                    VALUES (?, ?, ?)
                """, (type_name, 1 if attrs["requires_temp"] else 0, attrs["sort_order"]))

        conn.commit()
        conn.close()
    except Exception as e:
        print(f"Note: Could not initialize default data: {e}")


# Initialize on import
try:
    init_default_data()
except:
    pass  # Database might not exist yet, that's okay
