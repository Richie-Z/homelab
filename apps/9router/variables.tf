variable "image" {
  description = "Docker Hub image tag for 9router (defaults to latest)"
  type        = string
  default     = "decolua/9router:latest"
}

variable "hostname" {
  description = "Public hostname routed through Cloudflare Tunnel"
  type        = string
  default     = "9router.dreadwrym.my.id"
}