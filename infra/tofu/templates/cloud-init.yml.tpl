#cloud-config

users:
  - name: deploy
    groups: docker, sudo
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ${ssh_public_key}

package_update: true
package_upgrade: true

packages:
  - apt-transport-https
  - ca-certificates
  - curl
  - gnupg
  - lsb-release
  - unattended-upgrades

runcmd:
  # Install Docker
  - install -m 0755 -d /etc/apt/keyrings
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  - chmod a+r /etc/apt/keyrings/docker.asc
  - echo "deb [arch=$$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $$(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
  - apt-get update
  - apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

  # Login to Docker Hub
  - echo "${dockerhub_token}" | docker login -u "${dockerhub_username}" --password-stdin

  # Copy GHCR credentials for deploy user
  - mkdir -p /home/deploy/.docker
  - cp /root/.docker/config.json /home/deploy/.docker/config.json
  - chown -R deploy:deploy /home/deploy/.docker

  # Start services
  - cd /opt/readintent && docker compose pull && docker compose up -d

write_files:
  # Docker compose file
  - path: /opt/readintent/docker-compose.yml
    permissions: "0644"
    content: |
      ${indent(6, docker_compose)}

  # Environment file
  - path: /opt/readintent/.env
    permissions: "0600"
    owner: root:root
    content: |
      ENVIRONMENT=${environment}
      DOCKER_REPO=${dockerhub_username}
      IMAGE_TAG=latest
      POSTGRES_ADMIN_USER=${postgres_admin_user}
      POSTGRES_ADMIN_PASSWORD=${postgres_admin_pass}
      KRATOS_DB_USER=kratos
      KRATOS_DB_PASSWORD=${postgres_admin_pass}
      BFF_DB_PASSWORD=${postgres_admin_pass}
      KRATOS_SECRET=${kratos_secret}
      KRATOS_COOKIE_SECRET=${kratos_cookie_secret}

  # Caddyfile
  - path: /opt/readintent/Caddyfile
    permissions: "0644"
    content: |
      ${indent(6, caddyfile)}

  # Kratos config
  - path: /opt/readintent/kratos/kratos.yml
    permissions: "0644"
    content: |
      ${indent(6, kratos_config)}

  # Kratos identity schema
  - path: /opt/readintent/kratos/identity.schema.json
    permissions: "0644"
    content: |
      ${indent(6, kratos_identity_schema)}

  # Database init scripts
  - path: /opt/readintent/database/docker-initdb/01-databases.sql
    permissions: "0644"
    content: |
      ${indent(6, db_init_sql)}

  - path: /opt/readintent/database/docker-initdb/02-users.sh
    permissions: "0755"
    content: |
      ${indent(6, db_init_users_sh)}

  - path: /opt/readintent/database/docker-initdb/03-permissions.sql
    permissions: "0644"
    content: |
      ${indent(6, db_init_perms_sql)}

  # pg_hba.conf
  - path: /opt/readintent/database/pg_hba.conf
    permissions: "0644"
    content: |
      ${indent(6, pg_hba_conf)}
