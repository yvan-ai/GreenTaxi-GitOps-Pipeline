# ADR 0001 — Use ArgoCD for GitOps delivery

- **Status:** Accepted
- **Date:** 2026-06-15

## Context

The platform must deploy dbt transformations to Kubernetes with zero manual steps
after a code push, and the cluster state must strictly and verifiably match the Git
repository (no configuration drift). We need a delivery mechanism that is declarative,
auditable, and cloud-agnostic.

Options considered:

1. **Push-based CI deployment** — GitHub Actions runs `kubectl apply` directly on the cluster.
2. **ArgoCD (pull-based GitOps)** — a controller inside the cluster continuously reconciles
   the live state against manifests in Git.
3. **Flux** — an alternative GitOps controller with similar guarantees.

## Decision

Adopt **ArgoCD** with an `Application` configured for automated sync, `prune`, and `selfHeal`.

## Consequences

**Positive**
- Git becomes the single source of truth; any drift is automatically reverted (`selfHeal`),
  and deleted manifests are removed from the cluster (`prune`).
- CI credentials never need cluster admin access — the pull model keeps the cluster's
  kubeconfig out of GitHub, reducing the attack surface.
- ArgoCD's UI gives a clear, recruiter-friendly visualization of sync status and history.

**Negative**
- One more component to run and understand inside the cluster.
- Chosen over Flux mainly for its richer UI and larger community footprint; Flux would
  have been an equally valid choice.
