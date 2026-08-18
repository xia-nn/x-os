#!/bin/bash
#
# Archiso 钩子：在 chroot 内构建阶段执行
#  - 创建自动登录用户 live
#  - 启用 sddm / NetworkManager 服务
#  - 从 /opt/xos-*-src 编译并安装自研 Qt 应用（含 xos-firstboot OOBE 向导）
#
set -e

# 创建自动登录用户（若已存在则忽略）
if ! id live >/dev/null 2>&1; then
  useradd -m -G wheel,audio,video,input -s /bin/bash live
fi

# 允许 wheel 组无密码 sudo（演示用，后续收紧）
echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/xos

# 预配置 Live 环境，避免 systemd-firstboot 交互式询问 root 密码
systemd-machine-id-setup || true
echo "xos-live" > /etc/hostname
# 默认时区/语言（OOBE 向导首次启动时会按用户选择覆盖）
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo "LANG=zh_CN.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf
# 生成 OOBE 向导与桌面所需的多语言 locale（中/加/美/日/英/德/法/韩/澳/新）
for l in zh_CN en_US en_CA en_GB en_AU en_SG ja_JP ko_KR de_DE fr_FR; do
  sed -i "s/^#\($l\.UTF-8\)/\1/" /etc/locale.gen
done
locale-gen || true
# 演示用 root 密码，避免 firstboot 卡住
echo "root:root" | chpasswd

# 首次设置完成标志目录（OOBE 向导写入 /var/lib/xos/firstboot-done）
mkdir -p /var/lib/xos

# 启用系统服务
mkdir -p /etc/systemd/system/multi-user.target.wants
ln -sf /usr/lib/systemd/system/NetworkManager.service /etc/systemd/system/multi-user.target.wants/NetworkManager.service

# labwc 启动脚本：由 rc.xml autostart 调用，此时 Wayland socket 已就绪
cat > /etc/xos/labwc/autostart <<'AEOF'
#!/bin/sh
mkdir -p /tmp/xos

# 中文输入法守护进程
fcitx5 >/tmp/xos/fcitx5.log 2>&1 &

# 首次启动运行 OOBE 向导（选地区/时区），完成后进入桌面
if [ ! -f /var/lib/xos/firstboot-done ]; then
  xos-firstboot >/tmp/xos/firstboot.log 2>&1 || true
fi

# X OS 桌面 Shell（面板 + 启动器）
xos-shell >/tmp/xos/shell.log 2>&1 &
AEOF
chmod 755 /etc/xos/labwc/autostart

# X OS 会话入口脚本：自动登录后前台启动 labwc（桌面组件由 labwc autostart 拉起）
cat > /usr/bin/xos-session <<'SEOF'
#!/bin/sh
# X OS session entry: launch labwc Wayland composizer
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=labwc
export XDG_SESSION_DESKTOP=labwc
exec labwc -C /etc/xos/labwc
SEOF
chmod 755 /usr/bin/xos-session

# 自动登录 live 用户并直接进入 X OS 会话（绕过 SDDM，对虚拟机/裸金属更稳健）
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf <<'AEOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin live --noclear %I $TERM
AEOF

mkdir -p /home/live
cat > /home/live/.bash_profile <<'BEOF'
if [ -z "$WAYLAND_DISPLAY" ] && [ -z "$DISPLAY" ] && [ "$(tty 2>/dev/null)" = "/dev/tty1" ]; then
  exec xos-session
fi
BEOF
chown live:live /home/live/.bash_profile
chmod 644 /home/live/.bash_profile

# 默认启动到图形目标
ln -sf /usr/lib/systemd/system/graphical.target /etc/systemd/system/default.target

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
build_qt_app /opt/xos-firstboot-src xos-firstboot

# 刷新字体缓存
fc-cache -f >/dev/null 2>&1 || true
