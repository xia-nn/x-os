import QtQuick 2.15

// 启动器中的单个应用按钮；点击后启动对应程序并收起启动器
Rectangle {
    id: btn
    property string appName: ""
    property string cmd: ""
    width: 240
    height: 48
    radius: 8
    color: "#313244"

    Text {
        anchors.centerIn: parent
        text: btn.appName
        color: "#cdd6f4"
        font.pixelSize: 16
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: btn.color = "#45475a"
        onExited: btn.color = "#313244"
        onClicked: {
            Shell.launch(btn.cmd)
            launcher.visible = false
        }
    }
}
