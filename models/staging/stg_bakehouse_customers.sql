with source as (
    select * from {{ source('bakehouse', 'customers') }}
),

renamed as (
    select
        customer_id,
        customer_name,
        email,
        created_date,
        updated_date
    from source
)

select * from renamed

