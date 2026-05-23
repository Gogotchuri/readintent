resource "hcloud_volume" "data" {
  name     = "ri-${var.environment}-data"
  size     = var.volume_size
  location = var.location
  format   = "ext4"

  labels = {
    environment = var.environment
    managed_by  = "opentofu"
  }
}

resource "hcloud_volume_attachment" "data" {
  volume_id = hcloud_volume.data.id
  server_id = hcloud_server.main.id
  automount = false
}
