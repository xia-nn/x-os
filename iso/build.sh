#!/bin/bash
#
# X OS ISO 构建（Arch Linux 主机，需 root 并预装 archiso）
#
#   sudo pacman -S --needed archiso
#   sudo ./iso/build.sh
#
set -euo pipefail

cd "$(dirname "$0")"
PROFILE=profiles/xos
OUT=out
WORK=work

# 将自研应用源码同步进 profile，供 customize_airootfs.sh 编译
rm -rf "$PROFILE/airootfs/opt/xos-shell-src"
cp -r ../shell/xos-shell "$PROFILE/airootfs/opt/xos-shell-src"

rm -rf "$PROFILE/airootfs/opt/xos-settings-src"
cp -r ../shell/xos-settings "$PROFILE/airootfs/opt/xos-settings-src"

rm -rf "$WORK" "$OUT"
mkarchiso -v -w "$WORK" -o "$OUT" "$PROFILE"

echo "==> ISO 已生成于 $OUT/"
ls -1 "$OUT"
