variable "namespace" {
  description = "Namespace for AgentMemory resources"
  type        = string
  default     = "agentmemory"
}

variable "image" {
  description = "AgentMemory image built and pushed by Jenkins"
  type        = string
  default     = "harbor.dreadwrym.my.id/library/agentmemory:0.9.30"
}

variable "hostname" {
  description = "Public hostname routed through Cloudflare Tunnel"
  type        = string
  default     = "agentmemory.dreadwrym.my.id"
}
