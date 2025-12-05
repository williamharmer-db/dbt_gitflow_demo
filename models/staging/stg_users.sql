with source as (
    select * from {{ source('raw_data', 'users') }}
),

renamed as (
    select
        id as user_id,
        email,
        created_at,
        updated_at
    from source
)

select * from renamed

