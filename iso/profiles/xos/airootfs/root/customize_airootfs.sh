#!/bin/bash
#
# Archiso 钩子：在 chroot 内构建阶段执行
#  - 创建自动登录用户 live
#  - 启用 sddm / NetworkManager 服务
#  - 从 /opt/xos-shell-src 编译并安装 xos-shell
#
set -e

# 创建自动登录用户（若已存在则忽略）
if ! id live >/dev/null 2>&1; then
  useradd -m -G wheel,audio,video,input -s /bin/bash live
fi

# 允许 wheel 组无密码 sudo（演示用，后续收紧）
echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/xos

# 预配置 Live 环境，避免 systemd-firstboot 交互式询问时区/locale/root密码
systemd-machine-id-setup || true
echo "xos-live" > /etc/hostname
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo "LANG=zh_CN.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf
sed -i 's/^#\(zh_CN.UTF-8\)/\1/' /etc/locale.gen
sed -i 's/^#\(en_US.UTF-8\)/\1/' /etc/locale.gen
locale-gen || true
# 演示用 root 密码，避免 firstboot 卡住
echo "root:root" | chpasswd

# 启用系统服务
mkdir -p /etc/systemd/system/graphical.target.wants /etc/systemd/system/multi-user.target.wants
ln -sf /usr/lib/systemd/system/sddm.service /etc/systemd/system/graphical.target.wants/sddm.service
ln -sf /usr/lib/systemd/system/NetworkManager.service /etc/systemd/system/multi-user.target.wants/NetworkManager.service

# 配置 Plymouth 图形化启动动画（替代文本滚动，类似 Windows 启动界面）
if command -v plymouth-set-default-theme >/dev/null 2>&1; then
  plymouth-set-default-theme spinfinity || true
fi

# 编译并安装自研 Qt 应用（源码由 build.sh 同步至 /opt/*-src）
build_qt_app() {
  local src="$1" bin="$2"
  if [ -d "$src" ]; then
    cd "$src"
    cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
    cmake --build build -j"$(nproc 2>/dev/null || echo 4)"
    install -Dm755 "build/$bin" "/usr/bin/$bin"
    rm -rf "$src/build"
  fi
}

build_qt_app /opt/xos-shell-src   xos-shell
build_qt_app /opt/xos-settings-src xos-settings

# 刷新字体缓存
fc-cache -f >/dev/null 2>&1 || true
