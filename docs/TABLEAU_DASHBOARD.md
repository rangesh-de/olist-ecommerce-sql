# Building the sales dashboard in Tableau Public

Time: about 3–4 hours the first time. Every calculated field below can be copied and pasted.

## 0. Before you start

1. Run the pipeline: `docker compose up -d` → `python scripts/load_data.py` → `python scripts/export_for_tableau.py`
2. Install **Tableau Public** (free, works on Mac): https://public.tableau.com/app/discover → Create → Download.
3. Keep `dashboard/kpi_check.md` open. Your KPI tiles must match it.

## 1. Connect the data

1. Open Tableau Public → **Text file** → `dashboard/data/orders.csv`.
2. Drag `order_items.csv` onto the canvas next to it. Tableau creates a **relationship**. Make sure it joins on `order_id = order_id`.
   - Use a relationship (the "noodle"), not a join. A join would repeat each order once per item, inflating revenue. Relationships keep each table at its own grain.
3. Fix data types: click the type icon above each column.
   - `purchase_date` → Date
   - `state_name` → Geographic role → **State/Province**
   - `country` → Geographic role → **Country/Region**
4. **Data source filter** (top right, Filters → Add): `is_valid_sale` = True. This removes canceled orders everywhere.
5. Add a second data source filter: `purchase_date` from **2017-01-01 to 2018-08-31**. Months outside this range are incomplete and would show fake drops.

## 2. Calculated fields

Analysis → Create Calculated Field. Use these names exactly.

```
Revenue
SUM([Order Value])

Orders
COUNTD([Order Id])

Avg Order Value
[Revenue] / [Orders]

Customers
COUNTD([Customer Unique Id])

Repeat Customer %
COUNTD(IF [Customer Type] = "Repeat customer" THEN [Customer Unique Id] END)
/ COUNTD([Customer Unique Id])

Avg Review
AVG([Review Score])

Late Delivery %
SUM(IF [Is Late] THEN 1 ELSE 0 END)
/ SUM(IF [Is Delivered] THEN 1 ELSE 0 END)

Item Revenue
SUM([Price])
```

Year-over-year on a like-for-like period. The data ends in August 2018, so compare Jan–Aug 2018 with Jan–Aug 2017. Comparing a full year with a partial year would make 2018 look like a decline.

```
Revenue Jan-Aug 2017
SUM(IF YEAR([Purchase Date]) = 2017 AND MONTH([Purchase Date]) <= 8 THEN [Order Value] END)

Revenue Jan-Aug 2018
SUM(IF YEAR([Purchase Date]) = 2018 AND MONTH([Purchase Date]) <= 8 THEN [Order Value] END)

Revenue YoY %
([Revenue Jan-Aug 2018] - [Revenue Jan-Aug 2017]) / [Revenue Jan-Aug 2017]
```

Region, for drill-down from region to state:

```
Region
CASE [State Code]
  WHEN "AC" THEN "North" WHEN "AP" THEN "North" WHEN "AM" THEN "North" WHEN "PA" THEN "North"
  WHEN "RO" THEN "North" WHEN "RR" THEN "North" WHEN "TO" THEN "North"
  WHEN "AL" THEN "Northeast" WHEN "BA" THEN "Northeast" WHEN "CE" THEN "Northeast"
  WHEN "MA" THEN "Northeast" WHEN "PB" THEN "Northeast" WHEN "PE" THEN "Northeast"
  WHEN "PI" THEN "Northeast" WHEN "RN" THEN "Northeast" WHEN "SE" THEN "Northeast"
  WHEN "DF" THEN "Central-West" WHEN "GO" THEN "Central-West"
  WHEN "MT" THEN "Central-West" WHEN "MS" THEN "Central-West"
  WHEN "ES" THEN "Southeast" WHEN "MG" THEN "Southeast" WHEN "RJ" THEN "Southeast" WHEN "SP" THEN "Southeast"
  WHEN "PR" THEN "South" WHEN "RS" THEN "South" WHEN "SC" THEN "South"
END
```

Then build the hierarchy: drag `State Name` onto `Region` in the Data pane and name it **Geography**. A **+** on Region in any chart now drills down to states.

Delivery bucket, for the experience chart:

```
Delivery Bucket
IF [Days Vs Estimate] <= 0 THEN "1. On time or early"
ELSEIF [Days Vs Estimate] <= 3 THEN "2. 1-3 days late"
ELSEIF [Days Vs Estimate] <= 7 THEN "3. 4-7 days late"
ELSE "4. 8+ days late"
END
```

