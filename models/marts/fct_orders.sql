{{
    config(
        materialized='incremental',
        unique_key='order_id',
        file_format='delta',
        incremental_strategy='merge'
    )
}}

-- Principle: Idempotency ("Running it twice shouldn't break it")
-- Principle: Immutability (Append logic preferred)

with orders as (
    select * from {{ ref('stg_bakehouse_orders') }}
)

select
    order_id,
    customer_id,
    order_date,
    order_status,
    order_total,
    current_timestamp() as dbt_loaded_at
from orders

{% if is_incremental() %}
  -- State Awareness: Only process new data
  where order_date > (select max(order_date) from {{ this }})
{% endif %}

