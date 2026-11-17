// Accent color picker: preset swatches + a custom color.
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Flow {
    id: root
    property string current: "#6E5BFF"
    signal picked(string color)

    readonly property var colors: ["#6E5BFF", "#3D7EFF", "#0EA5E9", "#14B8A6", "#22C55E",
                                   "#EAB308", "#F97316", "#EF4444", "#EC4899", "#A855F7", "#8E8E93"]
    spacing: Kirigami.Units.smallSpacing * 2

    Repeater {
        model: root.colors
        delegate: Rectangle {
            required property string modelData
            width: Kirigami.Units.gridUnit * 2
            height: width
            radius: width / 2
            color: modelData
            border.width: root.current.toUpperCase() === modelData.toUpperCase() ? 3 : 0
            border.color: Kirigami.Theme.textColor
            Kirigami.Icon {
                anchors.centerIn: parent
                width: parent.width * 0.55; height: width
                visible: root.current.toUpperCase() === modelData.toUpperCase()
                source: "checkmark"
                color: "white"
                isMask: true
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.picked(modelData)
            }
        }
    }

    QQC2.RoundButton {
        width: Kirigami.Units.gridUnit * 2
        height: width
        icon.name: "color-picker"
        QQC2.ToolTip.text: "Pick any color"
        QQC2.ToolTip.visible: hovered
        onClicked: colorDialog.open()
    }

    ColorDialog {
        id: colorDialog
        title: "Choose an accent color"
        selectedColor: root.current
        onAccepted: root.picked(selectedColor.toString())
    }
}
