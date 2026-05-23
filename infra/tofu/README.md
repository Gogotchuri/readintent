# ReadIntent Infrastructure

Single-server deployment per environment (dev + prod) on Hetzner Cloud, provisioned with OpenTofu.

## Prerequisites

- [OpenTofu](https://opentofu.org/) >= 1.6
- [sops](https://github.com/getsops/sops) + [age](https://github.com/FiloSottile/age)
- Hetzner Cloud API token
- Cloudflare API token (DNS zone for readintent.app)
- Docker Hub account (private repos)

## Initial Setup

```bash
# 1. Generate age key (one-time)
age-keygen -o infra/tofu/age-key.txt
# Copy the public key from stdout into .sops.yaml

# 2. Create & encrypt secrets for each environment
cp secrets/dev.enc.yaml.example secrets/dev.enc.yaml
# Edit with real values, then encrypt:
SOPS_AGE_KEY_FILE=infra/tofu/age-key.txt sops -e -i secrets/dev.enc.yaml

# Same for prod:
cp secrets/prod.enc.yaml.example secrets/prod.enc.yaml
SOPS_AGE_KEY_FILE=infra/tofu/age-key.txt sops -e -i secrets/prod.enc.yaml

# 3. Set provider credentials
export HCLOUD_TOKEN="hc_..."
export CLOUDFLARE_API_TOKEN="..."
```

## Provisioning

```bash
cd infra/tofu
tofu init

# Dev
tofu workspace new dev          # first time only
tofu workspace select dev
SOPS_AGE_KEY_FILE=./age-key.txt tofu apply -var-file=envs/dev.tfvars

# Prod
tofu workspace new prod         # first time only
tofu workspace select prod
SOPS_AGE_KEY_FILE=./age-key.txt tofu apply -var-file=envs/prod.tfvars
```

## Manual Deploy

```bash
ssh deploy@dev-api.readintent.app "cd /opt/readintent && docker compose pull && docker compose up -d"
ssh deploy@api.readintent.app "cd /opt/readintent && docker compose pull && docker compose up -d"
```

## CI/CD (GitHub Actions)

Automated on push:
- `dev` branch → builds changed images tagged `:dev` → deploys to dev server
- `master` branch → builds changed images tagged `:latest` → deploys to prod server

Only triggers when `backend/`, `scraper/`, or `phonemizer/` files change.
Builds all 3 images in parallel (cached layers).

**Required GitHub repo secrets:**

| Secret | Description |
|--------|-------------|
| `DEPLOY_SSH_KEY` | Private key for the `deploy` user |
| `DEV_SERVER_HOST` | Dev server public IP |
| `PROD_SERVER_HOST` | Prod server public IP |
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token |

## Editing Encrypted Secrets

```bash
SOPS_AGE_KEY_FILE=infra/tofu/age-key.txt sops secrets/dev.enc.yaml
```
