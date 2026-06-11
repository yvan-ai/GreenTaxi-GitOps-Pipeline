variable "kubeconfig_path" {
  type        = string
  description = "Path to the kubeconfig file"
  default     = "~/.kube/config"
}

variable "kubeconfig_context" {
  type        = string
  description = "Kubernetes context to use"
  default     = "kind-kind" # By default for local Kind, or default if empty
}

variable "argocd_namespace" {
  type        = string
  description = "Namespace where ArgoCD will be installed"
  default     = "argocd"
}

variable "argocd_version" {
  type        = string
  description = "Helm chart version for ArgoCD"
  default     = "6.7.11"
}
