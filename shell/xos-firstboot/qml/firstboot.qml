import QtQuick
import QtQuick.Window
import QtQuick.Layouts

Window {
    id: root
    visibility: Window.FullScreen
    color: "#0b0e14"

    // 地区 → 时区 / 语言 映射（友好国家名）
    property var regions: [
        { name: "中国",     flag: "🇨🇳", tz: "Asia/Shanghai",    locale: "zh_CN.UTF-8" },
        { name: "加拿大",   flag: "🇨🇦", tz: "America/Toronto",  locale: "en_CA.UTF-8" },
        { name: "美国",     flag: "🇺🇸", tz: "America/New_York", locale: "en_US.UTF-8" },
        { name: "日本",     flag: "🇯🇵", tz: "Asia/Tokyo",       locale: "ja_JP.UTF-8" },
        { name: "英国",     flag: "🇬🇧", tz: "Europe/London",    locale: "en_GB.UTF-8" },
        { name: "德国",     flag: "🇩🇪", tz: "Europe/Berlin",    locale: "de_DE.UTF-8" },
        { name: "法国",     flag: "🇫🇷", tz: "Europe/Paris",     locale: "fr_FR.UTF-8" },
        { name: "韩国",     flag: "🇰🇷", tz: "Asia/Seoul",       locale: "ko_KR.UTF-8" },
        { name: "澳大利亚", flag: "🇦🇺", tz: "Australia/Sydney", locale: "en_AU.UTF-8" },
        { name: "新加坡",   flag: "🇸🇬", tz: "Asia/Singapore",   locale: "en_SG.UTF-8" }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 64
        spacing: 28

        Text {
            text: "欢迎使用 X OS"
            font.pixelSize: 42
            font.bold: true
            color: "#e6e9f0"
            Layout.alignment: Qt.AlignHCenter
        }
        Text {
            text: "请选择您的地区，我们将据此设置时区与语言"
            font.pixelSize: 18
            color: "#8b949e"
            Layout.alignment: Qt.AlignHCenter
        }

        GridLayout {
            columns: 5
            rowSpacing: 20
            columnSpacing: 20
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 20

            Repeater {
                model: root.regions
                Rectangle {
                    id: card
                    width: 240
                    height: 96
                    radius: 14
                    color: "#161b22"
                    border.color: "#30363d"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: modelData.flag + "  " + modelData.name
                        font.pixelSize: 22
                        font.bold: true
                        color: "#e6e9f0"
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: card.color = "#1f6feb"
                        onExited: card.color = "#161b22"
                        onClicked: {
                            FirstBoot.apply(modelData.tz, modelData.locale)
                            FirstBoot.finish()
                        }
                    }
                }
            }
        }
    }
}
