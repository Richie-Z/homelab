# Cloudflare Terraform

Manages the `dreadwrym.my.id` zone, Zero Trust Access apps and policies, the
Penpot service token, and the `dreadwrym` tunnel.

## Generated baseline

The initial resource inventory, resource IDs, DNS record IDs, and tunnel ID
came from `cf-terraforming` v0.31.0 against the live account. The generated
output was then normalized:

- stable resource names and `for_each` keys
- reusable policies referenced by ID instead of pasted into every app
- read-only and empty metadata removed, except API defaults pinned in config to
  avoid plan churn (see [Plan hygiene](#plan-hygiene))
- emails moved to `access_emails` in `terraform.tfvars`
- resource IDs moved to `import.tf`

Regenerate the raw baseline from the live account:

```bash
export CLOUDFLARE_API_TOKEN="..."
export CLOUDFLARE_ACCOUNT_ID="..."
export CLOUDFLARE_ZONE_ID="..."

../../cf-terraforming generate \
  --token "$CLOUDFLARE_API_TOKEN" \
  --account "$CLOUDFLARE_ACCOUNT_ID" \
  --zone "$CLOUDFLARE_ZONE_ID" \
  --resource-type "cloudflare_zero_trust_access_application,cloudflare_zero_trust_access_policy,cloudflare_zero_trust_access_service_token,cloudflare_dns_record,cloudflare_zero_trust_tunnel_cloudflared,cloudflare_zero_trust_tunnel_cloudflared_config" \
  > generated.tf
```

Run from `infra/cloudflare`. Use `cf-terraforming` directly if it is installed
instead of the repo-root binary. Add `--modern-import-block` to the same command
to generate `import` blocks for the resources.

## Import

The live resources are adopted with `import.tf`:

```bash
terraform init
terraform plan
terraform apply
```

After the import succeeds, delete `import.tf` and the two `*_import_ids` locals
from `locals.tf`.

`terraform.tfvars` is gitignored and holds the API token and access emails.

## Plan hygiene

The provider writes API defaults into state even when config omits them, so an
omitted Optional attribute shows up as an update on every plan. The values the
API returns are pinned in config:

- `cloudflare_zero_trust_access_application` — `auto_redirect_to_identity`,
  `enable_binding_cookie`, and `options_preflight_bypass` are all `false`.
- `cloudflare_zero_trust_access_policy` — `connection_rules = { rdp = {} }`,
  the empty block Cloudflare attaches to every policy.
- `cloudflare_zero_trust_tunnel_cloudflared_config` — `origin_request = {}`
  only for the `ssh` ingress, which the dashboard configured for the SSH
  hostname.

Computed-only attributes (`created_at`, `version`, `updated_at`, `reusable`,
`expires_at`, `leak_*`) must not be added to config. They are provider-owned
and only appear when something else in the resource changes.

### Service token

`client_secret_version` has a provider default of `1`, but import leaves it
null because neither it nor `client_secret` is returned by the API. The token
therefore reports an update on every plan, and `ignore_changes` cannot suppress
it: the default is applied after core planning. Applying sends
`client_secret_version = 1`, which only rotates the secret if the token is at
an earlier version. Confirm Penpot still authenticates afterwards; if the
secret changes it is written to state and must be copied into Penpot. To avoid
the update entirely, drop the resource and keep its ID in `locals.tf` next to
`penpot_policy_id`.

## Note

`penpot-mcp` uses `local.penpot_policy_id` rather than the policy resource
reference. The Penpot policy references both Penpot apps, so referencing the
policy from the app as well would create a Terraform dependency cycle.
