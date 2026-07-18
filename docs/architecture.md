# Architecture

## Overview

GreenTaxi is a GitOps-driven data transformation platform. It ingests raw NYC Green
Taxi trip data (official TLC Parquet exports), turns it into analytics-ready marts
using **dbt**, packages the transformation as an immutable Docker image, and delivers
it to **dev / staging / prod** Kubernetes environments through **ArgoCD
ApplicationSets** — with the Git repository as the single source of truth. A
**Prometheus + Grafana** stack watches the nightly runs.

## Data flow

```
NYC TLC open data (monthly Parquet exports)
        │  ingestion/load_green_tripdata.py (idempotent per month)
        ▼
[ raw ]      raw.green_tripdata          -- as published + loaded_at timestamp
        │  dbt source with freshness checks (warn 25h / error 49h)
        ▼
[ staging ]  stg_green_tripdata          -- cleaned & renamed columns (view)
        │
        ▼
[ marts ]    fct_monthly_revenue         -- monthly revenue aggregation (incremental)
        │
        ▼
Consumption (BI / analytics / dbt docs on GitHub Pages)
```

- **Raw layer** (`raw` schema): loaded by the ingestion script from the TLC CDN.
  Each row carries a `loaded_at` UTC timestamp that drives dbt source freshness.
  The load is idempotent per month (delete + insert), safe to re-run on a schedule.
- **Staging layer** (`models/staging/`): light cleaning, renaming, and filtering of
  invalid rows. Materialized as **views** so they are cheap and always reflect the source.
- **Marts layer** (`models/marts/`): business aggregations. Materialized as
  **incremental** models (`delete+insert` on `vendor_id + revenue_month`) — only months
  that received new data are recomputed.

## Delivery flow (GitOps)

1. A developer pushes SQL/config changes to `main`.
2. **GitHub Actions** lints (SQLFluff + Terraform), ingests a real TLC sample into an
   **ephemeral Postgres**, checks source freshness, then builds and tests the dbt project.
3. On success, a Docker image is built and pushed to **GHCR**, tagged with the commit SHA,
   and the dbt documentation site (lineage + catalog) is deployed to **GitHub Pages**.
4. The pipeline updates `k8s/base/dbt-cronjob.yaml` with the new image tag and commits it
   (`[skip ci]`) — the desired state now lives in Git.
5. An **ArgoCD ApplicationSet** fans the change out to three environments:
   - `greentaxi-dev` — auto-sync, hourly dbt runs
   - `greentaxi-staging` — auto-sync, daily runs at 2am
   - `greentaxi-prod` — **manual promotion**: an operator reviews the diff in ArgoCD and
     triggers the sync explicitly, nightly runs at midnight
6. Each environment runs the **dbt CronJob** against its own in-namespace Postgres.

## Multi-environment layout

```
k8s/
├── appset.yaml            # ApplicationSet: generates the 3 env Applications
├── monitoring-app.yaml    # ArgoCD Application for the monitoring resources
├── base/                  # Kustomize base: Postgres + dbt CronJob
├── envs/{dev,staging,prod}/  # Overlays: namespace + schedule per env
└── monitoring/            # PrometheusRule alerts + Grafana dashboard (GitOps-delivered)
```

Environment differences are expressed as **Kustomize patches** (namespace, schedule),
never by duplicating manifests. Promotion to prod is a deliberate human action on an
already-tested artifact — the same image SHA that ran in dev and staging.

## Observability

- **kube-prometheus-stack** (Prometheus, Grafana, Alertmanager, kube-state-metrics) is
  provisioned by Terraform alongside ArgoCD.
- Alert rules travel through Git like everything else (`k8s/monitoring/`):
  - `GreenTaxiDbtJobFailed` — a dbt job has failed pods for more than 5 minutes.
  - `GreenTaxiDbtJobMissing` — no dbt run started in 48 hours (silent-failure guard).
- A Grafana dashboard (`GreenTaxi dbt pipeline`) tracks run successes/failures and the
  time since the last run, loaded automatically via the dashboard sidecar.

## Data quality strategy

- dbt tests (`not_null`, extensible to `unique`, `accepted_values`, relationships)
  are declared in `schema.yml` and enforced in CI via `dbt build`.
- **Source freshness** is checked in CI (`dbt source freshness`): stale raw data warns
  at 25h and fails at 49h, so a broken ingestion cannot silently ship.
- No image is ever built from a dbt project that fails to parse or test — quality is a
  hard gate before packaging.

## Idempotency & replay

- Ingestion is idempotent per month: re-loading a month replaces its rows exactly.
- The incremental mart uses `delete+insert` on its unique key, so recomputed months
  converge to the same result; a `--full-refresh` rebuilds the world from raw.
- Images are immutable and SHA-tagged, so any historical run can be reproduced exactly
  by pinning the corresponding tag.

## Portability

The Terraform code depends only on the Kubernetes and Helm providers, driven by a
`kubeconfig` context variable. The same code provisions ArgoCD and the monitoring stack
on a local Kind cluster today or a managed EKS/GKE cluster tomorrow, with no changes to
the manifests or dbt project.
