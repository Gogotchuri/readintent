locals {
  # Per-environment rolling image tag. consistent with the tag the CI
  # deploy workflow seds into .env (master -> latest, dev -> dev) 
  image_tag = var.environment == "dev" ? "dev" : "latest"

  # All mutable application config delivered to the server, keyed by path
  # relative to /opt/readintent. Rendered here (with sops secrets + templatefile)
  # pushed post-boot by terraform_data.config below so config edits don't force a server replace.
  managed_files = {
    "docker-compose.yml" = {
      mode    = "0644"
      content = file("${path.module}/files/docker-compose.yml")
    }

    ".env" = {
      mode    = "0600"
      content = <<-EOT
        ENVIRONMENT=${var.environment}
        DOCKER_REPO=${data.sops_file.secrets.data["dockerhub_username"]}
        IMAGE_TAG=${local.image_tag}
        POSTGRES_ADMIN_USER=${data.sops_file.secrets.data["postgres_user"]}
        POSTGRES_ADMIN_PASSWORD=${data.sops_file.secrets.data["postgres_password"]}
        KRATOS_DB_USER=kratos
        KRATOS_DB_PASSWORD=${data.sops_file.secrets.data["postgres_password"]}
        BFF_DB_PASSWORD=${data.sops_file.secrets.data["postgres_password"]}
      EOT
    }

    "Caddyfile" = {
      mode = "0644"
      content = templatefile("${path.module}/files/Caddyfile.tpl", {
        domain = var.domain
      })
    }

    "kratos/kratos.yml" = {
      mode = "0644"
      content = templatefile("${path.module}/files/kratos.yml.tpl", {
        domain                     = var.domain
        kratos_secret              = data.sops_file.secrets.data["kratos_secret"]
        kratos_cookie_secret       = data.sops_file.secrets.data["kratos_cookie_secret"]
        google_oauth_client_id     = data.sops_file.secrets.data["google_oauth_client_id"]
        google_oauth_client_secret = data.sops_file.secrets.data["google_oauth_client_secret"]
      })
    }

    "kratos/identity.schema.json" = {
      mode    = "0644"
      content = file("${path.module}/../../infra/kratos/identity.schema.json")
    }

    "kratos/oidc.google.jsonnet" = {
      mode    = "0644"
      content = file("${path.module}/../../infra/kratos/oidc.google.jsonnet")
    }

    "database/docker-initdb/01-databases.sql" = {
      mode    = "0644"
      content = file("${path.module}/../../infra/database/docker-initdb/01-databases.sql")
    }

    "database/docker-initdb/02-users.sh" = {
      mode    = "0755"
      content = file("${path.module}/../../infra/database/docker-initdb/02-users.sh")
    }

    "database/docker-initdb/03-permissions.sql" = {
      mode    = "0644"
      content = file("${path.module}/../../infra/database/docker-initdb/03-permissions.sql")
    }

    "database/pg_hba.conf" = {
      mode    = "0644"
      content = file("${path.module}/../../infra/database/pg_hba.conf")
    }
  }
}

# Delivers mutable app config to the server out-of-band, after first boot.
# Re-runs whenever any rendered file changes (or the server is replaced),
# re-pushing config and restarting compose without replacing the server.
resource "terraform_data" "config" {
  triggers_replace = merge(
    { for path, f in local.managed_files : path => sha256(f.content) },
    { server_id = hcloud_server.main.id }
  )

  connection {
    type        = "ssh"
    host        = hcloud_server.main.ipv4_address
    user        = "deploy"
    private_key = file(pathexpand(var.ssh_private_key_path))
    timeout     = "10m" # first boot does apt upgrade + docker install
  }

  provisioner "remote-exec" {
    inline = concat(
      [
        # Wait for cloud-init to finish docker install + volume mount.
        # `|| true` tolerates a non-zero status from earlier-boot errors.
        "cloud-init status --wait || true",
        "sudo mkdir -p /opt/readintent/kratos /opt/readintent/database/docker-initdb",
        "sudo chown -R deploy:deploy /opt/readintent",
      ],
      # Write each file from base64 (avoids shell-escaping issues; only sha256
      # hashes of the content live in state, never the plaintext secrets).
      [for path, f in local.managed_files :
        "printf '%s' '${base64encode(f.content)}' | base64 -d > /opt/readintent/${path} && chmod ${f.mode} /opt/readintent/${path}"
      ],
      ["cd /opt/readintent && docker compose pull && docker compose up -d --remove-orphans"],
    )
  }

  # Volume must be attached + mounted before compose brings up postgres/redis.
  depends_on = [hcloud_volume_attachment.data]
}
