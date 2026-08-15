# xos-shell — X OS 自研桌面 Shell（M0）

一个最小化的 Wayland 桌面 Shell，使用 **Qt 6 + QML** 实现：

- 顶部面板：左侧「X OS」菜单按钮，右侧实时时钟。
- 启动器：点击菜单按钮居中弹出，含「终端 / 文件 / 浏览器」入口，由 `Shell.launch(cmd)`（C++ `QProcess`）启动外部程序。

## 依赖

- Qt6：`Qt6::Gui` `Qt6::Qml` `Qt6::Quick`
- 运行环境：Wayland 合成器（M0 为 `labwc`），并设置 `QT_QPA_PLATFORM=wayland`

## 构建

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
```

## 安装

```bash
cmake --install build
# 二进制 -> /usr/bin/xos-shell
# QML    -> /usr/share/xos-shell/
```

> 在 X OS ISO 构建中，`customize_airootfs.sh` 会自动完成上述编译与安装。
