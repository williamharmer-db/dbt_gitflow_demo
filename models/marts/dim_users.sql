{{
    config(
        materialized='table',
        tags=['daily']
    )
}}

with users as (
    select * from {{ ref('stg_users') }}
)

select
    user_id,
    email,
    created_at,
    updated_at,
    current_timestamp() as dbt_updated_at
from users

