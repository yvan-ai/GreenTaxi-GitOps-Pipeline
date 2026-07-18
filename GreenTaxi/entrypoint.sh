#!/bin/sh
# Container entrypoint for the scheduled dbt run:
# 1. ingest the configured TLC months into the raw schema (idempotent)
# 2. build and test all dbt models
set -e

python /usr/app/ingestion/load_green_tripdata.py ${INGEST_MONTHS:-2021-01}
exec dbt build
