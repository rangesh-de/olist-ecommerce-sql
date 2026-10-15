"""
Export dashboard-ready CSVs for Tableau Public, plus the KPI values the
dashboard should show, so you can check your Tableau numbers are right.

Run after load_data.py:
    python scripts/export_for_tableau.py

Writes:
    dashboard/data/orders.csv        one row per order
    dashboard/data/order_items.csv   one row per item
    dashboard/kpi_check.md           expected KPI values
"""
import csv
from pathlib import Path

from db import get_connection

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "dashboard" / "data"

KPI_SQL = """
SELECT
    ROUND(SUM(order_value), 2)                                        AS revenue,
    COUNT(*)                                                          AS orders,
    ROUND(SUM(order_value) / COUNT(*), 2)                             AS avg_order_value,
    COUNT(DISTINCT customer_unique_id)                                AS customers,
    ROUND(100.0 * COUNT(DISTINCT customer_unique_id) FILTER (WHERE customer_type = 'Repeat customer')
          / COUNT(DISTINCT customer_unique_id), 2)                    AS repeat_customer_pct,
    ROUND(AVG(review_score), 2)                                       AS avg_review,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_late) / NULLIF(COUNT(*) FILTER (WHERE is_delivered), 0), 1)
                                                                      AS late_delivery_pct
FROM olist.dash_orders
WHERE is_valid_sale AND order_value IS NOT NULL
"""


def export(cur, view, path):
    cur.execute(f"SELECT * FROM olist.{view}")
    cols = [d[0] for d in cur.description]
    rows = cur.fetchall()
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(cols)
        writer.writerows(rows)
    print(f"  {path.relative_to(ROOT)}  {len(rows):,} rows")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute((ROOT / "sql" / "04_dashboard_views.sql").read_text(encoding="utf-8"))
            conn.commit()
            print("Exporting")
            export(cur, "dash_orders", OUT / "orders.csv")
            export(cur, "dash_order_items", OUT / "order_items.csv")

            cur.execute(KPI_SQL)
            cols = [d[0] for d in cur.description]
            values = cur.fetchone()
    finally:
        conn.close()

    lines = ["# Expected KPI values\n",
             "Valid sales only (canceled and unavailable orders excluded), whole period, no filters.",
             "Your Tableau KPI tiles should show these numbers with all filters cleared.\n"]
    lines += [f"- **{c}**: {v}" for c, v in zip(cols, values)]
    (ROOT / "dashboard" / "kpi_check.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\nExpected KPIs (also saved to dashboard/kpi_check.md):")
    for c, v in zip(cols, values):
        print(f"  {c:<22} {v}")


if __name__ == "__main__":
    main()
