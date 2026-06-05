#!/usr/bin/bash
# Root test runner for the readintent monorepo.
# Usage:
#   ./test.sh                 # run all components that have tests
#   ./test.sh backend ui      # run only the named components
# Assumes the relevant toolchains (go, uv, flutter) and Docker are installed.

set -uo pipefail

# Absolute repo root, independent of the caller's cwd.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run() {
  echo ""
  echo "==> $1"
  case "$1" in
    backend)    ( cd "$ROOT/backend"    && go test -short ./... ) ;;
    scraper)    ( cd "$ROOT/scraper"    && uv sync --locked && uv run pytest -v ) ;;
    phonemizer) ( cd "$ROOT/phonemizer" && uv sync --locked && uv run pytest -v ) ;;
    ui)         ( cd "$ROOT/ui"         && flutter pub get && flutter test ) ;;
    *) echo "ERROR: unknown component '$1' (valid: backend scraper phonemizer ui)" >&2; return 2 ;;
  esac
}

components=("$@")
[[ $# -eq 0 ]] && components=(backend scraper phonemizer ui)

failed=()
for comp in "${components[@]}"; do
  run "$comp" || failed+=("$comp")
done

echo ""
if [[ ${#failed[@]} -eq 0 ]]; then
  echo "All requested component tests passed."
else
  echo "FAILED components: ${failed[*]}"
  exit 1
fi
