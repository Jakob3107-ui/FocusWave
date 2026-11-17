// Window button style: macOS traffic lights or Windows-style buttons.
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Flow {
    id: root
    property string current: "mac"
    property bool dark: false
    property bool decorationAvailable: true
    signal picked(string style)

    spacing: Kirigami.Units.largeSpacing

    Repeater {
        model: [
            { id: "mac", name: "Traffic lights", desc: "Colored buttons on the left" },
            { id: "windows", name: "Windows style", desc: "Minimize, maximize, close on the right" }
        ]
        delegate: ChoiceCard {
            required property var modelData
            width: Kirigami.Units.gridUnit * 12
            label: modelData.name
            sublabel: modelData.id === "mac" && !root.decorationAvailable
                      ? "Buttons on the left (traffic-light colors not installed)" : modelData.desc
            selected: root.current === modelData.id
            onClicked: root.picked(modelData.id)

            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.9
                height: parent.height * 0.62
                radius: Kirigami.Units.largeSpacing
                color: root.dark ? "#1E1E22" : "#F3F3F6"
                border.color: Qt.rgba(0, 0, 0, 0.12)
                Row {
                    visible: modelData.id === "mac"
                    x: Kirigami.Units.largeSpacing
                    y: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing * 2
                    Repeater {
                        model: ["#FF5F57", "#FEBC2E", "#28C840"]
                        Rectangle { width: Kirigami.Units.gridUnit * 0.8; height: width; radius: width / 2; color: modelData }
                    }
                }
                Row {
                    visible: modelData.id === "windows"
                    anchors.right: parent.right
                    anchors.rightMargin: Kirigami.Units.largeSpacing
                    y: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.largeSpacing * 1.5
                    Repeater {
                        model: ["window-minimize-symbolic", "window-maximize-symbolic", "window-close-symbolic"]
                        Kirigami.Icon {
                            width: Kirigami.Units.iconSizes.small; height: width
                            source: modelData
                            color: root.dark ? "#F2F2F7" : "#1D1D1F"
                            isMask: true
                        }
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Kirigami.Units.largeSpacing - 2
                    text: "Window"
                    color: root.dark ? "#F2F2F7" : "#1D1D1F"
                    font.bold: true
                }
            }
        }
    }
}
