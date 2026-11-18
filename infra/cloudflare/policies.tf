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
