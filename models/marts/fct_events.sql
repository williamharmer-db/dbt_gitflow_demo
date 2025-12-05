{{
    config(
        materialized='incremental',
        unique_key='event_id',
        file_format='delta',
        incremental_strategy='merge'
    )
}}

-- Principle: Idempotency ("Running it twice shouldn't break it")
-- Principle: Immutability (Append logic preferred)

with events as (
    select * from {{ ref('stg_events') }}
)

select
    event_id,
    user_id,
    event_type,
    event_timestamp,
    payload,
    current_timestamp() as dbt_loaded_at
from events

{% if is_incremental() %}
  -- State Awareness: Only process new data
  where event_timestamp > (select max(event_timestamp) from {{ this }})
{% endif %}

