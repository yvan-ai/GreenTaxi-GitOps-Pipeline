{{
    config(
        materialized='incremental',
        incremental_strategy='delete+insert',
        unique_key=['vendor_id', 'revenue_month']
    )
}}

with trip_data as (
    select * from {{ ref('stg_green_tripdata') }}

    {% if is_incremental() %}
    -- Only recompute months that received new data since the last run
        where date_trunc('month', pickup_datetime) >= (
            select coalesce(max(existing.revenue_month), '1900-01-01'::timestamp)
            from {{ this }} as existing
        )
    {% endif %}
)

select
    vendor_id,
    date_trunc('month', pickup_datetime) as revenue_month,
    sum(fare_amount) as revenue_monthly_fare,
    sum(extra) as revenue_monthly_extra,
    sum(mta_tax) as revenue_monthly_mta_tax,
    sum(tip_amount) as revenue_monthly_tip_amount,
    sum(tolls_amount) as revenue_monthly_tolls_amount,
    sum(ehail_fee) as revenue_monthly_ehail_fee,
    sum(improvement_surcharge) as revenue_monthly_improvement_surcharge,
    sum(total_amount) as revenue_monthly_total_amount,
    count(trip_distance) as total_monthly_trips,
    avg(passenger_count) as avg_monthly_passenger_count,
    avg(trip_distance) as avg_monthly_trip_distance
from trip_data
group by 1, 2
