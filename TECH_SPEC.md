# Technical Specifications

## 1. Agnostic Infrastructure (IaC)
- Use Terraform with the Helm provider to install ArgoCD.
- Ensure the code is provider-agnostic (local K8s today, EKS/GKE tomorrow).

## 2. CI/CD Pipeline Logic
- **Linting:** Pre-commit hooks for SQL and Terraform.
- **Continuous Integration:** GitHub Actions must run `dbt test` in a container.
- **Artifacts:** Docker images tagged with commit SHA.

## 3. GitOps Workflow
- ArgoCD monitors the `/k8s` directory.
- Deployment strategy: "Automated Sync" with "Prune" enabled to ensure immutability.