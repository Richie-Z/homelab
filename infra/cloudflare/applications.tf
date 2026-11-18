resource "cloudflare_zero_trust_access_application" "this" {
  for_each = local.access_apps

  account_id           = var.account_id
  name                 = each.value.name
  domain               = each.value.destinations[0]
  type                 = "self_hosted"
  app_launcher_visible = true
  session_duration     = "24h"

  http_only_cookie_attribute = false
  auto_redirect_to_identity  = false
  enable_binding_cookie      = false
  options_preflight_bypass   = false

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
