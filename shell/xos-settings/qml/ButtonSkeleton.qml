import QtQuick 2.15

// 通用按钮（骨架阶段：仅做占位交互）
Rectangle {
    id: btn
    property string label: "按钮"
    signal clicked()

    width: Math.max(140, labelText.width + 40)
    height: 40
    radius: 8
    color: "#89b4fa"

    Text {
        id: labelText
        anchors.centerIn: parent
        text: btn.label
        color: "#11111b"
        font.pixelSize: 14
        font.bold: true
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: btn.color = "#b4befe"
        onExited: btn.color = "#89b4fa"
        onClicked: btn.clicked()
    }
}
