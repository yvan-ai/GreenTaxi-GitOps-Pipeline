# Architecture

## Overview

GreenTaxi is a GitOps-driven data transformation platform. It turns raw NYC Green
Taxi trip data into analytics-ready marts using **dbt**, packages the transformation
as an immutable Docker image, and delivers it to a **Kubernetes** cluster through
**ArgoCD** — with the Git repository as the single source of truth.

## Data flow

```
Source (NYC Green Taxi trip data)
        │
        ▼
[ staging ]  stg_green_tripdata      -- cleaned & renamed columns (view)
        │
        ▼
[ marts ]    fct_monthly_revenue     -- monthly revenue aggregation (table)
        │
        ▼
Consumption (BI / analytics)
```

- **Staging layer** (`models/staging/`): light cleaning, renaming, and typing. Materialized
  as **views** so they are cheap and always reflect the source.
- **Marts layer** (`models/marts/`): business aggregations. Materialized as **tables** for
  fast downstream reads.

> The source is currently mocked as a single in-SQL row so the pipeline runs standalone
> in CI without external dependencies. In production this becomes a dbt `source()` pointing
> at the loaded raw table (see [roadmap](../README.md#-roadmap)).

## Delivery flow (GitOps)

1. A developer pushes SQL/config changes to `main`.
2. **GitHub Actions** lints (SQLFluff + Terraform), then parses and tests the dbt project
   against an **ephemeral Postgres** service container.
3. On success, a Docker image is built and pushed to **GHCR**, tagged with the commit SHA.
4. The pipeline updates `k8s/dbt-cronjob.yaml` with the new image tag and commits it
   (`[skip ci]`) — the desired state now lives in Git.
5. **ArgoCD** detects the manifest change and reconciles the cluster (sync + prune + self-heal).
6. The **dbt CronJob** runs nightly against Postgres.

## Data quality strategy

- dbt tests (`not_null`, and extensible to `unique`, `accepted_values`, relationship tests)
  are declared in `schema.yml` and enforced in CI via `dbt build`.
- No image is ever built from a dbt project that fails to parse or test — quality is a
  hard gate before packaging.

## Idempotency & replay

- The marts are materialized as **tables** and fully rebuilt on each run, making the
  pipeline naturally idempotent: re-running produces the same result.
- Images are immutable and SHA-tagged, so any historical run can be reproduced exactly
  by pinning the corresponding tag.

## Portability

The Terraform code depends only on the Kubernetes and Helm providers, driven by a
`kubeconfig` context variable. The same code provisions ArgoCD on a local Kind cluster
today or a managed EKS/GKE cluster tomorrow, with no changes to the manifests or dbt project.
