import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: page
    title: "Themes"

    actions: [
        Kirigami.Action {
            text: "Import…"
            icon.name: "document-import"
            onTriggered: importDialog.open()
        },
        Kirigami.Action {
            text: "Export current look…"
            icon.name: "document-export"
            onTriggered: exportDialog.open()
        }
    ]

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing * 2

        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "A theme remembers everything: light/dark, accent, wallpaper, layout, window buttons, fonts and Focus Mode. "
                  + "Save your favorite looks and switch between them in one click, or share them as .fwtheme files."
        }

        RowLayout {
            Layout.fillWidth: true
            QQC2.TextField {
                id: nameField
                Layout.fillWidth: true
                placeholderText: "Name for the current look, e.g. “Cozy evening”"
                onAccepted: saveButton.clicked()
            }
            QQC2.Button {
                id: saveButton
                text: "Save"
                icon.name: "document-save"
                enabled: nameField.text.trim().length > 0
                onClicked: {
                    backend.saveTheme(nameField.text)
                    nameField.text = ""
                }
            }
        }

        Kirigami.PlaceholderMessage {
            Layout.fillWidth: true
            visible: backend.themes.length === 0
            icon.name: "color-management"
            text: "No saved themes yet"
            explanation: "Make it look the way you like, then save it here."
        }

        Repeater {
            model: backend.themes
            delegate: QQC2.ItemDelegate {
                required property var modelData
                Layout.fillWidth: true
                contentItem: RowLayout {
                    spacing: Kirigami.Units.largeSpacing
                    Rectangle {
                        implicitWidth: Kirigami.Units.gridUnit * 1.5
                        implicitHeight: implicitWidth
                        radius: width / 2
                        color: modelData.accent
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        QQC2.Label { text: modelData.name; font.bold: true }
                        QQC2.Label {
                            text: modelData.mode + " · " + modelData.preset + " layout"
                            opacity: 0.7
                            font: Kirigami.Theme.smallFont
                        }
                    }
                    QQC2.Button {
                        text: "Apply"
                        icon.name: "dialog-ok-apply"
                        onClicked: backend.applyTheme(modelData.id)
                    }
                    QQC2.ToolButton {
                        icon.name: "edit-delete"
                        QQC2.ToolTip.text: "Delete"
                        QQC2.ToolTip.visible: hovered
                        onClicked: backend.deleteTheme(modelData.id)
                    }
                }
                onClicked: backend.applyTheme(modelData.id)
            }
        }
    }

    FileDialog {
        id: importDialog
        title: "Import a FocusWave theme"
        nameFilters: ["FocusWave themes (*.fwtheme *.json)"]
        onAccepted: backend.importTheme(selectedFile.toString())
    }
    FileDialog {
        id: exportDialog
        title: "Export the current look"
        fileMode: FileDialog.SaveFile
        defaultSuffix: "fwtheme"
        nameFilters: ["FocusWave themes (*.fwtheme)"]
        onAccepted: backend.exportTheme(selectedFile.toString())
    }
}
