resource "cloudflare_zero_trust_access_service_token" "penpot" {
  account_id = var.account_id
  name       = "opencode-penpot"
  duration   = "forever"
  enabled    = true
}
