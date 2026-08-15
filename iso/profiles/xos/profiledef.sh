#!/usr/bin/env bash
# shellcheck disable=SC2034

# X OS Archiso profile definition

iso_name="xos"
iso_label="XOS_$(date +%Y%m)"
iso_publisher="X OS <https://github.com/xia-nn/x-os>"
iso_application="X OS Live/Rescue CD"
iso_version="$(date +%Y.%m.%d)"
install_dir="xos"
buildmodes=('iso')
bootmodes=(
  'bios.syslinux.mbr'
  'bios.syslinux.eltorito'
  'uefi-x64.grub.eltorito'
)
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
)
