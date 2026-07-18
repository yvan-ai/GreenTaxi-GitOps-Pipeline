resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  # Expose ArgoCD server with NodePort for easy access locally
  set {
    name  = "server.service.type"
    value = "NodePort"
  }

  # Set admin password to empty so it auto-generates one, or can be overridden
  # Actually, Argo automatically creates an admin password stored in a Secret.
}
