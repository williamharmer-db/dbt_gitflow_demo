{{
    config(
        materialized='table',
        tags=['daily']
    )
}}

-- Customer dimension built from bakehouse catalog
with customers as (
    select * from {{ ref('stg_bakehouse_customers') }}
)

select
    customer_id,
    customer_name,
    email,
    created_date,
    updated_date,
    current_timestamp() as dbt_updated_at
from customers

