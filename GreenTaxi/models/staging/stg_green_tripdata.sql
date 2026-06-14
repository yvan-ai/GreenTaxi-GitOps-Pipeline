{{ config(materialized='view') }}

with source as (
    -- For a real project with a live DB, this would be:
    -- select * from source('taxi_data', 'green_tripdata')

    -- Here we mock a single row for pipeline standalone execution and tests
    select
        1 as vendor_id,
        '2021-01-01 00:15:56'::timestamp as lpep_pickup_datetime,
        '2021-01-01 00:19:52'::timestamp as lpep_dropoff_datetime,
        'Y' as store_and_fwd_flag,
        1 as ratecode_id,
        2 as passenger_count,
        1.50 as trip_distance,
        6.5 as fare_amount,
        0.5 as extra,
        0.5 as mta_tax,
        1.66 as tip_amount,
        0.0 as tolls_amount,
        0.3 as ehail_fee,
        0.3 as improvement_surcharge,
        9.76 as total_amount,
        1 as payment_type,
        1 as trip_type,
        43 as pulocation_id,
        251 as dolocation_id
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
    dolocation_id
from source
