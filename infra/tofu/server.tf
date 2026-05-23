resource "hcloud_server" "main" {
  name        = "ri-${var.environment}"
  server_type = var.server_type
  location    = var.location
  image       = "ubuntu-24.04"
  backups     = var.enable_backups

  ssh_keys = [hcloud_ssh_key.deploy.id]

  firewall_ids = [hcloud_firewall.main.id]

  user_data = templatefile("${path.module}/templates/cloud-init.yml.tpl", {
    ssh_public_key       = trimspace(file(pathexpand(var.ssh_public_key_path)))
    domain               = var.domain
    environment          = var.environment
    postgres_admin_user  = data.sops_file.secrets.data["postgres_user"]
    postgres_admin_pass  = data.sops_file.secrets.data["postgres_password"]
    kratos_secret        = data.sops_file.secrets.data["kratos_secret"]
    kratos_cookie_secret = data.sops_file.secrets.data["kratos_cookie_secret"]
    dockerhub_username   = data.sops_file.secrets.data["dockerhub_username"]
    dockerhub_token      = data.sops_file.secrets.data["dockerhub_token"]
    docker_compose       = file("${path.module}/files/docker-compose.yml")
    caddyfile = templatefile("${path.module}/files/Caddyfile.tpl", {
      domain = var.domain
    })
    kratos_config = templatefile("${path.module}/files/kratos.yml.tpl", {
      domain = var.domain
    })
    kratos_identity_schema = file("${path.module}/../../infra/kratos/identity.schema.json")
    db_init_sql            = file("${path.module}/../../infra/database/docker-initdb/01-databases.sql")
    db_init_users_sh       = file("${path.module}/../../infra/database/docker-initdb/02-users.sh")
    db_init_perms_sql      = file("${path.module}/../../infra/database/docker-initdb/03-permissions.sql")
    pg_hba_conf            = file("${path.module}/../../infra/database/pg_hba.conf")
  })

  labels = {
    environment = var.environment
    managed_by  = "opentofu"
  }
}
