#!/usr/bin/env bash
# deploy.sh - Install, start, or restart the RavenHost website via Docker.
#
# Usage:
#   bash deploy.sh          # normal deploy / restart
#   bash deploy.sh --port   # force re-prompt for port
#
# Requirements: git, docker (with compose plugin)
#
set -euo pipefail

REPO_URL="https://github.com/f0rest96/ravenhost-website.git"
REPO_DIR_NAME="ravenhost-website"
CONTAINER_NAME="ravenhost-web"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# If the script is being run from outside the repo (e.g. from ~), install
# the site into a ravenhost-website/ subfolder next to the script.
if [ ! -f "$SCRIPT_DIR/package.json" ] && [ "$(basename "$SCRIPT_DIR")" != "$REPO_DIR_NAME" ]; then
  INSTALL_DIR="$SCRIPT_DIR/$REPO_DIR_NAME"
else
  INSTALL_DIR="$SCRIPT_DIR"
fi

ENV_FILE="$INSTALL_DIR/.env"

# ── Colours ───────────────────────────────────────────────────────────────────
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[1;34m'; N='\033[0m'
log()  { echo -e "${G}[deploy]${N} $*"; }
info() { echo -e "${B}[deploy]${N} $*"; }
warn() { echo -e "${Y}[deploy]${N} $*"; }
err()  { echo -e "${R}[deploy]${N} $*" >&2; exit 1; }

# ── Dependency check ──────────────────────────────────────────────────────────
command -v git    >/dev/null 2>&1 || err "git is not installed."
command -v docker >/dev/null 2>&1 || err "docker is not installed."
docker compose version >/dev/null 2>&1 || err "docker compose plugin is not installed."

echo ""
echo -e "${B}  RavenHost - Deploy Script${N}"
echo    "  ──────────────────────────"
echo ""

# ── Load existing .env ────────────────────────────────────────────────────────
if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

# ── Port prompt ───────────────────────────────────────────────────────────────
FORCE_PORT=false
[[ "${1:-}" == "--port" ]] && FORCE_PORT=true

if [ -z "${PORT:-}" ] || [ "$FORCE_PORT" = true ]; then
  echo "  Ports 80, 81, 8080, 8081 are reserved. Pick any free port for cloudflared."
  read -rp "  Port to expose locally: " PORT
  [[ -z "$PORT" ]] && err "No port entered. Aborting."
  [[ ! "$PORT" =~ ^[0-9]+$ ]] && err "Port must be a number."
  (( PORT > 0 && PORT < 65536 )) || err "Port must be between 1 and 65535."
  # Write/update just the PORT line in .env (preserve any other vars)
  if [ -f "$ENV_FILE" ] && grep -q "^PORT=" "$ENV_FILE"; then
    sed -i "s/^PORT=.*/PORT=$PORT/" "$ENV_FILE"
  else
    echo "PORT=$PORT" >> "$ENV_FILE"
  fi
  log "Port $PORT saved to .env"
fi

export PORT

# ── Check if site files are present ──────────────────────────────────────────
SITE_INSTALLED=false
[ -f "$INSTALL_DIR/package.json" ] && SITE_INSTALLED=true

if [ "$SITE_INSTALLED" = false ]; then
  info "Site not found. Cloning repository into $INSTALL_DIR ..."
  git clone "$REPO_URL" "$INSTALL_DIR"
  log "Repository ready."
  FRESH_INSTALL=true
else
  FRESH_INSTALL=false
fi

# ── Pull latest changes (skip on fresh install, already up to date) ───────────
if [ "$FRESH_INSTALL" = false ]; then
  info "Pulling latest changes..."
  git -C "$INSTALL_DIR" pull --ff-only || warn "git pull failed - continuing with local files."
fi

# ── Check container state ─────────────────────────────────────────────────────
is_running() {
  docker ps --filter "name=^/${CONTAINER_NAME}$" --filter "status=running" \
    --format "{{.Names}}" 2>/dev/null | grep -q "^${CONTAINER_NAME}$"
}

is_stopped() {
  docker ps -a --filter "name=^/${CONTAINER_NAME}$" \
    --format "{{.Names}}" 2>/dev/null | grep -q "^${CONTAINER_NAME}$"
}

# ── Build & run ───────────────────────────────────────────────────────────────
cd "$INSTALL_DIR"

if [ "$FRESH_INSTALL" = true ]; then
  info "Fresh install - building image and starting container on port $PORT..."
  docker compose up -d --build
  log "Site is running at http://localhost:$PORT"

elif is_running; then
  info "Container is running - rebuilding and restarting on port $PORT..."
  docker compose up -d --build
  log "Site restarted at http://localhost:$PORT"

elif is_stopped; then
  info "Container exists but is stopped - rebuilding and starting on port $PORT..."
  docker compose up -d --build
  log "Site started at http://localhost:$PORT"

else
  info "No container found - building image and starting on port $PORT..."
  docker compose up -d --build
  log "Site started at http://localhost:$PORT"
fi

echo ""
echo -e "  ${G}Done.${N} Point your cloudflared tunnel at http://localhost:$PORT"
echo ""
