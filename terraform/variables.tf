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

variable "monitoring_namespace" {
  type        = string
  description = "Namespace where the monitoring stack will be installed"
  default     = "monitoring"
}

variable "kube_prometheus_stack_version" {
  type        = string
  description = "Helm chart version for kube-prometheus-stack"
  default     = "87.17.0"
}
