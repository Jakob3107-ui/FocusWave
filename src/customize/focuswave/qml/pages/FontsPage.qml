import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: page
    title: "Fonts"
    readonly property var ft: backend.settings.font

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing * 2

        Kirigami.FormLayout {
            Layout.fillWidth: true
            QQC2.ComboBox {
                id: family
                Kirigami.FormData.label: "Interface font:"
                implicitWidth: Kirigami.Units.gridUnit * 16
                model: Qt.fontFamilies()
                Component.onCompleted: currentIndex = Math.max(0, find(page.ft.family))
                onActivated: backend.set("font.family", currentText)
            }
            QQC2.SpinBox {
                id: size
                Kirigami.FormData.label: "Size:"
                from: 8; to: 16
                value: page.ft.size
                onValueModified: backend.set("font.size", value)
            }
            QQC2.ComboBox {
                Kirigami.FormData.label: "Monospace (code) font:"
                implicitWidth: Kirigami.Units.gridUnit * 16
                model: Qt.fontFamilies()
                Component.onCompleted: currentIndex = Math.max(0, find(page.ft.mono))
                onActivated: backend.set("font.mono", currentText)
            }
            QQC2.Button {
                text: "Back to Inter 10"
                icon.name: "edit-undo"
                onClicked: {
                    backend.set("font.family", "Inter")
                    backend.set("font.size", 10)
                    family.currentIndex = Math.max(0, family.find("Inter"))
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: sample.implicitHeight + Kirigami.Units.gridUnit * 2
            radius: Kirigami.Units.largeSpacing
            color: Kirigami.Theme.alternateBackgroundColor
            ColumnLayout {
                id: sample
                anchors.fill: parent
                anchors.margins: Kirigami.Units.gridUnit
                QQC2.Label {
                    text: "The quick brown fox jumps over the lazy dog"
                    font.family: family.currentText
                    font.pointSize: size.value + 6
                    font.weight: Font.DemiBold
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: "This is how menus, buttons and window titles will look. 0123456789"
                    font.family: family.currentText
                    font.pointSize: size.value
                }
            }
        }
    }
}
