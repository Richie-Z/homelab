output "namespace" {
  value = kubernetes_namespace_v1.ninerouter.metadata[0].name
}

output "service_url" {
  value = kubernetes_service_v1.ninerouter.spec[0].cluster_ip
}

