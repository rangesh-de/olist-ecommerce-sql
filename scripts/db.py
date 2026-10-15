"""Shared database connection settings (override with environment variables)."""
import os

import psycopg2


def get_connection():
    return psycopg2.connect(
        host=os.getenv("PGHOST", "localhost"),
        port=os.getenv("PGPORT", "5432"),
        user=os.getenv("PGUSER", "olist"),
        password=os.getenv("PGPASSWORD", "olist"),
        dbname=os.getenv("PGDATABASE", "olist"),
    )
