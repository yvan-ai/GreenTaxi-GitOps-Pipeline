resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.monitoring_namespace
  }
}

# Prometheus + Grafana + Alertmanager + kube-state-metrics in one chart.
# The release is named "monitoring": PrometheusRule resources delivered by
# GitOps must carry the label `release: monitoring` to be picked up.
resource "helm_release" "kube_prometheus_stack" {
  name       = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.kube_prometheus_stack_version
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  timeout    = 900

  # Keep the footprint small enough for a local Kind cluster
  set {
    name  = "grafana.service.type"
    value = "NodePort"
  }
  set {
    name  = "prometheus.prometheusSpec.retention"
    value = "7d"
  }
  # Let Grafana's sidecar load dashboards from ConfigMaps in any namespace
  set {
    name  = "grafana.sidecar.dashboards.searchNamespace"
    value = "ALL"
  }
}
