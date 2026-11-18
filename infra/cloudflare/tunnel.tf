locals {
  tunnel_hosts = [
    "ssh",
    "harbor",
    "jenkins",
    "bench-check",
    "agentmemory",
    "grafana",
    "prometheus",
    "alertmanager",
    "9router",
    "omniroute",
    "argocd",
    "multica",
    "penpot",
  ]

  tunnel_origin = "http://192.168.18.43:80"

  tunnel_ingress = [
    for host in local.tunnel_hosts : {
      hostname = "${host}.${var.zone_name}"
      service  = host == "ssh" ? "ssh://localhost:22" : local.tunnel_origin
    }
  ]
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "this" {
  account_id = var.account_id
  name       = "dreadwrym"
  config_src = "cloudflare"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "this" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this.id
  source     = "cloudflare"

  config = {
    ingress = concat(local.tunnel_ingress, [{ service = "http_status:404" }])
  }
}
