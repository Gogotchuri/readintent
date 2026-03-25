#!/usr/bin/bash
docker compose -p readintent_dev --project-directory ./ -f docker-compose.dev.yml --env-file ./.env.dev up -d --remove-orphans
