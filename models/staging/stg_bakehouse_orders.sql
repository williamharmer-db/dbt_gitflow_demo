with source as (
    select * from {{ source('bakehouse', 'orders') }}
),

renamed as (
    select
        order_id,
        customer_id,
        order_date,
        order_status,
        order_total
    from source
)

select * from renamed

