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
  -L "tcp://:20133/103.235.16.248:20133" \
  -L "tcp://:23133/23.185.208.29:23133" \
  -L "tcp://:21133/188.253.120.181:21133"

echo "GOST 端口转发已启动："
echo "20133 -> 103.235.16.248:20133"
echo "23133 -> 23.185.208.29:23133"
echo "21133 -> 188.253.120.181:21133"

docker ps --filter "name=$CONTAINER_NAME"
