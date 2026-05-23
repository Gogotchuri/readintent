resource "hcloud_ssh_key" "deploy" {
  name       = "ri-${var.environment}-deploy"
  public_key = file(pathexpand(var.ssh_public_key_path))
}
