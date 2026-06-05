variable "environment" {
  type        = string
  description = "Environment name (dev, prod)"
}

variable "server_type" {
  type        = string
  default     = "cx22"
  description = "Hetzner server type"
}

variable "location" {
  type        = string
  default     = "nbg1"
  description = "Hetzner datacenter location"
}

variable "domain" {
  type        = string
  description = "Domain for this environmentreadintent.app"
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare zone ID for readintent.app"
}

variable "ssh_public_key_path" {
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
  description = "Path to SSH public key file"
}

variable "ssh_private_key_path" {
  type        = string
  default     = "~/.ssh/id_ed25519"
  description = "Path to SSH private key for the deploy user (used by the config provisioner)"
}

variable "volume_size" {
  type        = number
  default     = 20
  description = "Hetzner volume size in GB for persistent data"
}

variable "enable_backups" {
  type        = bool
  default     = false
  description = "Enable Hetzner server backups"
}
