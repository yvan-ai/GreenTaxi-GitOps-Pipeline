# Build context is the repository root (see .github/workflows/ci.yml and Makefile):
#   docker build -f GreenTaxi/Dockerfile .
FROM python:3.11-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    git \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir dbt-core dbt-postgres pandas pyarrow sqlalchemy

WORKDIR /usr/app/dbt

COPY ingestion/ /usr/app/ingestion/
COPY GreenTaxi/ .

RUN chmod +x entrypoint.sh

ENV DBT_PROFILES_DIR=/usr/app/dbt

CMD ["./entrypoint.sh"]
