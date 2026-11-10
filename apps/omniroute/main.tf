resource "kubernetes_namespace_v1" "omniroute" {
  metadata {
    name = "omniroute"
  }
}

resource "kubernetes_persistent_volume_claim_v1" "omniroute_data" {
  metadata {
    name      = "omniroute-data"
    namespace = kubernetes_namespace_v1.omniroute.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "local-path"

    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }

  wait_until_bound = false
  lifecycle {
    prevent_destroy = true
  }
}

resource "kubernetes_deployment_v1" "omniroute" {
  metadata {
    name      = "omniroute"
    namespace = kubernetes_namespace_v1.omniroute.metadata[0].name

    labels = {
      app = "omniroute"
    }
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        app = "omniroute"
      }
    }

    template {
      metadata {
        labels = {
          app = "omniroute"
        }
      }

      spec {
        termination_grace_period_seconds = 60

        container {
          name              = "omniroute"
          image             = var.image
          image_pull_policy = "Always"

          port {
            name           = "http"
            container_port = 20128
          }

          env {
            name  = "DATA_DIR"
            value = "/app/data"
          }

          env {
            name  = "INITIAL_PASSWORD"
            value = var.password
          }

          env {
            name  = "PORT"
            value = "20128"
          }

          resources {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }

            limits = {
              cpu    = "1"
              memory = "2Gi"
            }
          }

          # /healthz is the in-memory probe the image's own HEALTHCHECK uses;
          # /api/monitoring/health hits SQLite and flaps under load.
          startup_probe {
            http_get {
              path = "/healthz"
              port = "http"
            }

            period_seconds    = 10
            timeout_seconds   = 5
            failure_threshold = 24
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = "http"
            }

            period_seconds    = 20
            timeout_seconds   = 5
            failure_threshold = 3
          }

          readiness_probe {
            http_get {
              path = "/healthz"
              port = "http"
            }

            period_seconds    = 10
            timeout_seconds   = 5
            failure_threshold = 2
          }

          volume_mount {
            name       = "data"
            mount_path = "/app/data"
          }
        }

        volume {
          name = "data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.omniroute_data.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_persistent_volume_claim_v1.omniroute_data
  ]
}

resource "kubernetes_service_v1" "omniroute" {
  metadata {
    name      = "omniroute"
    namespace = kubernetes_namespace_v1.omniroute.metadata[0].name
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = "omniroute"
    }

    port {
      name        = "http"
      port        = 20128
      target_port = "http"
    }
  }
}

resource "kubernetes_ingress_v1" "omniroute" {
  metadata {
    name      = "omniroute"
    namespace = kubernetes_namespace_v1.omniroute.metadata[0].name

    # ingress-shim creates the Certificate and its secret.
    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
    }
  }

  spec {
    ingress_class_name = "traefik"

    tls {
      hosts       = [var.hostname]
      secret_name = "omniroute-tls"
    }

    rule {
      host = var.hostname

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.omniroute.metadata[0].name

              port {
                number = 20128
              }
            }
          }
        }
      }
    }
  }
}
