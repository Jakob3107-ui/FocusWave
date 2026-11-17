import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: page
    title: "Advanced"

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "FocusWave is built on KDE Plasma, one of the most customizable desktops there is. "
                  + "Everything below opens the full Plasma settings for that area."
        }

        GridLayout {
            Layout.fillWidth: true
            columns: page.width > Kirigami.Units.gridUnit * 36 ? 2 : 1
            columnSpacing: Kirigami.Units.largeSpacing
            rowSpacing: Kirigami.Units.largeSpacing

            Repeater {
                model: [
                    { text: "Edit desktop, panels & widgets", icon: "edit-entry", kcm: "@edit" },
                    { text: "Colors", icon: "preferences-desktop-color", kcm: "kcm_colors" },
                    { text: "Icons", icon: "preferences-desktop-icons", kcm: "kcm_icons" },
                    { text: "Window decorations", icon: "preferences-system-windows-actions", kcm: "kcm_kwindecoration" },
                    { text: "Desktop effects", icon: "preferences-desktop-effects", kcm: "kcm_kwin_effects" },
                    { text: "Keyboard shortcuts", icon: "preferences-desktop-keyboard-shortcut", kcm: "kcm_keys" },
                    { text: "Displays & scaling", icon: "preferences-desktop-display", kcm: "kcm_kscreen" },
                    { text: "Power & battery", icon: "preferences-system-power-management", kcm: "kcm_powerdevilprofilesconfig" },
                    { text: "Mouse & touchpad", icon: "preferences-desktop-mouse", kcm: "kcm_touchpad" },
                    { text: "All system settings", icon: "preferences-system", kcm: "" }
                ]
                delegate: QQC2.Button {
                    required property var modelData
                    Layout.fillWidth: true
                    text: modelData.text
                    icon.name: modelData.icon
                    onClicked: modelData.kcm === "@edit" ? backend.editDesktop() : backend.openSettings(modelData.kcm)
                }
            }
        }

        Kirigami.Separator { Layout.fillWidth: true; Layout.topMargin: Kirigami.Units.largeSpacing }

        RowLayout {
            Layout.fillWidth: true
            QQC2.Button {
                text: "Run the welcome tour again"
                icon.name: "help-about"
                onClicked: backend.runWelcome()
            }
            QQC2.Button {
                text: "Re-apply everything"
                icon.name: "view-refresh"
                onClicked: backend.applyEverything()
            }
            Item { Layout.fillWidth: true }
            QQC2.Button {
                text: "Reset to FocusWave defaults…"
                icon.name: "edit-reset"
                onClicked: resetDialog.open()
            }
        }
    }

    Kirigami.PromptDialog {
        id: resetDialog
        title: "Reset everything?"
        subtitle: "Colors, wallpaper, layout, window buttons, fonts and Focus Mode go back to the FocusWave defaults. Saved themes are kept."
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
        onAccepted: backend.resetDefaults()
    }
}
