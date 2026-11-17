import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../components"

Kirigami.ScrollablePage {
    id: page
    title: "Layout"
    readonly property var s: backend.settings
    readonly property bool windowsPreset: s.layout.preset === "windows"

    actions: [
        Kirigami.Action {
            text: "Apply to my desktop"
            icon.name: "dialog-ok-apply"
            onTriggered: backend.applyLayout()
        }
    ]

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing * 2

        Preview {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(page.width - Kirigami.Units.gridUnit * 2, Kirigami.Units.gridUnit * 30)
            Layout.preferredHeight: Layout.preferredWidth * 0.625
            dark: backend.previewDark
            accent: page.s.accent
            wallpaper: backend.thumbFor(page.s.wallpaper, backend.previewDark)
            preset: page.s.layout.preset
            topBar: page.s.layout.topBar
            buttons: page.s.buttons
            dockPosition: page.s.layout.dockPosition
            dockFloating: page.s.layout.dockFloating
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: true
            type: Kirigami.MessageType.Information
            text: "Layout changes show up in the preview first. Press “Apply to my desktop” when you like it."
            actions: [
                Kirigami.Action {
                    text: "Apply to my desktop"
                    icon.name: "dialog-ok-apply"
                    onTriggered: backend.applyLayout()
                }
            ]
        }

        Kirigami.Heading { level: 3; text: "Style" }
        PresetPicker {
            Layout.fillWidth: true
            current: page.s.layout.preset
            dark: backend.previewDark
            accent: page.s.accent
            wallpaper: backend.thumbFor(page.s.wallpaper, backend.previewDark)
            onPicked: (preset) => backend.choosePreset(preset)
        }

        Kirigami.FormLayout {
            Layout.fillWidth: true

            Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Top bar" }
            QQC2.Switch {
                Kirigami.FormData.label: "Show top bar:"
                enabled: !page.windowsPreset
                checked: page.s.layout.topBar
                onToggled: backend.set("layout.topBar", checked)
            }
            RowLayout {
                Kirigami.FormData.label: "Height:"
                enabled: !page.windowsPreset && page.s.layout.topBar
                QQC2.Slider {
                    id: topHeight
                    from: 24; to: 44; stepSize: 2
                    value: page.s.layout.topBarHeight
                    onMoved: backend.set("layout.topBarHeight", value)
                }
                QQC2.Label { text: Math.round(topHeight.value) + " px" }
            }

            Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: page.windowsPreset ? "Taskbar" : "Dock" }
            RowLayout {
                Kirigami.FormData.label: "Size:"
                QQC2.Slider {
                    id: dockSize
                    from: 40; to: 80; stepSize: 2
                    value: page.s.layout.dockSize
                    onMoved: backend.set("layout.dockSize", value)
                }
                QQC2.Label { text: Math.round(dockSize.value) + " px" }
            }
            QQC2.ComboBox {
                Kirigami.FormData.label: "Position:"
                enabled: !page.windowsPreset
                textRole: "text"
                valueRole: "value"
                model: [
                    { text: "Bottom", value: "bottom" },
                    { text: "Left", value: "left" },
                    { text: "Right", value: "right" }
                ]
                Component.onCompleted: currentIndex = indexOfValue(page.s.layout.dockPosition)
                onActivated: backend.set("layout.dockPosition", currentValue)
            }
            QQC2.Switch {
                Kirigami.FormData.label: "Floating:"
                checked: page.s.layout.dockFloating
                onToggled: backend.set("layout.dockFloating", checked)
            }
            QQC2.ComboBox {
                Kirigami.FormData.label: "Visibility:"
                textRole: "text"
                valueRole: "value"
                model: [
                    { text: "Always visible", value: "none" },
                    { text: "Hide when a window touches it", value: "dodgewindows" },
                    { text: "Auto-hide", value: "autohide" }
                ]
                Component.onCompleted: currentIndex = indexOfValue(page.s.layout.dockHiding)
                onActivated: backend.set("layout.dockHiding", currentValue)
            }

            Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Transparency" }
            QQC2.ComboBox {
                Kirigami.FormData.label: "Panels:"
                textRole: "text"
                valueRole: "value"
                model: [
                    { text: "Adaptive (see-through until a window is maximized)", value: "adaptive" },
                    { text: "Always see-through", value: "translucent" },
                    { text: "Solid", value: "opaque" }
                ]
                Component.onCompleted: currentIndex = indexOfValue(page.s.layout.panelOpacity)
                onActivated: backend.set("layout.panelOpacity", currentValue)
            }
        }

        QQC2.Button {
            Layout.alignment: Qt.AlignHCenter
            text: "Apply to my desktop"
            icon.name: "dialog-ok-apply"
            highlighted: true
            onClicked: backend.applyLayout()
        }
    }
}
