{{ config(materialized='view') }}

with source as (
    select * from {{ source('taxi_data', 'green_tripdata') }}
)

select
    vendor_id,
    lpep_pickup_datetime as pickup_datetime,
    lpep_dropoff_datetime as dropoff_datetime,
    store_and_fwd_flag,
    ratecode_id,
    passenger_count,
    trip_distance,
    fare_amount,
    extra,
    mta_tax,
    tip_amount,
    tolls_amount,
    ehail_fee,
    improvement_surcharge,
    total_amount,
    payment_type,
    trip_type,
    pulocation_id,
    dolocation_id,
    loaded_at
from source
where
    total_amount is not null
    and lpep_pickup_datetime is not null
