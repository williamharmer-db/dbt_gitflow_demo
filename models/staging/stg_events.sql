with source as (
    select * from {{ source('raw_data', 'events') }}
),

renamed as (
    select
        id as event_id,
        user_id,
        event_type,
        event_timestamp,
        payload
    from source
)

select * from renamed

