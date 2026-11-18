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

  access_app_import_ids = {
    "9router"    = "0ea641ff-ba99-474d-b239-640bc7dfe089"
    "9router-v1" = "bcb60636-c863-4e79-a849-f6cfd94cc92c"
    alertmanager = "63049bb8-1218-4075-b852-029f6899702e"
    argocd       = "28cadf2e-6dbc-46fe-8993-45bc7329b90f"
    grafana      = "a9557b01-d9fd-4ee3-ac19-9b9e5c869709"
    harbor       = "eca0f44c-0751-4f99-9c00-97b96fa15ab2"
    "harbor-v2"  = "a1d88719-bc6a-4921-a7fa-7e1b76145e56"
    jenkins      = "08e3c2ea-5a14-40aa-a15c-8be56ecfe607"
    multica      = "5c54e1d8-b180-4f67-9cc0-ff7eca58a6ad"
    penpot       = "7eb7aa9c-8a1f-4d5a-833f-268a1e1ad806"
    "penpot-mcp" = "3566528f-0566-4e50-b2b8-b51b5a39b028"
    prometheus   = "18f56b37-0dd9-4cbe-a45f-efcbd7ba2a92"
    ssh          = "0d66067b-ee2f-4e4c-9ab6-632caece48f4"
  }

  dns_tunnel_import_ids = {
    "9router"     = "471ef166045359602d96a5a6f75e7093"
    agentmemory   = "b1aa64b77c6b4969f81b574da71dcb7b"
    alertmanager  = "61453e379a400b79db537db733e3787b"
    argocd        = "5d586976d28d480e207424908569f82b"
    "bench-check" = "bfa4de20d0c5d0489d5ed18f3abb048e"
    grafana       = "cdc714ae95bf02f8cde8b5c258fe8e98"
    harbor        = "44e5ba5b5183888e288dedb0807f26fb"
    jenkins       = "4387f5e460e17303b32d4b73182c2e54"
    multica       = "e90f287c4450183a5d09a307399f9be0"
    omniroute     = "07db4eb3b797fd5719a962355aaf6dec"
    penpot        = "0ad7f9c9fe018fa4e48503ca33b9a246"
    prometheus    = "24c3d10a8c8774a399dcb871f92be23e"
    ssh           = "17a3d4c4433f1533a1067a0e50f567ee"
  }
}
