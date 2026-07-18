"""Load NYC TLC Green Taxi trip data (Parquet) into Postgres.

Downloads one or more monthly Parquet files from the official NYC TLC
CloudFront distribution and loads them into the `raw.green_tripdata` table,
adding a `loaded_at` timestamp used by dbt source freshness checks.

The load is idempotent per month: existing rows for a month are deleted
before re-inserting, so the script can safely run on a schedule.

Usage:
    python ingestion/load_green_tripdata.py              # default: 2021-01
    python ingestion/load_green_tripdata.py 2021-01 2021-02

Connection is read from the same env vars as the dbt profile:
    DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME
"""

import io
import os
import sys
import urllib.request
from datetime import datetime, timezone

import pandas as pd
from sqlalchemy import create_engine, text

TLC_URL = "https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_{month}.parquet"
RAW_SCHEMA = "raw"
RAW_TABLE = "green_tripdata"

# Normalize TLC column names to snake_case
COLUMN_RENAMES = {
    "VendorID": "vendor_id",
    "RatecodeID": "ratecode_id",
    "PULocationID": "pulocation_id",
    "DOLocationID": "dolocation_id",
}


def engine_from_env():
    host = os.environ.get("DB_HOST", "localhost")
    port = os.environ.get("DB_PORT", "5432")
    user = os.environ.get("DB_USER", "user")
    password = os.environ.get("DB_PASSWORD", "pass")
    dbname = os.environ.get("DB_NAME", "greentaxi")
    return create_engine(f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{dbname}")


def download_month(month: str) -> pd.DataFrame:
    url = TLC_URL.format(month=month)
    print(f"Downloading {url} ...")
    with urllib.request.urlopen(url) as resp:
        df = pd.read_parquet(io.BytesIO(resp.read()))
    df = df.rename(columns=COLUMN_RENAMES)
    # ehail_fee is entirely null in TLC exports and typed as object; force numeric
    if "ehail_fee" in df.columns:
        df["ehail_fee"] = pd.to_numeric(df["ehail_fee"], errors="coerce")
    df["loaded_at"] = datetime.now(timezone.utc)
    print(f"  {len(df):,} rows for {month}")
    return df


def load(months: list[str]) -> None:
    engine = engine_from_env()
    with engine.begin() as conn:
        conn.execute(text(f"CREATE SCHEMA IF NOT EXISTS {RAW_SCHEMA}"))

    for month in months:
        df = download_month(month)
        with engine.begin() as conn:
            table_exists = conn.execute(text(
                "SELECT 1 FROM information_schema.tables "
                "WHERE table_schema = :s AND table_name = :t"
            ), {"s": RAW_SCHEMA, "t": RAW_TABLE}).scalar()
            if table_exists:
                deleted = conn.execute(text(
                    f"DELETE FROM {RAW_SCHEMA}.{RAW_TABLE} "
                    "WHERE date_trunc('month', lpep_pickup_datetime) = :m"
                ), {"m": f"{month}-01"}).rowcount
                if deleted:
                    print(f"  replaced {deleted:,} existing rows for {month}")
        df.to_sql(RAW_TABLE, engine, schema=RAW_SCHEMA, if_exists="append",
                  index=False, chunksize=10_000, method="multi")
        print(f"  loaded {month} into {RAW_SCHEMA}.{RAW_TABLE}")

    print("Done.")


if __name__ == "__main__":
    load(sys.argv[1:] or ["2021-01"])
