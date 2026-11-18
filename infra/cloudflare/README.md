# Cloudflare Terraform

Manages the `dreadwrym.my.id` zone, Zero Trust Access apps and policies, the
Penpot service token, and the `dreadwrym` tunnel.

## Generated baseline

The initial resource inventory, resource IDs, DNS record IDs, and tunnel ID
came from `cf-terraforming` v0.31.0 against the live account. The generated
output was then normalized:

- stable resource names and `for_each` keys
- reusable policies referenced by ID instead of pasted into every app
- read-only and empty metadata removed
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

## Note

`penpot-mcp` uses `local.penpot_policy_id` rather than the policy resource
reference. The Penpot policy references both Penpot apps, so referencing the
policy from the app as well would create a Terraform dependency cycle.
