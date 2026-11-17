import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: page
    title: "Focus Mode"
    readonly property var f: backend.settings.focus

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing * 2

        RowLayout {
            spacing: Kirigami.Units.largeSpacing * 2
            Kirigami.Icon {
                source: "focuswave-focus"
                implicitWidth: Kirigami.Units.iconSizes.huge
                implicitHeight: implicitWidth
                isMask: true
                color: Kirigami.Theme.highlightColor
            }
            ColumnLayout {
                Layout.fillWidth: true
                Kirigami.Heading { level: 2; text: "Focus on one window" }
                QQC2.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: "Everything except the window you're using gets blurred, until you turn it off."
                }
            }
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: true
            type: Kirigami.MessageType.Positive
            text: "Turn it on with <b>" + backend.focusShortcut + "</b>, the Focus button in the top bar, "
                  + "or right-click a window's title bar and pick Focus Mode.<br>"
                  + "Turn it off the same way, or double-click the blurred area."
        }

        QQC2.Button {
            Layout.alignment: Qt.AlignHCenter
            text: "Try it on this window"
            icon.name: "focuswave-focus"
            highlighted: true
            onClicked: backend.tryFocusMode()
        }

        Kirigami.FormLayout {
            Layout.fillWidth: true
            RowLayout {
                Kirigami.FormData.label: "Blur:"
                QQC2.Label { text: "Soft" }
                QQC2.Slider {
                    from: 1; to: 15; stepSize: 1
                    value: page.f.blur
                    onMoved: backend.set("focus.blur", value)
                }
                QQC2.Label { text: "Strong" }
            }
            RowLayout {
                Kirigami.FormData.label: "Darken the background:"
                QQC2.Slider {
                    id: dim
                    from: 0; to: 80; stepSize: 5
                    value: page.f.dim
                    onMoved: backend.set("focus.dim", value)
                }
                QQC2.Label { text: Math.round(dim.value) + "%" }
            }
            QQC2.Switch {
                Kirigami.FormData.label: "Keep dock & top bar visible:"
                checked: page.f.keepDock
                onToggled: backend.set("focus.keepDock", checked)
            }
            QQC2.Switch {
                Kirigami.FormData.label: "Follow app switching:"
                text: "Switching apps (dock, Alt+Tab) moves the focus to that app"
                checked: page.f.follow
                onToggled: backend.set("focus.follow", checked)
            }
            QQC2.Switch {
                Kirigami.FormData.label: "Fade in and out:"
                checked: page.f.fade
                onToggled: backend.set("focus.fade", checked)
            }
            RowLayout {
                Kirigami.FormData.label: "Fade duration:"
                enabled: page.f.fade
                QQC2.Slider {
                    id: fadeMs
                    from: 80; to: 600; stepSize: 20
                    value: page.f.fadeMs
                    onMoved: backend.set("focus.fadeMs", value)
                }
                QQC2.Label { text: Math.round(fadeMs.value) + " ms" }
            }
            QQC2.Button {
                Kirigami.FormData.label: "Keyboard shortcut:"
                text: "Change in Shortcuts settings…"
                icon.name: "preferences-desktop-keyboard-shortcut"
                onClicked: backend.openSettings("kcm_keys")
            }
        }
    }
}
