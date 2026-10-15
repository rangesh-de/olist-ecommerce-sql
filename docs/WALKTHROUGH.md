# Query walkthrough

How each query works, the trap it avoids, and how to explain it in an interview. Open the SQL file next to this and run it step by step: run the first CTE on its own, look at the output, then add the next one.

## Foundations: schema and views

**Why a staging table in the loader?** COPY into a temp table with no keys, then `INSERT ... ON CONFLICT DO NOTHING` into the real table. If the source has a duplicate key, the load doesn't crash, and the script reports how many rows it skipped. That is a standard pattern in data engineering, and worth saying out loud in interviews.

**Why views?** `v_orders` defines "late", "delivered" and "order value" once. If ten queries each computed "late" their own way, they would disagree. Interview line: *"I put shared business logic in views so every metric has one definition."*

**Grain.** Always know what one row means. `orders` = one row per order. `order_items` = one row per item. `order_payments` = one row per payment part. Joining items to payments directly multiplies rows and inflates revenue. That's why `v_order_value` aggregates items to the order level first.

## Q1. Monthly revenue trend

- A CTE builds one row per month with orders and revenue.
- `LAG(revenue) OVER (ORDER BY purchase_month)` pulls the previous month's value onto the current row, so growth is `(this − last) / last`.
- **Trap:** the first and last months of the dataset are partial. Including them shows a fake crash at the end. The query keeps only Jan 2017 to Aug 2018.
- **Interview line:** "I used LAG for month-over-month growth and excluded partial months so the trend isn't distorted."

## Q2. Repeat customer rate

- Count orders per `customer_unique_id`, then count customers with more than one order.
- `COUNT(*) FILTER (WHERE ...)` is a cleaner PostgreSQL version of `SUM(CASE WHEN ... THEN 1 ELSE 0 END)`.
- **Trap:** `customer_id` is new for every order. Grouping by it gives a 0% repeat rate. This is the single most important detail in the dataset.
- **Interview line:** "Before measuring retention I checked what the customer key really represented."

## Q3. Cohort retention

- `MIN(purchase_month) OVER (PARTITION BY customer_unique_id)` tags every order with the customer's first month. That's their cohort.
- `AGE()` gives the gap between the order month and the cohort month, converted to a month number (0 = first month).
- Each `m1_pct`, `m2_pct` column counts customers who ordered in that month after joining, divided by cohort size.
- **Why stop at June 2018 cohorts:** later cohorts haven't had time to come back yet, so their retention would look falsely low.

## Q4. Late deliveries by state

- `is_late` is a boolean in the view, so `COUNT(*) FILTER (WHERE is_late)` counts late orders directly.
- `HAVING COUNT(*) >= 100` drops states with too few orders. A state with 5 orders and 2 late is 40% late, which is noise, not a finding.

## Q5. Late delivery vs review score

- `CASE` puts each delivered order into a bucket by how many days late it was.
- Compare average score and the share of 1–2 star reviews across buckets.
- **This is usually the headline finding**: it ties an operations problem (logistics) to a customer outcome (ratings).

## Q6. Top categories

- Joins items → orders (to drop canceled) → products → translation.
- `LEFT JOIN` to translation plus `COALESCE` keeps categories with no English name instead of silently dropping their revenue.
- `SUM(revenue) OVER ()` with an empty window is the grand total, so `revenue / total` is the share. Adding `ORDER BY revenue DESC` inside the window turns it into a running total, giving cumulative share.

## Q7. Seller Pareto (80/20)

- `NTILE(10)` splits sellers into 10 equal groups by revenue.
- `SUM(SUM(revenue)) OVER (...)` looks strange but is normal: the inner SUM is the GROUP BY aggregate, and the outer SUM is a window over those grouped rows.
- **Business meaning:** if the top 10% of sellers make most of the revenue, losing a few of them is a real risk.

## Q8. Seller scorecard

- `seller_orders` uses `DISTINCT` because one order can contain several items from the same seller. Without it, those orders would be double counted.
- Shows high-volume sellers (100+ delivered orders) with the lowest average reviews, and their late %, so you can see whether it's a shipping problem.

## Q9. Payment methods

- Payments can be split, for example a voucher plus a credit card. The CTE first rolls payments up to one row per order per payment type.
- `share_of_orders_pct` can add up to slightly more than 100%, because split-payment orders count under each method they used. Mention this if asked.

## Q10. Installments vs order value

- Buckets credit-card payments by number of installments.
- `PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ...)` is the median. Show it next to the average, because a few huge orders pull the average up.
- `ORDER BY MIN(payment_installments)` sorts the text buckets in numeric order instead of alphabetical.

## Q11. Freight burden by state

- `SUM(freight) / SUM(items)` is the ratio of sums. It weights big orders properly. `AVG(freight / items)` would let tiny orders with high relative shipping dominate.
- **Business meaning:** states where shipping is a big share of the basket are where free-shipping thresholds or regional warehouses would matter most.

## Q12. RFM segmentation

- Recency = days since last order, Frequency = number of orders, Monetary = total spend.
- `NTILE(5)` scores R and M from 1 to 5.
- Frequency is scored with fixed rules instead, because over 95% of customers buy once. NTILE would split identical customers into different scores at random.
- The "as of" date is the last date in the data, not today. Using today would make everyone look lost.

## Q13. Fulfillment bottlenecks

- Splits delivery time into stages: approval, seller handling, carrier transit.
- Filters out rows where timestamps run backwards (data entry errors), otherwise they produce negative durations.
- **Business meaning:** tells you whether to push sellers to ship faster or change carriers.

## Q14. Category satisfaction

- Compares each category's overall review score with its score on on-time orders only.
- If a category is still low when delivery was on time, the problem is likely the product or its listing, not logistics. This is a simple way to separate two causes.

## Q15. Peak shopping times

- `EXTRACT(ISODOW ...)` gives day number 1–7 (Monday = 1) for correct sorting. `TO_CHAR(..., 'Dy')` gives the readable name.
- `FILTER` turns hour ranges into columns, a simple pivot.

## Questions an interviewer might ask

- *Why PostgreSQL and not just pandas?* The data is relational with 9 tables. Modeling keys and constraints catches data problems at load time, and SQL is what the job uses.
- *How did you validate results?* Row counts after loading, checking that payment totals roughly match item + freight totals, and sanity checks on every rate (nothing above 100%, no negative durations).
- *What would you do next?* A Power BI dashboard on top of the views, and moving the transformations into dbt with tests.
