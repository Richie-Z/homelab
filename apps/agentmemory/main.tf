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

        # Copy the engine config into the writable PVC. The app runs the engine
        # in the config file's directory, and the npm package dir is read-only
        # for the runtime user, so the engine cannot create its ./config there.
        init_container {
          name              = "seed-engine-config"
          image             = var.image
          image_pull_policy = "IfNotPresent"

          command = [
            "sh",
            "-c",
            "cp /opt/agentmemory/node_modules/@agentmemory/agentmemory/dist/iii-config.docker.yaml /data/iii-config.yaml",
          ]

          volume_mount {
            name       = "data"
            mount_path = "/data"
          }
        }

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

          # The image entrypoint rewrites iii-config.yaml with a block-style
          # allowed_origins list, but the published @agentmemory/agentmemory
          # 0.9.30 renderer replaces only the key line and leaves the block
          # items behind, producing invalid YAML. The docker config uses a
          # flow-style list, so the renderer produces valid YAML. It is copied
          # to /data above so the engine can create ./config next to it.
          # Remove this once a release contains the engine-config render fix.
          env {
            name  = "AGENTMEMORY_III_CONFIG"
            value = "/data/iii-config.yaml"
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

          # /agentmemory/health requires the HMAC bearer token, which probes
          # cannot send, so readiness uses the unauthenticated livez route.
          readiness_probe {
            http_get {
              path = "/agentmemory/livez"
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

    tls {
      hosts       = [var.hostname]
      secret_name = "agentmemory-tls"
    }

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
