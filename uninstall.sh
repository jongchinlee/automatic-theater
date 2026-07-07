#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

SUDO=(sudo)
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
	SUDO=()
fi

ENV_FILE=.env
[[ -r "$ENV_FILE" ]] || ENV_FILE=docker-compose-default.env
COMPOSE_FILE=docker-compose.yml
[[ -f "$COMPOSE_FILE" ]] || COMPOSE_FILE=docker-compose-default.yml

set -a
. "./$ENV_FILE"
set +a

CONFIG_PATH=${CONFIG_PATH:-./config}
MEDIA_PATH=${MEDIA_PATH:-./media/video}
OLD_MEDIA_PATH=/media/video

paths=("$CONFIG_PATH" "$MEDIA_PATH")
[[ "$MEDIA_PATH" == "$OLD_MEDIA_PATH" ]] || paths+=("$OLD_MEDIA_PATH")

echo "This will stop Automatic Theater and delete:"
for path in "${paths[@]}"; do
	[[ -e "$path" ]] && echo "  $path"
done
echo "  .env"
echo "  docker-compose.yml"
read -r -p "Type DELETE to continue: " CONFIRM
if [[ "$CONFIRM" != "DELETE" ]]; then
	echo "Cancelled."
	exit 0
fi

if docker info >/dev/null 2>&1; then
	DOCKER=(docker)
else
	DOCKER=("${SUDO[@]}" docker)
fi

if "${DOCKER[@]}" info >/dev/null 2>&1; then
	"${DOCKER[@]}" compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" down --remove-orphans --volumes || true
	"${DOCKER[@]}" rm -f heimdall flaresolverr prowlarr jproxy seerr radarr sonarr bazarr recyclarr qbittorrent chinesesubfinder emby 2>/dev/null || true
else
	echo "Docker unavailable; skipping container removal."
fi

safe_rm() {
	local path=$1
	case "$path" in
		""|"/"|".") echo "Refusing to remove unsafe path: $path"; exit 1 ;;
	esac
	[[ -e "$path" ]] || return 0
	"${SUDO[@]}" rm -rf -- "$path"
}

safe_rm "$CONFIG_PATH"
safe_rm "$MEDIA_PATH"
[[ "$MEDIA_PATH" == "$OLD_MEDIA_PATH" ]] || safe_rm "$OLD_MEDIA_PATH"
rm -f .env docker-compose.yml

echo "Uninstall completed."
