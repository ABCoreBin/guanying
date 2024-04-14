#!/bin/bash

# 执行第一个任务：安装fuse3
apt-get install -y fuse3

# 执行第二个任务：创建docker配置文件并重启docker服务
mkdir -p /etc/systemd/system/docker.service.d/
cat <<EOF > /etc/systemd/system/docker.service.d/clear_mount_propagation_flags.conf
[Service]
MountFlags=shared
EOF
systemctl restart docker.service

# 执行第三个任务：创建文件夹并设置权限
mkdir -p /opt/docker/qb-downloads/本地/本地电影
mkdir -p /opt/docker/qb-downloads/本地/本地剧集
mkdir -p /opt/docker/qb-downloads/本地/links电影
mkdir -p /opt/docker/qb-downloads/本地/links剧集

# 执行第四个任务：创建Docker网络
docker network create -d bridge --subnet 172.19.0.0/16 1panel-network2

# 获取LICENSE_KEY值
LICENSE_KEY=$1

# 获取PLEX_CLAIM值
PLEX_CLAIM=$2

# 添加Docker Compose内容
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
      - "127.0.0.1:8089:8089"
    volumes:
      - /opt/docker/qb/config:/config
      - /opt/docker/qb-downloads/movie:/movie
      - /opt/docker/qb-downloads/tv:/tv
      - /opt/docker/qb-downloads/本地:/本地
      - /guazai:/guazai:rslave      
    restart: unless-stopped
    networks:
      1panel-network2:
        ipv4_address: 172.19.0.2

  movie-robot:
    image: yipengfei/movie-robot:latest
    container_name: movie-robot
    restart: always
    ports:
      - "127.0.0.1:1329:1329"
    volumes:
      - /opt/docker/mr:/data
      - /opt/docker/qb-downloads/movie:/movie
      - /opt/docker/qb-downloads/tv:/tv
      - /opt/docker/qb-downloads/本地:/本地
      - /guazai:/guazai:rslave
    environment:
      - LICENSE_KEY=$LICENSE_KEY
    networks:
      1panel-network2:
        ipv4_address: 172.19.0.3

  flaresolverr:
    container_name: flaresolverr
    image: ghcr.io/flaresolverr/flaresolverr:latest
    ports:
      - "8191:8191"    
    environment:
      LOG_LEVEL: info
    restart: unless-stopped     
    networks:
      1panel-network2:
        ipv4_address: 172.19.0.4

  plex:
    container_name: plex
    image: lscr.io/linuxserver/plex:latest
    ports:
      - "33333:32400"
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
      1panel-network2:
        ipv4_address: 172.19.0.5   

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
      1panel-network2:
        ipv4_address: 172.19.0.6  
    pid: host
    privileged: true
    devices:
      - /dev/fuse:/dev/fuse
    ports:
      - "127.0.0.1:19798:19798"

networks:
  1panel-network2:
    external: true
    ipam:
      driver: default
      config:
        - subnet: 172.19.0.0/16
EOF

# 执行第五个任务：启动Docker服务
docker-compose up -d

# 执行第六个任务：修改权限
chmod -R 777 /opt
