# X OS — 基于 Linux 的图形化操作系统（M0 → 阶段1 骨架）

X OS 是一个基于 **Linux LTS（x86_64）** 的图形化操作系统发行版（distro）。本仓库是 **M0 概念验证 + 阶段1 基础系统打磨** 的骨架：用 Archiso 构建一个可启动的 Live ISO，启动后进入 Wayland 桌面并运行自研的 `xos-shell`（Qt6/QML）桌面 Shell；阶段1 已加入 Calamares 安装器、fcitx5 中文输入、设置中心骨架、OSTree 原子更新桩与硬件/电源/蓝牙支撑。

> 设计依据：`docs/X_OS_Design_Spec.md`（八大模块设计规格）。原始需求见桌面 `X OS.md`。

## 目录结构

```
X OS/
├─ .github/workflows/build-iso.yml  # GitHub Actions：Docker 构建 ISO 并上传 Artifact
├─ docs/X_OS_Design_Spec.md         # 八大模块设计规格
├─ iso/                             # 构建相关
│  ├─ build.sh                      # Arch 主机构建入口
│  ├─ Dockerfile                    # 容器化构建（archlinux）
│  ├─ docker-build.sh               # 一键容器构建
│  └─ profiles/xos/                 # Archiso 配置骨架（含 Calamares / labwc / xos 应用）
├─ shell/xos-shell/                 # 自研桌面 Shell（C++ + QML）
├─ shell/xos-settings/              # 自研设置中心（C++ + QML，阶段1骨架）
└─ run-qemu.sh                      # 启动产出 ISO 验证
```

## 桌面栈（阶段1）

- 引导：`GRUB2` → Linux LTS → `systemd`
- 显示管理：`SDDM`（自动登录用户 `live`）
- 合成器：`labwc`（wlroots，Wayland）
- 桌面 Shell：`xos-shell`（Qt6/QML，顶部面板 + 启动器）
- 设置中心：`xos-settings`（Qt6/QML，网络/显示/声音/蓝牙/电源/用户分类占位）
- 原子更新：`xos-update`（OSTree / A-B 回滚桩，默认预览、可 `--apply`）
- 中文输入：`fcitx5` + `fcitx5-chinese-addons`
- 安装器：`Calamares` 配置已就绪（Live → 硬盘），但 ** calamares 包暂未预装**（它在 AUR 而非官方仓库，后续通过 AUR/chaotic-aur 启用）
- 预装应用：终端 `alacritty`、文件管理器 `pcmanfm`、浏览器 `firefox`
- 系统服务：`systemd`、`NetworkManager`、`PipeWire`/`WirePlumber`、`BlueZ`、`power-profiles-daemon`、`polkit`

## 构建方式

### 方式 A：Arch Linux 主机（推荐）

需要 `archiso` 与 root 权限：

```bash
sudo pacman -S --needed archiso
cd iso
./build.sh
# 产出 iso/out/xos-<date>.iso
```

### 方式 B：Docker（任意支持 Docker 的宿主机）

```bash
cd iso
./docker-build.sh
# 容器内执行 mkarchiso，产出 iso/out/xos-*.iso
```

> Dockerfile 基于 `archlinux:latest`，内部安装 `archiso` 并执行构建；构建出的 ISO 落在 `iso/out/`。

### 方式 C：GitHub Actions（推荐获取 ISO 的方式）

本地开发沙箱禁用了 Docker / 系统级工具，无法在沙箱内直接 `mkarchiso`。仓库已内置 `.github/workflows/build-iso.yml`：

- 推送到 `main` 自动触发，或在 Actions 页面手动 **Run workflow**；
- Runner 上用 Docker（`iso/Dockerfile`）构建，与本地方式 B 完全一致；
- 构建产物 ISO 作为 Artifact（`xos-iso`）提供下载，保留 30 天。

**已成功的构建**：https://github.com/xia-nn/x-os/actions/runs/31868521150
- Artifact `xos-iso` 大小约 1.7 GB，解压后得到 `xos-<date>.iso`。
- 下载后写盘：`dd if=xos-*.iso of=/dev/sdX bs=4M status=progress`（Linux）或用 Rufus（Windows，DD 模式）。

如需本地构建，请使用方式 A（Arch 主机）或方式 B（自带 Docker 的宿主机）。

## 运行验证（QEMU）

```bash
./run-qemu.sh
# 自动寻找 iso/out/xos-*.iso 并以 -cdrom 启动
# 启动后进入 SDDM → 选择 "X OS" 会话 → 桌面显示顶部面板与「X OS」启动器
```

按需调整 `run-qemu.sh`：Linux 用 `-enable-kvm`；无 KVM 时去掉该参数；显示后端可换 `-display sdl` 等。

## 已知限制（阶段1）

- 阶段1 已落地：fcitx5 中文输入、设置中心骨架（`xos-settings`）、OSTree 原子更新桩（`xos-update`）、硬件/电源/蓝牙支撑。设置中心的各分类（网络/显示/声音/蓝牙/电源/用户）目前为占位面板，实际控制逻辑计划在阶段2 接入。
- **Calamares 安装器**：配置文件和桌面项已就绪，但 ISO 中暂未预装 `calamares` 包（它在 AUR 而非官方仓库）。构建成功后才把它从 `packages.x86_64` 中临时注释掉，后续通过 AUR/chaotic-aur 安装后可恢复。
- `xos-update` 默认仅**预览** OSTree 升级流程；在 Live 环境中不执行真实更新（避免改动系统），安装到硬盘（Calamares + OSTree 管理式根）后加 `--apply` 即为真实流程。
- 构建与 QEMU 验证需在 Arch / Docker 环境（或 GitHub Actions）中进行（当前开发沙箱禁用系统级工具，故无法在沙箱内产出 `.iso`）。
