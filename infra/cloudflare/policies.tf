resource "cloudflare_zero_trust_access_policy" "email" {
  account_id = var.account_id
  name       = "Email include"
  decision   = "allow"

  include = [
    for email in var.access_emails : {
      email = {
        email = email
      }
    }
  ]

  connection_rules = {
    rdp = {}
  }
}

resource "cloudflare_zero_trust_access_policy" "bypass" {
  account_id = var.account_id
  name       = "Bypass All"
  decision   = "bypass"
  include    = [{ everyone = {} }]

  connection_rules = {
    rdp = {}
  }
}

resource "cloudflare_zero_trust_access_policy" "penpot" {
  account_id = var.account_id
  name       = "Penpot"
  decision   = "non_identity"

  include = [
    { service_token = { token_id = cloudflare_zero_trust_access_service_token.penpot.id } },
    { linked_app_token = { app_uid = cloudflare_zero_trust_access_application.this["penpot"].id } },
    { linked_app_token = { app_uid = cloudflare_zero_trust_access_application.this["penpot-mcp"].id } },
  ]

  connection_rules = {
    rdp = {}
  }
}
