#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="gost-port-forward"
IMAGE="gogost/gost:latest"

docker pull "$IMAGE"

docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  --network host \
  "$IMAGE" \
  -L "tcp://:10443/103.135.103.90:10443" \
  -L "tcp://:11443/23.185.208.29:11443" \
  -L "tcp://:21443/188.253.120.181:21443"

echo "GOST 端口转发已启动："
echo "10443 -> 103.135.103.90:10443"
echo "11443 -> 23.185.208.29:11443"
echo "21443 -> 188.253.120.181:21443"

docker ps --filter "name=$CONTAINER_NAME"
