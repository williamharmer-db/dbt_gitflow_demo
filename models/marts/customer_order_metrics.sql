{{
    config(
        materialized='table',
        tags=['metrics', 'daily']
    )
}}

-- Customer order metrics from bakehouse catalog
-- Demonstrates: Building on existing models to create business metrics

with customers as (
    select * from {{ ref('dim_customers') }}
),

orders as (
    select * from {{ ref('fct_orders') }}
),

customer_order_summary as (
    select
        o.customer_id,
        count(*) as total_orders,
        sum(o.order_total) as lifetime_value,
        avg(o.order_total) as avg_order_value,
        min(o.order_date) as first_order_date,
        max(o.order_date) as last_order_date,
        count(distinct date(o.order_date)) as active_days
    from orders o
    group by o.customer_id
)

select
    c.customer_id,
    c.customer_name,
    c.email,
    c.created_date as customer_created_date,
    coalesce(s.total_orders, 0) as total_orders,
    coalesce(s.lifetime_value, 0) as lifetime_value,
    coalesce(s.avg_order_value, 0) as avg_order_value,
    coalesce(s.active_days, 0) as active_days,
    s.first_order_date,
    s.last_order_date,
    case 
        when s.total_orders >= 10 then 'vip'
        when s.total_orders >= 5 then 'loyal'
        when s.total_orders >= 1 then 'regular'
        else 'inactive'
    end as customer_segment,
    current_timestamp() as dbt_updated_at
from customers c
left join customer_order_summary s on c.customer_id = s.customer_id

