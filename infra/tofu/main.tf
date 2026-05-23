provider "hcloud" {
  # Set via HCLOUD_TOKEN env var
}

provider "cloudflare" {
  # Set via CLOUDFLARE_API_TOKEN env var
}

data "sops_file" "secrets" {
  source_file = "${path.module}/../../secrets/${var.environment}.enc.yaml"
}
