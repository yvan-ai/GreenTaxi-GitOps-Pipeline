# ADR 0002 — Use dbt with PostgreSQL for the transformation layer

- **Status:** Accepted
- **Date:** 2026-06-15

## Context

We need a transformation framework that is testable, version-controlled, and easy to
run both in CI and inside a Kubernetes CronJob. The engine backing it should be simple
to spin up ephemerally in CI and portable across environments.

Options considered:

1. **dbt + PostgreSQL** — SQL-first transformations with built-in testing and docs.
2. **Hand-written SQL scripts** orchestrated by a shell/Python runner.
3. **Spark / PySpark jobs** for the transformation layer.

## Decision

Use **dbt** for transformations, targeting **PostgreSQL** as the warehouse.

## Consequences

**Positive**
- dbt provides testing (`schema.yml`), lineage, documentation, and `ref()`-based dependency
  management out of the box — far more maintainable than raw SQL scripts.
- PostgreSQL runs trivially as an ephemeral service container in GitHub Actions, enabling
  a real `dbt build` quality gate before any image is packaged.
- Connection settings are driven entirely by environment variables in `profiles.yml`, so
  no credentials are hardcoded and the same project runs locally, in CI, and in-cluster.

**Negative**
- PostgreSQL is not a cloud analytical warehouse (BigQuery/Snowflake); for large-scale
  analytics the adapter would need to change. dbt's adapter abstraction keeps that
  migration low-cost.
- Spark was rejected as over-engineered for the current data volumes.
