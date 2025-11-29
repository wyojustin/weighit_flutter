"""
Database Module

Provides database access for weighit application using SQLite.
"""

import sqlite3
import os
from typing import Optional, List, Dict, Any
from datetime import datetime
from pathlib import Path

# Default database path - can be overridden
DB_PATH = os.path.join(os.path.dirname(__file__), '..', 'weighit.db')


def get_connection() -> sqlite3.Connection:
    """Get a database connection"""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row  # Enable column access by name
    return conn


def init_database():
    """Initialize database schema if not exists"""
    conn = get_connection()
    cursor = conn.cursor()

    # Create entries table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            source TEXT NOT NULL,
            type TEXT NOT NULL,
            weight_lb REAL NOT NULL,
            temp_pickup_f REAL,
            temp_dropoff_f REAL,
            is_deleted INTEGER DEFAULT 0
        )
    ''')

    # Create sources table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS sources (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            is_active INTEGER DEFAULT 1
        )
    ''')

    # Create food types table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS food_types (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            requires_temp INTEGER DEFAULT 0,
            sort_order INTEGER DEFAULT 0,
            is_active INTEGER DEFAULT 1
        )
    ''')

    # Create undo/redo stack table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS undo_stack (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entry_id INTEGER NOT NULL,
            operation TEXT NOT NULL,
            timestamp TEXT NOT NULL
        )
    ''')

    conn.commit()
    conn.close()


# Initialize database on import
if os.path.exists(DB_PATH):
    # Database exists, ensure schema is up to date
    init_database()
