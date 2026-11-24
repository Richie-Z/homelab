locals {
  penpot_policy_id = "a1b6a0b1-6e3b-4628-9704-3c8018d96868"

  access_apps = {
    "9router" = {
      name         = "9router"
      destinations = ["9router.${var.zone_name}"]
      policy       = "email"
    }
    "9router-v1" = {
      name         = "9router"
      destinations = ["9router.${var.zone_name}/v1"]
      policy       = "bypass"
    }
    alertmanager = {
      name         = "alertmanager"
      destinations = ["alertmanager.${var.zone_name}"]
      policy       = "email"
    }
    argocd = {
      name         = "argocd"
      destinations = ["argocd.${var.zone_name}"]
      policy       = "email"
    }
    grafana = {
      name         = "grafana"
      destinations = ["grafana.${var.zone_name}"]
      policy       = "email"
    }
    harbor = {
      name         = "harbor"
      destinations = ["harbor.${var.zone_name}"]
      policy       = "email"
    }
    harbor-v2 = {
      name         = "harbor"
      destinations = ["harbor.${var.zone_name}/v2", "harbor.${var.zone_name}/service/token*"]
      policy       = "bypass"
    }
    jenkins = {
      name         = "jenkins"
      destinations = ["jenkins.${var.zone_name}"]
      policy       = "email"
    }
    multica = {
      name         = "multica"
      destinations = ["multica.${var.zone_name}"]
      policy       = "email"
    }
    penpot = {
      name         = "penpot"
      destinations = ["penpot.${var.zone_name}"]
      policy       = "email"
    }
    penpot-mcp = {
      name         = "penpot"
      destinations = ["penpot.${var.zone_name}/mcp"]
      policy       = "penpot"
    }
    prometheus = {
      name         = "prometheus"
      destinations = ["prometheus.${var.zone_name}"]
      policy       = "email"
    }
    ssh = {
      name         = "ssh"
      destinations = ["ssh.${var.zone_name}"]
      policy       = "email"
    }
  }

  access_policy_ids = {
    email  = cloudflare_zero_trust_access_policy.email.id
    bypass = cloudflare_zero_trust_access_policy.bypass.id
    penpot = local.penpot_policy_id
  }

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
      hostname       = "${host}.${var.zone_name}"
      service        = host == "ssh" ? "ssh://localhost:22" : local.tunnel_origin
      origin_request = host == "ssh" ? {} : null
    }
  ]
}
