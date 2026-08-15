# X OS 设计规格文档（Design Specification）

> 阶段：M0 概念验证 → **阶段1 基础系统打磨** · 路线：基于 **Linux LTS** 的 **x86_64 图形化发行版（distro）**
> 来源规划：`C:\Users\Administrator\Desktop\X OS.md`（基于开源项目构建图形化操作系统）
> 配套代码：本仓库 `iso/`（Archiso 配置骨架）、`shell/xos-shell/`（桌面 Shell）、`shell/xos-settings/`（设置中心）

本文档将原始规划的 8 段结构，逐一定义为 X OS 作为 Linux 发行版的**设计目标 + 实现要点 + 关键选型 + 与代码/阶段的映射**，确保规划可执行、逻辑递进。

---

## 0. 总体架构（分层）

```
┌─────────────────────────────────────────────┐
│ 应用层      Firefox / LibreOffice / 微信 / VS Code │
├─────────────────────────────────────────────┤
│ 桌面环境层  X OS Shell（自研 Qt6/QML）：面板/启动器/通知 │
├─────────────────────────────────────────────┤
│ 图形栈层    Wayland + labwc(wlroots) + Mesa(llvmpipe) │
├─────────────────────────────────────────────┤
│ 系统服务层  systemd / NetworkManager / PipeWire / BlueZ / polkit │
├─────────────────────────────────────────────┤
│ 基础系统层  GNU 工具链 / glibc / pacman 包管理 │
├─────────────────────────────────────────────┤
│ 内核层      Linux LTS（x86_64，宏内核）          │
└─────────────────────────────────────────────┘
```

X OS 不重写内核与系统服务，而是**选型、集成、定制与体验优化**（文档 §2、§7）。

---

## 1. 系统架构设计

**设计目标**
- 明确"内核态 / 系统服务 / 桌面 / 应用"职责边界，使各层选型与集成有统一准绳。
- 保证二进制兼容：能直接运行常规 Linux 软件与 Flatpak 应用。

**实现要点**
- **内核类型**：Linux 宏内核（x86_64）。仅裁剪/定制 `defconfig`（关闭无用模块，开启 `CONFIG_APPARMOR`、`CONFIG_CGROUPS_V2`、`CONFIG_ZRAM`、`CONFIG_KVM`）。
- **系统调用接口**：沿用 Linux x86_64 syscall ABI（`syscall` 指令 + `unistd_64.h` 编号）。用户态经 glibc 封装；X OS 不引入私有 syscall。
- **驱动模型**：Linux 内核模块 + `linux-firmware` 固件；用户态 HAL 由 `udev` + `libinput` + `Mesa` 提供。专有驱动（NVIDIA）走 DKMS/可选包。
- **分层职责**：见 §0；各层由成熟开源项目构成，X OS 负责集成与定制。

**代码映射**：`iso/profiles/xos/packages.x86_64`（内核与基础包清单）、`docs/X_OS_Design_Spec.md §0`。
**阶段映射**：原始文档 §3 全部选型落地于此层。

---

## 2. 启动流程

**设计目标**：定义从固件到桌面 Shell 的完整、可控、可回滚启动链。

**实现要点（端到端）**
1. **固件**：UEFI（Secure Boot 可选）/ BIOS legacy 回退。
2. **引导加载器**：UEFI 用 `systemd-boot`（简洁）或 GRUB2；BIOS 用 GRUB2。生成对应启动项。
3. **内核 + initramfs**：Linux LTS + `initramfs`（mkinitcpio/dracut），挂载根（后续接入 OSTree 部署根）。
4. **PID1 = systemd**：切到 `graphical.target`。
5. **显示管理器**：SDDM（定制主题）启动 Wayland 会话。
6. **合成器**：`labwc`（wlroots 合成器）作为 compositor 占位，读取 `/etc/xos/labwc/` 配置。
7. **桌面 Shell**：`xos-shell`（Qt6/QML）经 labwc `autostart` 自启动，渲染面板与启动器。
8. **回滚钩子**：后续阶段接入 OSTree，`ostree admin rollback` 在启动失败时自动切换。

