# ADR 0003 — Multi-environment promotion with ArgoCD ApplicationSets

- **Status**: accepted
- **Date**: 2026-07-18

## Context

The pipeline initially deployed a single environment (`default` namespace) through one
ArgoCD `Application`. Real data platforms need isolated environments with different
cadences and a controlled path to production: a change should prove itself in dev and
staging before a human promotes it to prod.

Options considered:

1. **Three hand-written `Application` manifests** — simple but repetitive; every change
   to the app spec must be copied three times and drift between the copies is likely.
2. **One branch per environment** — common but fights Git: promotion becomes merge
   management, hotfixes diverge, and history is hard to read.
3. **ApplicationSet + Kustomize overlays** — one template generates the three
   Applications from a list of environments; per-env differences live as overlay patches.

## Decision

Use an **ArgoCD ApplicationSet** with a list generator (`dev`, `staging`, `prod`) over
**Kustomize overlays** (`k8s/envs/<env>` on top of `k8s/base`).

- `dev` and `staging` sync **automatically** (prune + self-heal).
- `prod` has **no automated sync policy** (via `templatePatch`): promotion is an explicit
  operator action in ArgoCD, on the exact image SHA already validated downstream.
- Environment differences are limited to namespace and CronJob schedule; anything more
  becomes a reviewed patch in the overlay.

## Consequences

- Adding an environment is a one-line change in the generator list plus an overlay folder.
- The prod diff is always reviewable in the ArgoCD UI before promotion — no "merge and
  pray".
- All three environments share the same base manifests, so configuration drift between
  environments is structurally impossible.
- The single-cluster demo maps 1:1 to a multi-cluster setup later: the destination
  `server` simply becomes part of the generator elements.
