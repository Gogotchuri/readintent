resource "hcloud_server" "main" {
  name        = "ri-${var.environment}"
  server_type = var.server_type
  location    = var.location
  image       = "ubuntu-24.04"
  backups     = var.enable_backups

  ssh_keys = [hcloud_ssh_key.deploy.id]

  firewall_ids = [hcloud_firewall.main.id]

  # Bootstrap only. Mutable app config is delivered post-boot by
  # terraform_data.config (see config.tf), so it lives outside user_data and a
  # config edit no longer forces a server replace.
  user_data = templatefile("${path.module}/templates/cloud-init.yml.tpl", {
    ssh_public_key     = trimspace(file(pathexpand(var.ssh_public_key_path)))
    dockerhub_username = data.sops_file.secrets.data["dockerhub_username"]
    dockerhub_token    = data.sops_file.secrets.data["dockerhub_token"]
    volume_id          = hcloud_volume.data.id
  })

  labels = {
    environment = var.environment
    managed_by  = "opentofu"
  }

  # user_data only executes on first boot, so later edits never reach a running
  # server anyway. Ignoring it stops config changes from forcing a full server
  # replace (which would detach the data volume and risk downtime/data loss).
  # Mutable config is delivered out-of-band via the deploy pipeline instead.
  lifecycle {
    ignore_changes = [user_data]
  }
}
