#!/usr/bin/env bash
# Blue-green deploy orchestrator for the bff backend.
#
#   deploy.sh <image-tag>   roll the new image onto the inactive color, wait for
#                           it to be healthy, flip Caddy, then stop the old color
#   deploy.sh --rollback    flip back to the previously-active (retained) color
#
# The active color is derived from bff_upstream.caddy (the snippet Caddy imports),
# which is the single source of truth. `caddy reload` drains in-flight requests,
# so no connections are dropped.
set -euo pipefail
cd /opt/readintent

# Enable both color profiles for every compose command in this script so
# `ps`/`stop`/`exec`/`inspect` can resolve either color
export COMPOSE_PROFILES="blue green"

SNIPPET=/opt/readintent/bff_upstream.caddy
HEALTH_TIMEOUT=120

usage() { echo "usage: deploy.sh <image-tag> | deploy.sh --rollback" >&2; exit 1; }
[ $# -ge 1 ] || usage

# Rewrite the Caddy snipper in-place. This file must be bound in Docker Compose
write_snippet() { # $1 = color
    printf 'reverse_proxy bff_%s:5050 {\n\tflush_interval -1\n}\n' "$1" > "$SNIPPET"
}

reload_caddy() {
    docker compose exec -T caddy caddy reload \
    --config /etc/caddy/Caddyfile --adapter caddyfile
}

wait_healthy() { # $1 = color
    local cid deadline status
    cid=$(docker compose ps -q "bff_$1")
    [ -n "$cid" ] || { echo "no container for bff_$1" >&2; return 1; }
    # SECONDS stores the number of seconds we are executing this script
    deadline=$((SECONDS + HEALTH_TIMEOUT))
    # Probe every 3 seconds until the dedline if we have a healthy service
    while :; do
        status=$(docker inspect -f '{{.State.Health.Status}}' "$cid" 2>/dev/null || echo unknown)
        [ "$status" = healthy ] && return 0
        [ $SECONDS -lt $deadline ] || { echo "health timeout for bff_$1 (last: $status)" >&2; return 1; }
        sleep 3
    done
}

# Set ENV variable $1 to value $2 in .env
set_env_var() { # $1 = VAR  $2 = value
  # Check the existence of the VAR and replace inline
  # or append it
  if grep -q "^$1=" .env; then
      sed -i "s|^$1=.*|$1=$2|" .env
  else
      echo "$1=$2" >> .env
  fi
}

other_color() { [ "$1" = blue ] && echo green || echo blue; }

# Current routed color, parsed from the snippet Caddy imports.
# Empty if unknown. `|| true` keeps a no-match grep from aborting under
current_color() {
    grep -oE 'bff_(blue|green)' "$SNIPPET" 2>/dev/null | head -n1 | sed 's/^bff_//' || true
}
activate() { # $1 = target color  [$2 = image tag]
    local target=$1 tag=${2:-} var
    if [ -n "$tag" ]; then
        var="BFF_${target^^}_TAG"
        set_env_var "$var" "$tag"
        docker compose pull "bff_$target"
    fi
    # We will restart dependencies later
    docker compose up -d --no-deps "bff_$target"
    wait_healthy "$target" || return 1
    # Flip Caddy to the new color
    write_snippet "$target"
    reload_caddy
    echo ">> traffic now on bff_$target"
}

active=$(current_color)

## ROLLBACK
if [ "$1" = "--rollback" ]; then
    case "$active" in
        blue|green) target=$(other_color "$active") ;;
        *) echo "no active color in $SNIPPET; cannot roll back" >&2; exit 1 ;;
    esac
    echo ">> rolling back: $active -> $target"
    activate "$target" || { echo "rollback target bff_$target unhealthy; aborting" >&2; exit 1; }
    docker compose stop "bff_$active" || true
    echo ">> rolled back to bff_$target"
    exit 0
fi

## Deploy
NEW_TAG="$1"
case "$active" in
    blue|green) inactive=$(other_color "$active") ;;
    *) active=""; inactive=blue ;; # first run -> stand up blue
esac
echo ">> deploying $NEW_TAG to bff_$inactive (current active: ${active:-none})"

# Pin the inactive color to the new image, start it and flip.
if ! activate "$inactive" "$NEW_TAG"; then
    echo "bff_$inactive failed health check; aborting flip (bff_${active:-none} stays live)" >&2
    docker compose stop "bff_$inactive" || true
    exit 1
fi

# Roll the dependencies to the same build. A brief restart is fine;
# they resume from their Redis Streams consumer groups and reclaimed dropped events soon
set_env_var IMAGE_TAG "$NEW_TAG"
docker compose pull scraper phonemizer || true
docker compose up -d --no-deps scraper phonemizer || true

# Retire the old color
if [ -n "$active" ]; then
    docker compose stop "bff_$active" || true
fi

echo ">> deployed bff_$inactive @ $NEW_TAG (previous: bff_${active:-none} retained, stopped)"
