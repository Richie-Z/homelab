output "namespace" {
  value = kubernetes_namespace_v1.omniroute.metadata[0].name
}

output "service_url" {
  value = kubernetes_service_v1.omniroute.spec[0].cluster_ip
}
