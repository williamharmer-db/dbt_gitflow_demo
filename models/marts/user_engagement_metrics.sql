{{
    config(
        materialized='table',
        tags=['metrics', 'daily']
    )
}}

-- User engagement metrics
-- Demonstrates: Building on existing models to create business metrics

with users as (
    select * from {{ ref('dim_users') }}
),

events as (
    select * from {{ ref('fct_events') }}
),

user_event_summary as (
    select
        e.user_id,
        count(*) as total_events,
        count(distinct date(e.event_timestamp)) as active_days,
        min(e.event_timestamp) as first_event_at,
        max(e.event_timestamp) as last_event_at
    from events e
    group by e.user_id
)

select
    u.user_id,
    u.email,
    u.created_at as user_created_at,
    coalesce(s.total_events, 0) as total_events,
    coalesce(s.active_days, 0) as active_days,
    s.first_event_at,
    s.last_event_at,
    case 
        when s.total_events >= 10 then 'power_user'
        when s.total_events >= 5 then 'regular_user'
        when s.total_events >= 1 then 'casual_user'
        else 'inactive'
    end as user_segment,
    current_timestamp() as dbt_updated_at
from users u
left join user_event_summary s on u.user_id = s.user_id

