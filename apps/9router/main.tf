resource "kubernetes_namespace_v1" "ninerouter" {
  metadata {
    name = "9router"
  }
}

resource "kubernetes_persistent_volume_claim_v1" "ninerouter_data" {
  metadata {
    name      = "9router-data"
    namespace = kubernetes_namespace_v1.ninerouter.metadata[0].name
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

resource "kubernetes_deployment_v1" "ninerouter" {
  metadata {
    name      = "9router"
    namespace = kubernetes_namespace_v1.ninerouter.metadata[0].name

    labels = {
      app = "9router"
    }
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        app = "9router"
      }
    }

    template {
      metadata {
        labels = {
          app = "9router"
        }
      }

      spec {
        termination_grace_period_seconds = 60

        container {
          name              = "9router"
          image             = var.image
          image_pull_policy = "IfNotPresent"

          port {
            name           = "http"
            container_port = 20128
          }

          env {
            name  = "DATA_DIR"
            value = "/data"
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

          startup_probe {
            http_get {
              path = "/"
              port = "http"
            }

            period_seconds    = 10
            timeout_seconds   = 5
            failure_threshold = 24
          }

          liveness_probe {
            http_get {
              path = "/"
              port = "http"
            }

            period_seconds    = 20
            timeout_seconds   = 5
            failure_threshold = 3
          }

          readiness_probe {
            http_get {
              path = "/"
              port = "http"
            }

            period_seconds    = 10
            timeout_seconds   = 5
            failure_threshold = 2
          }

          volume_mount {
            name       = "data"
            mount_path = "/data"
          }
        }

        volume {
          name = "data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.ninerouter_data.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_persistent_volume_claim_v1.ninerouter_data
  ]
}

resource "kubernetes_service_v1" "ninerouter" {
  metadata {
    name      = "9router"
    namespace = kubernetes_namespace_v1.ninerouter.metadata[0].name
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = "9router"
    }

    port {
      name        = "http"
      port        = 20128
      target_port = "http"
    }
  }
}

resource "kubernetes_ingress_v1" "ninerouter" {
  metadata {
    name      = "9router"
    namespace = kubernetes_namespace_v1.ninerouter.metadata[0].name
  }

  spec {
    ingress_class_name = "traefik"

    tls {
      hosts       = [var.hostname]
      secret_name = "9router-tls"
    }

    rule {
      host = var.hostname

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.ninerouter.metadata[0].name

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

