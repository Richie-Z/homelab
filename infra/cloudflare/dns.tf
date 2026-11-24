resource "cloudflare_dns_record" "tunnel" {
  for_each = { for host in local.tunnel_hosts : host.name => host }

  zone_id = var.zone_id
  name    = "${each.key}.${var.zone_name}"
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.this.id}.cfargotunnel.com"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "immich" {
  zone_id = var.zone_id
  name    = "immich.${var.zone_name}"
  type    = "A"
  content = "103.119.237.106"
  proxied = false
  ttl     = 1
  comment = "used for shared ip on vpsmurah.co.id"
}

resource "cloudflare_dns_record" "immich_caa" {
  zone_id = var.zone_id
  name    = "immich.${var.zone_name}"
  type    = "CAA"
  ttl     = 1

  data = {
    flags = 0
    tag   = "issue"
    value = "letsencrypt.org; accounturi=https://acme-v02.api.letsencrypt.org/acme/acct/3858117286; validationmethods=dns-01"
  }
}
