# ADR 0004 — Secrets provisioned by Terraform, never stored in Git

- **Status**: accepted
- **Date**: 2026-07-18

## Context

The first iteration of the Kubernetes manifests carried database credentials as plain
`value:` fields — visible to anyone with read access to the repository, and copied
identically across environments. GitOps makes this worse: the repo is the deployment
mechanism, so a leaked repo is a leaked production credential.

Options considered:

1. **Kubernetes Secrets committed to Git** — base64 is encoding, not encryption; this
   only hides the problem.
2. **Sealed Secrets** — encrypts against one cluster's key. Safe in Git, but the
   ciphertext is useless on any other cluster, which breaks this repo's "clone and
   run" promise.
3. **External Secrets Operator** — the production-grade answer, but requires an external
   backend (Vault, AWS Secrets Manager…) that a local demo cannot assume.
4. **Terraform-generated Secrets** — the IaC layer creates a `random_password` per
   environment and materializes it as a Kubernetes `Secret`; manifests reference it
   by name only (`secretKeyRef`).

## Decision

Option 4. Terraform owns the environment namespaces and provisions a
`postgres-credentials` Secret (random 24-char password per environment) in each.
Git manifests contain **no secret values** — only `secretKeyRef` references.
The Grafana admin password is likewise generated (`terraform output -raw
grafana_admin_password`) instead of the chart's well-known default.

Secret values exist in exactly two places: the Terraform state and the cluster.

## Consequences

- The repository can be public without exposing any credential; each environment gets
  a distinct password, so no lateral movement between envs.
- The Terraform state becomes sensitive and must be treated as such (remote encrypted
  backend in a real deployment).
- CI's ephemeral Postgres keeps throwaway inline credentials by design: the container
  lives for minutes, is reachable only inside the runner, and holds public sample data.
- Migrating to External Secrets Operator later only changes who writes the Secret;
  the manifests' `secretKeyRef` contract stays identical.
