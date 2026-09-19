# sql-customer-segmentation-rfm

Customer segmentation in SQL using the RFM model (Recency, Frequency, Monetary) on the Snowflake TPC-H sample dataset.

The analysis scores 99,996 customers into quintiles on each dimension, groups them into named segments, and tests whether the resulting patterns are real.

---

## Dataset

`SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` — the `CUSTOMER`, `ORDERS` and `NATION` tables.
Orders run from 1992 to 1998. Recency is anchored to the latest order date in the data rather than to the current date, so results do not drift over time.

## Approach

| Dimension | Metric | Sort direction |
|---|---|---|
| Recency | Days since last order | Descending, so the most recent buyers score 5 |
| Frequency | Distinct order count | Ascending, so the most frequent score 5 |
| Monetary | Average order value | Ascending, so the highest per-order spend scores 5 |

Scores are assigned with `NTILE(5)`. Every score carries `customer_id` as a secondary sort key — without it, customers holding identical values are split arbitrarily across quintile boundaries and the segment counts change between runs.

Scores are then combined into segments with a `CASE` expression running from most specific to most general.

## Results

| Segment | Customers | % of customers | % of revenue | Revenue per customer |
|---|---|---|---|---|
| At risk | 31,543 | 31.54% | 29.54% | 2,124,595 |
| Loyal | 21,367 | 21.37% | 25.73% | 2,731,975 |
| Need Attention | 13,263 | 13.26% | 16.98% | 2,904,770 |
| Champions | 8,136 | 8.14% | 13.36% | 3,725,194 |
| Potential Loyalist | 10,495 | 10.50% | 6.52% | 1,408,536 |
| Lost | 8,456 | 8.46% | 3.78% | 1,013,203 |
| Others | 6,736 | 6.74% | 4.08% | 1,373,919 |

Champions hold 8.14% of customers and 13.36% of revenue — about 1.6× their weight. Revenue per customer runs from 3.73M down to 1.01M, a spread of roughly 3.7×.

The largest single revenue block is **At risk**: 29.54% of revenue at over 2.1M per customer. These are dormant high-value customers rather than low-value ones, which makes them the strongest candidate for a reactivation campaign.

## Why average order value

Monetary was originally scored on total spend. Two correlation checks showed why that was a poor choice on this dataset:

```sql
select corr(frequency_orders, monetary_value)  as f_m_correlation,   -- 0.941
       corr(frequency_orders, avg_order_value) as f_aov_correlation  -- -0.008
from scored_rfm;
```

Total spend correlates with order count at **0.94**, so Frequency and Monetary were measuring nearly the same thing and the model was effectively RF rather than RFM. Average order value correlates with frequency at **−0.008**, meaning it carries information that total spend was burying.

The effect was measurable. With Monetary on total spend, `Champions` held about 19,500 customers (19.5%) — far above the ~6% that three independent quintile filters should select. After switching to average order value, `Champions` fell to 8,136 (8.14%), and the top five customers by RFM score rose from around 3.19M in total spend each to between 5.87M and 6.06M. The model is now selecting customers who both order often and spend well per order, instead of selecting the same "orders often" group twice.

## Geographic analysis: a non-result

Champion rates across the 25 TPC-H nations range from 9.11% (Algeria) down to 7.35% (Kenya) — a spread of 1.76 percentage points.

With approximately 4,000 customers per nation and an overall rate of 8.14%, one standard deviation is about 0.43 points. The expected gap between the highest and lowest of 25 groups is around 1.7 points from random variation alone. The observed spread is 1.76.

The national ranking is indistinguishable from chance. No nation shows a genuine difference in customer value.

An earlier version of this analysis ranked nations by raw Champion count and reported Romania first. By rate, Romania is 24th of 25. The count ranking was measuring nation size, not customer behaviour — France has the most customers of any nation (4,149) and ranks 13th by rate.

## Bugs found and fixed

Three problems in the first version, none of which raised an error — each silently produced wrong answers.

**1. Inverted Frequency and Monetary scores.**
`NTILE` assigns bucket 1 to whatever sorts first, so `order by frequency_orders desc` gave the *most* frequent customers the *worst* score. `Champions` was selecting customers who bought recently, rarely, and cheaply. The symptom was visible in the output: Champions held 8.96% of customers but only 5.21% of revenue — under-indexing, when the segment is defined to be the best.

**2. Unreachable `Lost` segment.**
`when r_score <= 2 then 'At risk'` sat above `when r_score <= 1 and f_score <= 1 then 'Lost'`. Since `CASE` returns the first match, every potential `Lost` row was caught by `At risk` first and the segment never appeared in the output at all.

**3. Non-deterministic quintile boundaries.**
`NTILE` splits rows into equal-sized buckets regardless of ties. Thousands of customers share the same `recency_days` value, and those sitting on a bucket boundary were assigned differently on each run — segment counts shifted by a few dozen customers every time the query executed. Adding `customer_id` as a secondary sort key makes the assignment reproducible.

## Validation

Three checks that catch the problems above:

```sql
-- Does each score point the right way?
-- avg_recency must FALL as r_score rises.
-- avg_orders and avg_spend must RISE as f_score / m_score rise.
select r_score,
       count(*)                        as customers,
       round(avg(recency_days), 1)     as avg_recency,
       round(avg(frequency_orders), 2) as avg_orders,
       round(avg(monetary_value), 0)   as avg_spend
from scored_rfm
group by r_score
order by r_score;

-- Is every segment reachable?
-- A label missing here is dead code, not an empty group.
select rfm_segment, count(*) as customers
from segmented_rfm
group by rfm_segment
order by customers desc;

-- How many customers never ordered at all?
select count(*) as never_ordered
from snowflake_sample_data.tpch_sf1.customer c
where not exists (
  select 1 from snowflake_sample_data.tpch_sf1.orders o
  where o.o_custkey = c.c_custkey
);
```

Running the segmentation twice and comparing counts is the check for problem 3. Disable the result cache first with `alter session set use_cached_result = false;`, or Snowflake may return the previous answer without re-executing.

## Limitations

- **TPC-H is synthetic.** Orders are generated pseudo-randomly, so average order value clusters tightly around 150,000 and the near-zero frequency/AOV correlation is a property of the generator rather than of customer behaviour. The method transfers to real data; these specific figures do not.
- **A third of customers are excluded.** 50,004 of TPC-H's 150,000 customers placed no orders. They have no recency and cannot be scored, so they sit outside every segment above. Arguably they are the most genuinely lost group in the dataset.
- **`rfm_score` sums the three dimensions**, so 5-1-5 and 3-4-4 both total 11 despite describing very different customers. It is a rough ranking, not a measure of value.
- **Quintiles are relative, not absolute.** `NTILE(5)` always produces five equal groups, whether or not the underlying values differ meaningfully. A score of 5 means "top fifth of this dataset", not "high" in any absolute sense.

## Files

| File | Contents |
|---|---|
| `sql-customer-segmentation-rfm.sql` | Segmentation model and exploration queries |
| `findings.pdf` | Written analysis and recommendations |

## Running it

Requires a Snowflake account with access to the shared `SNOWFLAKE_SAMPLE_DATA` database.

```sql
use database snowflake_sample_data;
use schema tpch_sf1;
```

Then run the CTE chain in the SQL file, appending one exploration query at a time.
