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
  -L "tcp://:14443/5.34.221.16:14443" \
  -L "tcp://:20133/103.135.103.90:20133" \
  -L "tcp://:23133/23.185.208.29:23133" \
  -L "tcp://:21443/188.253.120.181:21443"

echo "GOST 端口转发已启动："
echo "14443 -> 5.34.221.16:14443"
echo "20133 -> 103.135.103.90:20133"
echo "23133 -> 23.185.208.29:23133"
echo "21443 -> 188.253.120.181:21443"

docker ps --filter "name=$CONTAINER_NAME"
