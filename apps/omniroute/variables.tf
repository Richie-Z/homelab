variable "image" {
  description = "OmniRoute image (Docker Hub diegosouzapw/omniroute)"
  type        = string
  default     = "diegosouzapw/omniroute:latest"
}

variable "hostname" {
  description = "Public hostname served through the Traefik ingress"
  type        = string
  default     = "omniroute.dreadwrym.my.id"
}

variable "password" {
  description = "Initial dashboard password (INITIAL_PASSWORD). Leave empty to run the onboarding wizard."
  type        = string
  default     = "admin"
}
