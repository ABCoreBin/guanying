#!/bin/bash

# 任务 1: 安装 fuse3
apt-get install -y fuse3

# 任务 2: 创建 Docker 配置文件并重启 Docker 服务
mkdir -p /etc/systemd/system/docker.service.d/
cat <<EOF > /etc/systemd/system/docker.service.d/clear_mount_propagation_flags.conf
[Service]
MountFlags=shared
EOF
systemctl restart docker.service

# 任务 3: 创建文件夹并设置权限
mkdir -p /opt/docker/qb-downloads/本地/本地电影
mkdir -p /opt/docker/qb-downloads/本地/本地剧集
mkdir -p /opt/docker/qb-downloads/本地/links电影
mkdir -p /opt/docker/qb-downloads/本地/links剧集

# 任务 4: 获取 LICENSE_KEY 和 PLEX_CLAIM 值
LICENSE_KEY=$1
PLEX_CLAIM=$2

# 任务 5: 添加 Docker Compose 内容
cat <<EOF > docker-compose.yml
version: '3'

services:
  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    environment:
      - PUID=0
      - PGID=0
      - WEBUI_PORT=8089
    ports:
      - "35781:35781"
      - "8089:8089"
    volumes:
      - /opt/docker/qb/config:/config
      - /opt/docker/qb-downloads/movie:/movie
      - /opt/docker/qb-downloads/tv:/tv
      - /opt/docker/qb-downloads/本地:/本地
      - /guazai:/guazai:rslave
    restart: unless-stopped
    networks:
      - 1panel-network

  movie-robot:
    image: yipengfei/movie-robot:latest
    container_name: movie-robot
    restart: always
    ports:
      - "1329:1329"
    volumes:
      - /opt/docker/mr:/data
      - /opt/docker/qb-downloads/movie:/movie
      - /opt/docker/qb-downloads/tv:/tv
      - /opt/docker/qb-downloads/本地:/本地
      - /guazai:/guazai:rslave
    environment:
      - LICENSE_KEY=$LICENSE_KEY
    networks:
      - 1panel-network

  flaresolverr:
    container_name: flaresolverr
    image: ghcr.io/flaresolverr/flaresolverr:latest
    ports:
      - "8191:8191"
    environment:
      LOG_LEVEL: info
    restart: unless-stopped
    networks:
      - 1panel-network

  plex:
    container_name: plex
    image: lscr.io/linuxserver/plex:latest
    ports:
      - "32400:32400"
    environment:
      - PUID=0
      - PGID=0
      - VERSION=docker
      - PLEX_CLAIM=$PLEX_CLAIM
    volumes:
      - /guazai:/guazai:rslave
      - /opt/docker/plex:/config
      - /opt/docker/qb-downloads/本地:/本地
    restart: unless-stopped
    networks:
      - 1panel-network

  clouddrive:
    image: cloudnas/clouddrive2
    container_name: clouddrive
    restart: unless-stopped
    environment:
      - CLOUDDRIVE_HOME=/Config
    volumes:
      - /cloudnas:/CloudNAS:shared
      - /guazai:/guazai:shared
      - /opt/cloudnas-config:/Config
      - /opt/docker/qb-downloads/本地:/本地
    networks:
      - 1panel-network
    pid: host
    privileged: true
    devices:
      - /dev/fuse:/dev/fuse
    ports:
      - "19798:19798"

networks:
  1panel-network:
    external: true

# 任务 6: 启动 Docker 服务
docker-compose up -d

# 任务 7: 修改权限
chmod -R 777 /opt
