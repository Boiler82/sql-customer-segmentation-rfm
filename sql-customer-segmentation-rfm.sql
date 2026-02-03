-- Part 1. Customer Segmentation (RFM)
-- Starting the query by setting the list of customers demographic that I will need for my analysis
with relevant_customers_details as (
  select
    c.c_custkey,
    c.c_name as customer_name,
    c.c_nationkey as customer_nationality,
    c.c_acctbal as account_balance,
    n.n_name as nation_name
  from
    snowflake_sample_data.tpch_sf1.customer as c
    inner join snowflake_sample_data.tpch_sf1.nation as n on c.c_nationkey = n.n_nationkey
),
-- Setting the aggregates that I will need for the RFM analysis
customers_aggregate as (
  select
    o.o_custkey,
    sum(o.o_totalprice) as total_revenue,
    round(avg(o.o_totalprice), 2) as avg_order_value,
    count(o.o_orderkey) as total_orders,
    max(o.o_orderdate) as last_order_date
  from
    snowflake_sample_data.tpch_sf1.orders as o
  group by
    o.o_custkey
),
-- Creating a reference date for the Recency segment
reference_date as (
  select
    max(o_orderdate) as ref_date -- 1998-08-03
  from
    snowflake_sample_data.tpch_sf1.orders
),
-- This is where the actual calculation take place
customers_rfm as (
  select
    o.o_custkey as customer_id,
    datediff('day',max(o.o_orderdate), -- Using DATEDIFF to calculate the customer's last transaction date
    (select
      ref_date
     from
      reference_date)
    ) as recency_days,
    count(distinct o.o_orderkey) as frequency_orders,
    sum(o.o_totalprice) as monetary_value
  from
    snowflake_sample_data.tpch_sf1.orders as o
  group by
    o.o_custkey
),
-- Combining all the data and left join the tables to be sure that all the customers matches from the left table
aggregate_rfm as (
  select
    crfm.customer_id,
    crfm.recency_days,
    crfm.frequency_orders,
    crfm.monetary_value,
    rcd.customer_name,
    rcd.nation_name,
    ca.total_revenue,
    ca.avg_order_value,
    ca.total_orders,
    ca.last_order_date
  from
    customers_rfm as crfm
  left join
    relevant_customers_details as rcd
      on crfm.customer_id = rcd.c_custkey
  left join
    customers_aggregate as ca
      on crfm.customer_id = ca.o_custkey
),
-- Using NTILE to create a customer's rank
scored_rfm as (
  select
    *,
    ntile(5) over(order by recency_days desc) as r_score,  
    ntile(5) over(order by frequency_orders desc) as f_score, 
    ntile(5) over(order by monetary_value desc) as m_score   
  from
   aggregate_rfm 
),
-- Using a CASE statement to transform labels into actionable groups
segmented_rfm as (
  select
    *,
    (r_score + f_score + m_score) as rfm_score,
    case
      when r_score >= 4 and f_score >= 4 and m_score >= 4 then 'Champions'
      when r_score >= 4 and f_score >= 3 then 'Loyal'
      when r_score >= 4 then 'Potential Loyalist'
      when r_score >= 3 and f_score >= 3 then 'Need Attention'
      when r_score <=2 then 'At risk'
      when r_score <= 1 and f_score <= 1 then 'Lost'
      else 'Others'
    end as rfm_segment
  from
    scored_rfm
)
-- Final statement
select
  *
from
  segmented_rfm
order by
  rfm_score desc
limit 10
;


-- Part 2. Segment Exploration
-- Substitute the following 4 options to the last statement of the query to obtain specific insights 

-- 1.
select
  rfm_segment,
  count(customer_id) AS customer_count,
  round(count(customer_id) * 100.0 / sum(count(customer_id)) over(), 2) as percentage_of_total -- Using this formula to calculate a percentage
from
  segmented_rfm
group by
  rfm_segment
order by
  customer_count desc
;

-- 2.
select
  rfm_segment,
  sum(total_revenue) as total_revenue_per_segment,
  round(sum(total_revenue) * 100.0 / sum(sum(total_revenue)) over(), 2) as percentage_of_total_revenue -- Using this formula to calculate a percentage
from
  segmented_rfm
group by
  rfm_segment
order by
  total_revenue_per_segment desc
;

-- 3.
select
  customer_id,
  customer_name,
  nation_name,
  rfm_segment,
  r_score,
  f_score,
  m_score,
  rfm_score,
  total_revenue
from
  segmented_rfm
order by
  rfm_score desc,    
  total_revenue desc   
limit 5
;

-- 4.
select
  nation_name,
  count(customer_id) as high_value_customer_count
from
  segmented_rfm
where
  rfm_segment = 'Champions'
group by
  nation_name
order by
  high_value_customer_count desc,
  nation_name asc
;

