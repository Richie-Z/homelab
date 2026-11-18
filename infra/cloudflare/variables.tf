variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API token."
  sensitive   = true
}

variable "account_id" {
  type        = string
  description = "Cloudflare account ID."
}

variable "zone_id" {
  type        = string
  description = "Zone ID of dreadwrym.my.id."
}

variable "zone_name" {
  type        = string
  description = "Cloudflare zone name."
  default     = "dreadwrym.my.id"
}

variable "access_emails" {
  type        = set(string)
  description = "Email addresses allowed by the Access policy."
}
