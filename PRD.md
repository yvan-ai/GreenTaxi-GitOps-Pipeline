# Project: GreenTaxi-GitOps-Pipeline

## Context & Objectives
Build a fully automated data transformation platform using dbt, running on Kubernetes, managed via GitOps (ArgoCD).

## Target Stack
- **Infrastructure:** Kubernetes (Kind on WSL), Terraform.
- **Data Engineering:** dbt (Data Build Tool), SQL, Python.
- **CI/CD & GitOps:** GitHub Actions, ArgoCD, Docker.
- **Quality:** SQLFluff, Pytest, Pre-commit hooks.

## Key Success Metrics
1. 0 manual steps for deployment after code push.
2. Infrastructure state strictly matches Git repository.
3. 100% of dbt models tested before image build.