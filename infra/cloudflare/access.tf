locals {
  penpot_app_ids = {
    penpot     = "7eb7aa9c-8a1f-4d5a-833f-268a1e1ad806"
    penpot_mcp = "3566528f-0566-4e50-b2b8-b51b5a39b028"
  }

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
    penpot = cloudflare_zero_trust_access_policy.penpot.id
  }
}

resource "cloudflare_zero_trust_access_policy" "email" {
  account_id = var.account_id
  name       = "Email include"
  decision   = "allow"

  include = [
    { email = { email = "redacted@example.com" } },
    { email = { email = "redacted@example.com" } },
  ]
}

resource "cloudflare_zero_trust_access_policy" "bypass" {
  account_id = var.account_id
  name       = "Bypass All"
  decision   = "bypass"
  include    = [{ everyone = {} }]
}

resource "cloudflare_zero_trust_access_policy" "penpot" {
  account_id = var.account_id
  name       = "Penpot"
  decision   = "non_identity"

  include = [
    { service_token = { token_id = cloudflare_zero_trust_access_service_token.penpot.id } },
    { linked_app_token = { app_uid = local.penpot_app_ids.penpot } },
    { linked_app_token = { app_uid = local.penpot_app_ids.penpot_mcp } },
  ]
}

resource "cloudflare_zero_trust_access_service_token" "penpot" {
  account_id = var.account_id
  name       = "opencode-penpot"
  duration   = "forever"
  enabled    = true
}

resource "cloudflare_zero_trust_access_application" "this" {
  for_each = local.access_apps

  account_id           = var.account_id
  name                 = each.value.name
  domain               = each.value.destinations[0]
  type                 = "self_hosted"
  app_launcher_visible = true
  session_duration     = "24h"

  http_only_cookie_attribute = false

  destinations = [
    for uri in each.value.destinations : {
      type = "public"
      uri  = uri
    }
  ]

  policies = [{
    id         = local.access_policy_ids[each.value.policy]
    precedence = 1
  }]
}
