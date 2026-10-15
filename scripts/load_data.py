"""
Build the schema and bulk-load the 9 Olist CSVs into PostgreSQL.

Pattern used (common in real data engineering):
  1. COPY each CSV into a temporary staging table with the same columns but no keys.
  2. INSERT into the real table with ON CONFLICT DO NOTHING, so duplicate keys
     in the source are skipped and counted instead of crashing the load.

Usage:  python scripts/load_data.py            (expects CSVs in ./data)
        python scripts/load_data.py path/to/csvs
"""
import sys
import time
from pathlib import Path

from db import get_connection

ROOT = Path(__file__).resolve().parent.parent
SQL_DIR = ROOT / "sql"

# Load order matters: parent tables before the tables that reference them.
TABLES = [
    ("category_translation", "product_category_name_translation.csv"),
    ("customers",            "olist_customers_dataset.csv"),
    ("sellers",              "olist_sellers_dataset.csv"),
    ("products",             "olist_products_dataset.csv"),
    ("orders",               "olist_orders_dataset.csv"),
    ("order_items",          "olist_order_items_dataset.csv"),
    ("order_payments",       "olist_order_payments_dataset.csv"),
    ("order_reviews",        "olist_order_reviews_dataset.csv"),
    ("geolocation",          "olist_geolocation_dataset.csv"),
]


def run_sql_file(cur, path):
    print(f"Running {path.name}")
    cur.execute(path.read_text(encoding="utf-8"))


def load_table(cur, table, csv_path):
    staging = f"stg_{table}"
    cur.execute(f"CREATE TEMP TABLE {staging} (LIKE olist.{table}) ON COMMIT DROP")
    with open(csv_path, "r", encoding="utf-8-sig") as f:
        cur.copy_expert(
            f"COPY {staging} FROM STDIN WITH (FORMAT csv, HEADER true, NULL '')", f
        )
    cur.execute(f"SELECT COUNT(*) FROM {staging}")
    source_rows = cur.fetchone()[0]
    cur.execute(f"INSERT INTO olist.{table} SELECT * FROM {staging} ON CONFLICT DO NOTHING")
    loaded = cur.rowcount
    skipped = source_rows - loaded
    note = f"  ({skipped:,} duplicate keys skipped)" if skipped else ""
    print(f"  {table:<22} {loaded:>9,} rows{note}")


def main():
    data_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "data"
    missing = [f for _, f in TABLES if not (data_dir / f).exists()]
    if missing:
        sys.exit(f"Missing CSVs in {data_dir}:\n  " + "\n  ".join(missing)
                 + "\nDownload them from Kaggle first (see data/README.md).")

    start = time.time()
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            run_sql_file(cur, SQL_DIR / "01_schema.sql")
            print("Loading tables")
            for table, filename in TABLES:
                load_table(cur, table, data_dir / filename)
            run_sql_file(cur, SQL_DIR / "02_views.sql")
            cur.execute("ANALYZE")
        conn.commit()

        print("\nData quality checks")
        with conn.cursor() as cur:
            run_sql_file(cur, SQL_DIR / "03_data_quality_checks.sql")
            for check, result in cur.fetchall():
                print(f"  {check:<62} {result}")
    finally:
        conn.close()
    print(f"Done in {time.time() - start:.1f}s")


if __name__ == "__main__":
    main()
