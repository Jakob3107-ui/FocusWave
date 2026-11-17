import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../components"

Kirigami.ScrollablePage {
    id: page
    title: "Windows & Effects"
    readonly property var s: backend.settings

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing * 2

        Kirigami.Heading { level: 3; text: "Window buttons" }
        ButtonStylePicker {
            Layout.fillWidth: true
            current: page.s.buttons
            dark: backend.previewDark
            decorationAvailable: backend.decorationAvailable
            onPicked: (style) => backend.set("buttons", style)
        }

        Kirigami.FormLayout {
            Layout.fillWidth: true

            Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Animations" }
            QQC2.ComboBox {
                Kirigami.FormData.label: "Opening & closing:"
                textRole: "text"
                valueRole: "value"
                model: [
                    { text: "Zoom (macOS-like)", value: "scale" },
                    { text: "Fade", value: "fade" },
                    { text: "Glide", value: "glide" },
                    { text: "None", value: "none" }
                ]
                Component.onCompleted: currentIndex = indexOfValue(page.s.windows.openAnimation)
                onActivated: backend.set("windows.openAnimation", currentValue)
            }
            QQC2.ComboBox {
                Kirigami.FormData.label: "Minimizing:"
                textRole: "text"
                valueRole: "value"
                model: [
                    { text: "Genie (Magic Lamp)", value: "magiclamp" },
                    { text: "Squash", value: "squash" },
                    { text: "None", value: "none" }
                ]
                Component.onCompleted: currentIndex = indexOfValue(page.s.windows.minimizeAnimation)
                onActivated: backend.set("windows.minimizeAnimation", currentValue)
            }
            QQC2.ComboBox {
                Kirigami.FormData.label: "Speed:"
                textRole: "text"
                valueRole: "value"
                model: [
                    { text: "Instant", value: "instant" },
                    { text: "Fast", value: "fast" },
                    { text: "Normal", value: "normal" },
                    { text: "Relaxed", value: "relaxed" }
                ]
                Component.onCompleted: currentIndex = indexOfValue(page.s.windows.speed)
                onActivated: backend.set("windows.speed", currentValue)
            }
            QQC2.Switch {
                Kirigami.FormData.label: "Wobbly windows:"
                text: "Windows wobble like jelly when you drag them"
                checked: page.s.windows.wobbly
                onToggled: backend.set("windows.wobbly", checked)
            }

            Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Glass effect" }
            RowLayout {
                Kirigami.FormData.label: "Blur behind panels & menus:"
                QQC2.Label { text: "Light" }
                QQC2.Slider {
                    from: 1; to: 15; stepSize: 1
                    value: page.s.windows.blurStrength
                    onMoved: backend.set("windows.blurStrength", value)
                }
                QQC2.Label { text: "Strong" }
            }
        }
    }
}
