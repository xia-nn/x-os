#!/bin/bash
#
# 在 QEMU 中启动 X OS 产出的 ISO，验证桌面
#
#   ./run-qemu.sh
#
set -euo pipefail

ISO=$(ls -1 iso/out/xos-*.iso 2>/dev/null | head -n1)
[ -z "$ISO" ] && { echo "未找到 ISO，请先构建（iso/build.sh 或 iso/docker-build.sh）。"; exit 1; }

echo "==> 启动: $ISO"
qemu-system-x86_64 \
  -m 4096 -smp 4 \
  -enable-kvm \
  -cdrom "$ISO" -boot d \
  -vga virtio -display gtk \
  -device virtio-net-pci,netdev=net0 \
  -netdev user,id=net0 \
  -usb -device usb-tablet

# 说明：
#  - 无 KVM 的宿主机请去掉 -enable-kvm；
#  - Windows 可用 -display sdl 或省略（默认窗口）；
#  - 启动后进入 SDDM -> 自动登录 live -> labwc(Wayland) -> xos-shell 桌面。
