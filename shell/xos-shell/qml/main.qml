import QtQuick 2.15
import QtQuick.Window 2.15

// X OS 顶部面板：左侧菜单按钮 + 右侧时钟
Window {
    id: root
    width: Screen.width
    height: 40
    x: 0
    y: 0
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: "#11111b"
    visible: true
    title: "X OS Shell"

    // 左侧「X OS」菜单按钮
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 96
        color: "#1e1e2e"
        Text {
            anchors.centerIn: parent
            text: "X OS"
            color: "#cdd6f4"
            font.pixelSize: 16
            font.bold: true
        }
        MouseArea {
            anchors.fill: parent
            onClicked: launcher.visible = !launcher.visible
        }
    }

    // 右侧时钟
    Text {
        id: clock
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 14
        text: Qt.formatTime(new Date(), "hh:mm")
        color: "#cdd6f4"
        font.pixelSize: 14
        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: clock.text = Qt.formatTime(new Date(), "hh:mm")
        }
    }

    Launcher { id: launcher }
}
