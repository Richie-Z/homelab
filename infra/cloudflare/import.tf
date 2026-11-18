import {
  for_each = local.access_app_import_ids
  to       = cloudflare_zero_trust_access_application.this[each.key]
  id       = "accounts/${var.account_id}/${each.value}"
}

import {
  for_each = local.dns_tunnel_import_ids
  to       = cloudflare_dns_record.tunnel[each.key]
  id       = "${var.zone_id}/${each.value}"
}

import {
  to = cloudflare_zero_trust_access_policy.email
  id = "${var.account_id}/f46c2dff-cbdb-45dc-bb9c-2c4b38312f39"
}

import {
  to = cloudflare_zero_trust_access_policy.bypass
  id = "${var.account_id}/93a1aa2b-8eeb-43f7-8ae8-decf9b3268aa"
}

import {
  to = cloudflare_zero_trust_access_policy.penpot
  id = "${var.account_id}/a1b6a0b1-6e3b-4628-9704-3c8018d96868"
}

import {
  to = cloudflare_zero_trust_access_service_token.penpot
  id = "accounts/${var.account_id}/b3fbfd6d-7612-46b9-8bda-1f089def2352"
}

import {
  to = cloudflare_zero_trust_tunnel_cloudflared.this
  id = "${var.account_id}/df344e61-7041-440b-b1b9-6f7818be9e8c"
}

import {
  to = cloudflare_zero_trust_tunnel_cloudflared_config.this
  id = "${var.account_id}/df344e61-7041-440b-b1b9-6f7818be9e8c"
}

import {
  to = cloudflare_dns_record.immich
  id = "${var.zone_id}/f5647ae1831553eaf25d61d825f929bb"
}

import {
  to = cloudflare_dns_record.immich_caa
  id = "${var.zone_id}/124735225cfeecd3482adeae97fd9f44"
}