## 3. Build the sheets

Create one worksheet for each item below. Name them as shown.

**KPI tiles (6 sheets: "KPI Revenue", "KPI Orders", and so on).** One measure each: Revenue, Orders, Avg Order Value, Customers, Avg Review, Late Delivery %. Drag the measure onto **Text**, make it large (28pt+), and put a small label above it. Format Revenue as currency with no decimals, and the percentages as % with one decimal. For the Revenue tile, also show `Revenue YoY %` underneath as "+X% vs Jan–Aug 2017".

**Monthly trend.** Columns: `MONTH(Purchase Date)`, continuous (green pill). Rows: `Revenue` as bars, then `Orders` on a second axis as a line (right-click the second pill → Dual Axis). The year → quarter → month hierarchy works as a date drill-down automatically.

**Revenue by state map.** Double-click `State Name`. Tableau draws Brazil. Drag `Revenue` onto **Color**, and `Orders` and `Avg Order Value` onto **Tooltip**. If any state shows as unrecognized: Map → Edit Locations → set Country to Brazil.

**Revenue by region (drill-down).** Rows: the `Geography` hierarchy. Columns: `Revenue`. Sort descending. Click **+** on Region to expand to states.

**Top 10 categories.** Rows: `Category`. Columns: `Item Revenue`. Sort descending. Drag `Category` to Filters → Top → By field → Top 10 by Item Revenue.

**Late delivery vs review.** Columns: `Delivery Bucket`. Rows: `Avg Review`. Add `Orders` to Label. Filter `Is Delivered` = True. This chart usually tells the strongest story.

**New vs repeat customers.** Columns: `Customer Type`. Rows: `Revenue`. Shows how dependent the business is on first-time buyers.

## 4. Assemble the dashboard

New Dashboard → Size: **Fixed, 1200 × 900** (renders well on Tableau Public).

```
┌──────────────────────────────────────────────────────────────────┐
│ Olist Sales Performance 2017–2018        [Date] [Region] [Category]│
├─────────┬─────────┬─────────┬─────────┬─────────┬─────────────────┤
│ Revenue │ Orders  │  AOV    │Customers│Avg rev. │ Late delivery % │
├─────────┴─────────┴─────────┴─────┬───┴─────────┴─────────────────┤
│ Monthly revenue & orders          │ Revenue by state (map)         │
├───────────────────────────────────┼────────────────────────────────┤
│ Top 10 categories                 │ Late delivery vs review score  │
├───────────────────────────────────┼────────────────────────────────┤
│ Revenue by region (drill-down)    │ New vs repeat customers        │
└───────────────────────────────────┴────────────────────────────────┘
```

1. Drag a **Horizontal** container to the top for the title and filters, then a horizontal container for the 6 KPI tiles. Drag the other sheets into a grid below.
2. Filters: on the trend chart, click the down arrow → Filters → `Purchase Date`, `Region`, `Category` → Apply to Worksheets → **All using this data source**.
3. **Click-to-filter:** Dashboard → Actions → Add Action → Filter. Source: the map. Target: all sheets. Run on: Select. Clicking a state now filters the whole dashboard. Mention this in interviews.
4. Formatting: use one main color for every chart (for example `#2B6CB0`) and orange only for the "late" story. Remove gridlines (Format → Lines). Give every chart a title that states the takeaway, for example "Orders arriving 8+ days late average under 2 stars".

## 5. Check, publish, share

1. Clear all filters and compare every KPI tile with `dashboard/kpi_check.md`. If a number differs, the usual causes are: the data source filter is missing, a join was used instead of a relationship, or `SUM` was used where `COUNTD` was needed.
2. File → **Save to Tableau Public** (sign in or create a free profile). Choose a clear name: "Olist E-commerce Sales Performance".
3. On Tableau Public, open the viz → copy the link.
4. Take a screenshot, save it as `dashboard/screenshot.png`, and add the link and screenshot to the README (the section is ready).

## Interview talking points

- **Relationships vs joins.** Orders and items have different grains. A join would duplicate order revenue for multi-item orders. Relationships aggregate each table at its own level.
- **Like-for-like YoY.** 2018 data stops in August, so I compared Jan–Aug against Jan–Aug.
- **Validated against SQL.** I checked the dashboard's KPIs against values computed in PostgreSQL before publishing.
- **Business framing.** Every chart title is a takeaway, not a label.