**代码映射**：
- `iso/profiles/xos/airootfs/etc/sddm.conf.d/10-xos.conf`
- `iso/profiles/xos/airootfs/etc/xos/labwc/{rc.xml,environment,autostart}`
- `iso/profiles/xos/airootfs/usr/share/wayland-sessions/xos.desktop`
- `iso/profiles/xos/airootfs/root/customize_airootfs.sh`（启用 sddm / NetworkManager）

**阶段映射**：原始文档 §4 阶段0（虚拟机启动至图形桌面）。

---

## 3. 内存管理

**设计目标**：复用 Linux 成熟内存子系统，通过发行版级调优保障"空闲桌面 < 1.5 GB、低配机流畅"。

**实现要点**
- **物理内存**：复用 Linux buddy（页帧分配）+ slab（内核对象缓存）；不重写。
- **虚拟内存**：复用 Linux 4 级页表 + 缺页处理；开启 `KPTI` 安全项。
- **发行版级策略**：
  - `zram` 压缩交换（默认开启，降低磁盘 IO）。
  - `systemd-oomd` + cgroup v2 内存上限，防单应用拖垮系统。
  - `swappiness` 调优；为桌面 slice 设内存预算。
  - 空闲服务惰性启动（socket/timer 激活），压低常驻内存。

**阶段映射**：原始文档 §4 阶段4（空闲 < 1.5 GB）。

---

## 4. 进程与调度

**设计目标**：复用 Linux 调度与进程模型，以 systemd 单元化 + 资源切片实现稳定、可恢复的进程管理。

**实现要点**
- **进程/线程模型**：Linux `task_struct`；线程即共享地址空间的轻量 task。不自定义。
- **调度算法**：默认 `CFS`（或新版 `EEVDF`）；桌面交互任务提 `nice`，后台降权。
- **进程管理**：全部以 systemd **unit** 表达（`.service`/`.socket`/`.timer`/`.slice`）；崩溃自动 `Restart=`，失败不影响系统。
- **IPC 机制**：
  - 系统级：`D-Bus`（system/session bus）用于服务通信与策略。
  - 传统：`pipe` / `socket` / POSIX 共享内存。
  - 图形/UI：Wayland 协议（client↔compositor）承载 UI IPC。

**代码映射**：`packages.x86_64` 中的 systemd / NetworkManager / PipeWire / BlueZ / polkit；`xos-shell` 通过 `QProcess` 启动应用（进程级 IPC）。
**阶段映射**：原始文档 §3.4 / §3.10 系统服务。

---

## 5. 文件系统

**设计目标**：确定默认文件系统与目录布局，支撑原子更新与用户数据隔离。

**实现要点**
- **文件系统类型**：根采用 **btrfs**（快照/子卷，便于回滚）或 ext4；家庭/数据分区 btrfs。
- **不可变根（OSTree）**：`/usr` 只读、`/etc` 与 `/var` 可变、`/home` 独立；系统更新 = 部署新 OSTree 提交并切换 boot 指针，旧提交保留可回滚（原始文档 §3.13）。
- **目录结构**：遵循 FHS + OSTree 约定：`/ostree`、`/usr`、`/etc`、`/var`、`/home`、`/run`(tmpfs)。Flatpak 仓库置于 `/var/lib/flatpak` 与 `~/.local/share/flatpak`。
- **存储管理**：LVM/btrfs 子卷；安装器（Calamares）负责分区、LUKS 加密（可选）、挂载。

**阶段映射**：原始文档 §4 阶段1（Calamares 分区/安装）+ 原子更新机制。

**阶段1 落地进度**
- ✅ **Calamares 安装器配置**：`airootfs/etc/calamares/`（settings.conf + 各模块 `.conf`）已就绪，覆盖欢迎/区域/键盘/分区/用户/网络/引导/卸载全流程；启动器「安装」按钮与 `xos-install.desktop` 已接入。
- ✅ **OSTree 原子更新桩**：`usr/bin/xos-update` 提供 `--status` / `--apply` / `--rollback`（默认预览，Live 环境不真实改动），对应 §8「更新失败自动回滚」。

