import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15

// X OS 设置中心（阶段1骨架）：左侧分类导航 + 右侧占位面板
// 各分类的实际控制逻辑（网络/显示/声音/蓝牙/电源/用户）将在阶段2接入。
Window {
    id: root
    width: 860
    height: 560
    x: Math.round((Screen.width - width) / 2)
    y: Math.round((Screen.height - height) / 2)
    color: "#11111b"
    title: "X OS 设置"
    visible: true

    // 分类数据：名称 + 当前占位说明
    property var categories: [
        { name: "网络",  desc: "网络与连接管理。\n阶段2将接入 NetworkManager：查看 Wi-Fi / 有线状态、扫描并连接热点、配置代理与 DNS。", action: "" },
        { name: "显示",  desc: "显示器与外观。\n阶段2将接入亮度调节、分辨率/刷新率、缩放与夜间模式。", action: "" },
        { name: "声音",  desc: "音频输出与输入。\n阶段2将接入 PipeWire：选择默认设备、调节音量、配置应用级音频路由。", action: "" },
        { name: "蓝牙",  desc: "蓝牙设备配对。\n阶段2将接入 BlueZ：扫描设备、配对/连接耳机与键鼠、管理已配对列表。", action: "" },
        { name: "电源",  desc: "电源与性能。\n阶段2将接入 power-profiles-daemon：平衡/性能/省电模式、休眠与盖子行为。", action: "" },
        { name: "用户",  desc: "账户与权限。\n阶段2将接入用户管理：修改密码、头像、自动登录与 sudo 策略。", action: "" },
        { name: "更新",  desc: "系统更新（OSTree / A-B 原子更新）。\n点击右侧按钮运行 xos-update 检查并应用更新，支持失败回滚。", action: "xos-update" }
    ]
    property int current: 0

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // 左侧分类导航
        ColumnLayout {
            Layout.preferredWidth: 200
            Layout.fillHeight: true
            spacing: 4
            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 8; color: "#11111b" }

            Repeater {
                model: root.categories
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    color: index === root.current ? "#313244" : "#1e1e2e"
                    radius: 6
                    Text {
                        anchors.centerIn: parent
                        text: modelData.name
                        color: "#cdd6f4"
                        font.pixelSize: 15
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.current = index
                    }
                }
            }
            Item { Layout.fillHeight: true }
        }

        // 右侧内容面板
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#1e1e2e"

            ColumnLayout {
                anchors { fill: parent; margins: 28 }
                spacing: 18

                Text {
                    Layout.fillWidth: true
                    text: root.categories[root.current].name
                    color: "#cdd6f4"
                    font.pixelSize: 26
                    font.bold: true
                }

                Text {
                    Layout.fillWidth: true
                    text: root.categories[root.current].desc
                    color: "#a6adc8"
                    font.pixelSize: 15
                    wrapMode: Text.Wrap
                    lineHeight: 1.5
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.alignment: Qt.AlignLeft
                    ButtonSkeleton {
                        visible: root.categories[root.current].action !== ""
                        label: "运行 " + root.categories[root.current].action
                        onClicked: Settings.launch(root.categories[root.current].action)
                    }
                    ButtonSkeleton {
                        label: "关闭"
                        onClicked: root.close()
                    }
                }
            }
        }
    }
}
