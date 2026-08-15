#!/bin/bash
#
# 在 Docker 中构建 X OS ISO（任意支持 Docker 的宿主机）
#
#   ./iso/docker-build.sh
#   -> 产出 iso/out/xos-*.iso
#
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p out

docker build -t xos-builder -f Dockerfile .
docker run --rm --privileged -v "$PWD/out":/xos/out xos-builder

echo "==> ISO 位于 $PWD/out/"