---

## 6. 设备驱动

**设计目标**：以 Linux 驱动生态为主，发行版侧提供自动硬件探测与 HAL 抽象，覆盖用户最关心的显卡/Wi-Fi/触控板。

**实现要点**
- **硬件抽象层（HAL）**：`udev`（设备枚举/命名）+ `libinput`（键鼠/触控板/触摸屏）+ `Mesa`（GPU OpenGL/Vulkan）。
- **驱动加载机制**：内核模块按需 `modprobe`；固件由 `linux-firmware` 提供；热插拔经 udev 规则触发用户态服务。
- **关键硬件策略**（原始文档 §4 阶段1）：
  - 显卡：Intel/AMD 开源驱动默认；NVIDIA 专有驱动作为可选包（DKMS）。
  - Wi-Fi：集成常见固件包（iwlwifi / brcmfmac 等）。
  - 输入：libinput 统一手势/触控板；支持高分辨滚轮、多指手势。

**代码映射**：`packages.x86_64` 含 `linux-firmware`、`mesa`、`libinput`；`labwc` 经 `libinput` 处理输入。
**阶段映射**：原始文档 §4 阶段1 "配置自动硬件检测"。

---

## 7. 用户界面

**设计目标**：打造统一、流畅、直觉的图形桌面（Wayland），覆盖面板、启动器、窗口管理、通知与动效。

**实现要点（自研 X OS Shell，Qt 6/QML）**
- **图形协议/合成器**：Wayland + `labwc`（wlroots）占位；`QT_QPA_PLATFORM=wayland`。
- **桌面 Shell 组件（M0 已实现）**：
  - 顶部面板：应用菜单按钮 + 时钟。
  - 启动器：点击菜单弹出，含「终端 / 文件 / 浏览器」应用按钮，`Shell.launch(cmd)` 启动。
- **阶段1 新增**（详见 `shell/xos-settings/` 与 `usr/bin/xos-update`）：
  - **设置中心 `xos-settings`**：独立 Qt6/QML 应用，左侧分类导航（网络/显示/声音/蓝牙/电源/用户/更新），右侧占位面板；分类实际控制逻辑待阶段2 接入。启动器与 `xos-settings.desktop` 已接入。
  - **更新入口**：启动器新增「更新」按钮（`alacritty -e xos-update`）；「安装」按钮接入 Calamares。
  - **输入法 / 高 DPI**：`fcitx5` 经 labwc `autostart` 启动；`environment` 注入 `GTK_IM_MODULE/QT_IM_MODULE/XMODIFIERS` 与缩放变量。
- **后续阶段（原始文档 §4 阶段2）**：任务栏/窗口预览/系统托盘、Spotlight 式搜索、浮动/平铺窗口管理、通知中心、触控板手势、统一设计系统（图标/主题/字体/动效/深浅色）、Plymouth 启动画面、SDDM 登录定制。

**代码映射**：`shell/xos-shell/`（C++ + QML 源码）、`shell/xos-settings/`（设置中心源码）、`airootfs/etc/xos/labwc/`（合成器配置）、`airootfs/usr/share/wayland-sessions/xos.desktop`。
**阶段映射**：原始文档 §4 阶段0（最简 Shell）→ 阶段1（设置/更新骨架）→ 阶段2（完整桌面体验）。

---

## 8. 安全机制

**设计目标**：在 Linux 安全基座上，提供清晰、默认隐私友好的权限与隔离策略。

