import QtQuick 2.15
import QtQuick.Window 2.15

// X OS 应用启动器：点击面板菜单后居中弹出
Window {
    id: launcher
    width: 520
    height: 360
    x: Math.round((Screen.width - width) / 2)
    y: Math.round((Screen.height - height) / 2)
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: "#1e1e2e"
    title: "X OS Launcher"
    visible: false

    Column {
        anchors.centerIn: parent
        spacing: 16
        LauncherButton { appName: "终端";   cmd: "alacritty" }
        LauncherButton { appName: "文件";   cmd: "pcmanfm" }
        LauncherButton { appName: "浏览器"; cmd: "firefox" }
        LauncherButton { appName: "设置";   cmd: "xos-settings" }
        LauncherButton { appName: "更新";   cmd: "alacritty -e xos-update" }
        LauncherButton { appName: "安装";   cmd: "sudo calamares" }
    }
}
