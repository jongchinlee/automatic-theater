#!/bin/bash
#
# https://github.com/LuckyPuppy514/automatic-theater/install.sh
# 作者：LuckyPuppy514
# 时间：2022-08-25
#
# 本脚本用于安装 automatic-theater
#

set -euo pipefail

cd "$(dirname "$0")"
SUDO=sudo
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
	SUDO=
fi

echo "|------------------------------------------------------|"
echo "|                                                      |"
echo "|                  Automatic Theater                   |" 
echo "|  https://github.com/LuckyPuppy514/automatic-theater  |"
echo "|                                                      |"
echo "|------------------------------------------------------|"
echo ""
echo "|------------------------------------------------------|"
echo "|                     当前配置如下                     |"
echo "|------------------------------------------------------|"
cat ./docker-compose-default.env
echo "|------------------------------------------------------|"
echo ""
read -r -p "确认信息，并继续执行？（是：y，否：n）：" CONFIRM
if [[ "${CONFIRM}" != "y" ]]; then
	echo "取消并退出"
	exit 0
fi

set -a
. ./docker-compose-default.env
set +a

echo ""
echo "开始创建媒体目录 ......"
for dir in \
	"${MEDIA_PATH}" \
	"${MEDIA_PATH}/movie" \
	"${MEDIA_PATH}/serial" \
	"${MEDIA_PATH}/anime" \
	"${MEDIA_PATH}/download"
do
	${SUDO} mkdir -p "${dir}"
	echo "✅  目录就绪：${dir}"
done

echo ""
echo "修改媒体目录权限 ......"
${SUDO} chown -R "${USERNAME}:${GROUPNAME}" "${MEDIA_PATH}"
${SUDO} chmod -R 770 "${MEDIA_PATH}"
echo "✅  修改媒体目录权限成功"

echo ""
echo "生成部署文件 ......"
cp ./docker-compose-default.env ./.env
cp ./docker-compose-default.yml ./docker-compose.yml

echo ""
echo "添加显卡配置 ......"
GPU_DEVICES=()
if [[ -d "/dev/dri" ]]; then
	GPU_DEVICES+=("/dev/dri:/dev/dri")
fi
if [[ -d "/dev/vchiq" ]]; then
	GPU_DEVICES+=("/dev/vchiq:/dev/vchiq")
fi
if (( ${#GPU_DEVICES[@]} )); then
	{
		echo "    devices:"
		for device in "${GPU_DEVICES[@]}"; do
			echo "      - ${device}"
		done
	} >> ./docker-compose.yml
	echo "✅  添加硬件加速设备成功"
else
	echo "✖️  未检测到 /dev/dri 或 /dev/vchiq，跳过硬件加速设备"
fi

${SUDO} chown "${USERNAME}:${GROUPNAME}" ./.env ./docker-compose.yml
chmod 660 ./.env ./docker-compose.yml

echo ""
echo "✅  程序执行完毕 ✅"
if docker info >/dev/null 2>&1; then
	DOCKER_RUN="docker compose"
else
	DOCKER_RUN="sudo docker compose"
fi
echo "下一步：${DOCKER_RUN} pull && ${DOCKER_RUN} up -d"