**实现要点**
- **权限模型**：Linux DAC（user/group/perm）+ `polkit` 控制提权（如设置中心改网络/用户）。
- **应用隔离**：Flatpak 沙箱（`bubblewrap`）+ Portals 受控访问文件/网络/设备；默认不授予全部权限。
- **强制访问控制**：启用 **AppArmor**（或 SELinux）MAC，为系统服务与桌面组件设轮廓。
- **用户隔离**：每用户独立 `/home` 与 Flatpak 仓库；`systemd-homed` 可选加密家目录。
- **隐私**：默认不收集遥测、无广告、无追踪；权限弹窗透明（原始文档 §5）。
- **安全启动/回滚**：UEFI Secure Boot 可选；更新失败自动回滚（OSTree）。

**阶段映射**：原始文档 §4 阶段1（polkit/权限透明）+ 阶段4（更新回滚、隐私）。

---

## 9. 代码仓库结构与 M0 交付

```
X OS/
├─ README.md                     # 构建与运行说明
├─ .github/workflows/
│  └─ build-iso.yml              # GitHub Actions：Docker 构建 ISO 并上传 Artifact
├─ docs/
│  └─ X_OS_Design_Spec.md        # 本规格文档
├─ iso/
│  ├─ build.sh                   # Arch 主机构建入口
│  ├─ Dockerfile                 # 容器化构建（archlinux）
│  ├─ docker-build.sh            # 一键容器构建
│  └─ profiles/xos/              # Archiso 配置骨架
│     ├─ packages.x86_64
│     ├─ pacman.conf
│     └─ airootfs/               # 根文件系统覆盖层
│        ├─ etc/{sddm.conf.d,xos/labwc,calamares}
│        ├─ usr/{bin/xos-update, share/applications/xos-*.desktop, share/wayland-sessions/xos.desktop}
│        └─ root/customize_airootfs.sh   # 编译 xos-shell + xos-settings + 启用服务
├─ shell/xos-shell/              # 自研桌面 Shell 源码（C++ + QML）
│  ├─ CMakeLists.txt
│  ├─ src/{main.cpp, shellcontroller.h, shellcontroller.cpp}
│  └─ qml/{main.qml, Launcher.qml, LauncherButton.qml}
├─ shell/xos-settings/           # 自研设置中心源码（C++ + QML，阶段1骨架）
│  ├─ CMakeLists.txt
│  ├─ src/{main.cpp, settingscontroller.h, settingscontroller.cpp}
│  └─ qml/{Settings.qml, ButtonSkeleton.qml}
└─ run-qemu.sh                   # 启动产出 ISO 验证桌面
```

**M0 验收清单**
- [x] 设计规格文档覆盖全部 8 模块，每模块含"设计目标 + 实现要点 + 选型 + 阶段映射"。
- [x] 骨架仓库完整：Archiso 配置 + xos-shell 源码 + 构建/运行脚本。
- [ ] `build.sh`（Arch 主机或 Docker）成功产出可启动 `xos-*.iso`（沙箱禁用，改用 GitHub Actions 产出）。
- [ ] QEMU 中启动至 Wayland + 最小 `xos-shell` 桌面，键鼠/分辨率正常。
- [ ] 启动链含 systemd → SDDM → labwc(Wayland) → xos-shell，并预留 OSTree 回滚钩子。

**阶段1 验收清单**
- [x] Calamares 安装器配置（welcome→…→finished 全流程 `.conf`）+ 启动器「安装」入口。
- [x] 设置中心 `xos-settings`（分类占位 UI）+ 启动器「设置」入口 + `.desktop`。
- [x] 原子更新桩 `xos-update`（OSTree `--status/--apply/--rollback`，默认预览）+ 启动器「更新」入口。
- [x] fcitx5 中文输入 + 高 DPI 环境变量（`environment` / `autostart`）。
- [x] 硬件/电源/蓝牙支撑包（bluez、power-profiles-daemon、sof-firmware、vulkan-intel/radeon）。
- [x] GitHub Actions 构建流水线 `.github/workflows/build-iso.yml`（产出 ISO Artifact）。

> 注：构建 / QEMU 验证需在有 Arch Linux / Docker 的环境（或 GitHub Actions）中执行，当前沙箱禁用系统级工具，无法本地产出 `.iso`。详见 `README.md`。
