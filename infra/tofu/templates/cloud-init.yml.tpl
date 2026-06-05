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
  - echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
  - apt-get update
  - apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

  # Wait for persistent volume to be attached
  - |
    for i in $(seq 1 30); do
      test -b /dev/disk/by-id/scsi-0HC_Volume_${volume_id} && break
      echo "Waiting for volume... attempt $i"
      sleep 5
    done

  # Mount persistent volume
  - mkdir -p /mnt/data
  - mount -o discard,defaults /dev/disk/by-id/scsi-0HC_Volume_${volume_id} /mnt/data
  - echo "/dev/disk/by-id/scsi-0HC_Volume_${volume_id} /mnt/data ext4 discard,nofail,defaults 0 0" >> /etc/fstab
  - mkdir -p /mnt/data/postgres /mnt/data/redis
  - chown -R 70:70 /mnt/data/postgres
  - chown -R 999:1000 /mnt/data/redis

  # Login to Docker Hub
  - echo "${dockerhub_token}" | docker login -u "${dockerhub_username}" --password-stdin

  # Copy GHCR credentials for deploy user
  - mkdir -p /home/deploy/.docker
  - cp /root/.docker/config.json /home/deploy/.docker/config.json
  - chown -R deploy:deploy /home/deploy/.docker

  # App config and `docker compose up` are handled post-boot by
  # terraform_data.config (see config.tf).
