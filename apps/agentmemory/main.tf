resource "kubernetes_namespace_v1" "agentmemory" {
  metadata {
    name = "agentmemory"
  }
}

resource "kubernetes_persistent_volume_claim_v1" "agentmemory_data" {
  metadata {
    name      = "agentmemory-data"
    namespace = kubernetes_namespace_v1.agentmemory.metadata[0].name
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

  # local-path uses WaitForFirstConsumer: the claim only binds once the
  # Deployment pod exists, so waiting for Bound here deadlocks the apply.
  wait_until_bound = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "kubernetes_deployment_v1" "agentmemory" {
  metadata {
    name      = "agentmemory"
    namespace = kubernetes_namespace_v1.agentmemory.metadata[0].name

    labels = {
      app = "agentmemory"
    }
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        app = "agentmemory"
      }
    }

    template {
      metadata {
        labels = {
          app = "agentmemory"
        }
      }

      spec {
        termination_grace_period_seconds = 60

        container {
          name              = "agentmemory"
          image             = var.image
          image_pull_policy = "IfNotPresent"

          port {
            name           = "http"
            container_port = 3111
          }

          env {
            name  = "AGENTMEMORY_DATA_DIR"
            value = "/data"
          }

          env {
            name  = "AGENTMEMORY_HMAC_FILE"
            value = "/data/.hmac"
          }

          env {
            name  = "MALLOC_ARENA_MAX"
            value = "2"
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
              path = "/agentmemory/livez"
              port = "http"
            }

            period_seconds    = 5
            timeout_seconds   = 3
            failure_threshold = 36
          }

          liveness_probe {
            http_get {
              path = "/agentmemory/livez"
              port = "http"
            }

            period_seconds    = 20
            timeout_seconds   = 5
            failure_threshold = 3
          }

          readiness_probe {
            http_get {
              path = "/agentmemory/health"
              port = "http"
            }

            period_seconds    = 10
            timeout_seconds   = 5
            failure_threshold = 3
          }

          volume_mount {
            name       = "data"
            mount_path = "/data"
          }
        }

        volume {
          name = "data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.agentmemory_data.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_persistent_volume_claim_v1.agentmemory_data
  ]
}

resource "kubernetes_service_v1" "agentmemory" {
  metadata {
    name      = "agentmemory"
    namespace = kubernetes_namespace_v1.agentmemory.metadata[0].name
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = "agentmemory"
    }

    port {
      name        = "http"
      port        = 3111
      target_port = "http"
    }
  }
}

resource "kubernetes_ingress_v1" "agentmemory" {
  metadata {
    name      = "agentmemory"
    namespace = kubernetes_namespace_v1.agentmemory.metadata[0].name
  }

  spec {
    ingress_class_name = "traefik"

    rule {
      host = var.hostname

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.agentmemory.metadata[0].name

              port {
                number = 3111
              }
            }
          }
        }
      }
    }
  }
}
