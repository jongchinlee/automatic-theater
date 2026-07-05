#!/usr/bin/env bash
set -euo pipefail

compose=docker-compose-default.yml

reject() {
  local pattern=$1
  shift
  if grep -R -I -q "$pattern" "$@"; then
    printf 'rejected pattern: %s\n' "$pattern"
    exit 1
  fi
}

reject '^version:' "$compose"
grep -q 'subnet: 172.30.12.0/24' "$compose"
reject '172\.128\.2\.' . --exclude-dir=.git --exclude=.env
reject '192\.168\.2\.' . --exclude-dir=.git --exclude=.env
reject 'Asia/Shanghai' README.md docker-compose-default.env docker-compose-default.yml install.sh
reject '下一步：docker compose pull' install.sh
reject 'sudo docker-compose pull\|sudo docker-compose up\|sudo docker-compose down' README.md
reject '^  portainer:' "$compose"
[ ! -e config/portainer ]
reject 'Portainer' README.md config/heimdall/www/app.sqlite config/heimdall/www/SupportedApps config/heimdall/www/icons 2>/dev/null
reject 'Jellyseerr\|jellyseerr\|fallenbagel/jellyseerr' README.md docker-compose-default.yml config/heimdall/www/app.sqlite 2>/dev/null

grep -q '^  seerr:' "$compose"
grep -q 'image: seerr/seerr:latest' "$compose"
grep -q '^  bazarr:' "$compose"
grep -q 'image: linuxserver/bazarr:latest' "$compose"
grep -q '^  recyclarr:' "$compose"
grep -q 'image: recyclarr/recyclarr:latest' "$compose"

bad_images=$(awk '/image:/{print $2}' "$compose" | grep -v ':latest$' || true)
[ -z "$bad_images" ] || { printf 'non-latest images:\n%s\n' "$bad_images"; exit 1; }

bash -n install.sh

echo OK
