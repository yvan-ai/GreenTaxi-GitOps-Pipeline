locals {
  environments = ["dev", "staging", "prod"]
}

resource "kubernetes_namespace" "greentaxi" {
  for_each = toset(local.environments)

  metadata {
    name = "greentaxi-${each.key}"
    labels = {
      "app.kubernetes.io/part-of" = "greentaxi"
    }
  }
}

# One random Postgres password per environment. The value only ever lives in
# the Terraform state and the in-cluster Secret - never in Git manifests.
resource "random_password" "postgres" {
  for_each = toset(local.environments)

  length  = 24
  special = false
}

resource "kubernetes_secret" "postgres_credentials" {
  for_each = toset(local.environments)

  metadata {
    name      = "postgres-credentials"
    namespace = kubernetes_namespace.greentaxi[each.key].metadata[0].name
  }

  data = {
    username = "postgres"
    password = random_password.postgres[each.key].result
    database = "greentaxi"
  }
}
