// FocusWave first-boot welcome wizard. Every choice is applied live.
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "components"

Kirigami.ApplicationWindow {
    id: root
    title: "Welcome to FocusWave"
    width: Kirigami.Units.gridUnit * 48
    height: Kirigami.Units.gridUnit * 36
    minimumWidth: Kirigami.Units.gridUnit * 34
    minimumHeight: Kirigami.Units.gridUnit * 28

    readonly property var s: backend.settings
    readonly property var steps: ["hello", "mode", "accent", "wallpaper", "layout", "buttons", "focus", "done"]
    property int step: 0

    function next() {
        if (steps[step] === "layout") {
            backend.applyLayout()
        }
        if (step < steps.length - 1) {
            step += 1
        }
    }
    function back() {
        if (step > 0) {
            step -= 1
        }
    }
    function finish() {
        backend.finishWelcome()
        Qt.quit()
    }

    onClosing: backend.finishWelcome()

    Connections {
        target: backend
        function onMessage(text) {
            root.showPassiveNotification(text)
        }
    }

    pageStack.initialPage: Kirigami.Page {
        globalToolBarStyle: Kirigami.ApplicationHeaderStyle.None
        padding: Kirigami.Units.gridUnit

        ColumnLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.largeSpacing

            // ---------------------------------------------------- step content
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.step

                // hello
                ColumnLayout {
                    spacing: Kirigami.Units.largeSpacing * 2
                    Item { Layout.fillHeight: true }
                    Kirigami.Icon {
                        Layout.alignment: Qt.AlignHCenter
                        source: "focuswave-logo"
                        implicitWidth: Kirigami.Units.iconSizes.enormous
                        implicitHeight: implicitWidth
                    }
                    Kirigami.Heading {
                        Layout.alignment: Qt.AlignHCenter
                        level: 1
                        text: "Welcome to FocusWave"
                    }
                    QQC2.Label {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.maximumWidth: Kirigami.Units.gridUnit * 28
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: "Let's make this computer yours. Pick a few things you like — you'll see each change on your desktop right away, and you can change everything later in the Customize app."
                    }
                    Item { Layout.fillHeight: true }
                }

                // mode
                ColumnLayout {
                    spacing: Kirigami.Units.largeSpacing
                    Kirigami.Heading { level: 2; text: "Light or dark?" }
                    ModePicker {
                        Layout.fillWidth: true
                        current: root.s.mode
                        accent: root.s.accent
                        wallpaperLight: backend.thumbFor(root.s.wallpaper, false)
                        wallpaperDark: backend.thumbFor(root.s.wallpaper, true)
                        preset: root.s.layout.preset
                        buttons: root.s.buttons
                        onPicked: (mode) => backend.set("mode", mode)
                    }
                    Item { Layout.fillHeight: true }
                }

                // accent
                ColumnLayout {
                    spacing: Kirigami.Units.largeSpacing * 2
                    Kirigami.Heading { level: 2; text: "Pick a favorite color" }
                    QQC2.Label { text: "It's used for highlights, selected items, buttons and switches." }
                    Swatches {
                        Layout.fillWidth: true
                        current: root.s.accent
                        onPicked: (color) => backend.set("accent", color)
                    }
                    Preview {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 24
                        Layout.preferredHeight: Layout.preferredWidth * 0.625
                        dark: backend.previewDark
                        accent: root.s.accent
                        wallpaper: backend.thumbFor(root.s.wallpaper, backend.previewDark)
                        preset: root.s.layout.preset
                        buttons: root.s.buttons
                    }
                    Item { Layout.fillHeight: true }
                }

                // wallpaper
                ColumnLayout {
                    spacing: Kirigami.Units.largeSpacing
                    Kirigami.Heading { level: 2; text: "Choose a wallpaper" }
                    QQC2.ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        WallpaperPicker {
                            width: root.width - Kirigami.Units.gridUnit * 3
                            model: backend.wallpapers
                            current: root.s.wallpaper
                            dark: backend.previewDark
                            maxItems: 8
                            onPicked: (path) => backend.set("wallpaper", path)
                        }
                    }
                }

                // layout
                ColumnLayout {
                    spacing: Kirigami.Units.largeSpacing
                    Kirigami.Heading { level: 2; text: "How should your desktop be laid out?" }
                    QQC2.Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: "“Mix” combines a Mac-style top bar with a Windows-style start menu in a floating dock. Your desktop updates when you press Next."
                    }
                    PresetPicker {
                        Layout.fillWidth: true
                        current: root.s.layout.preset
                        dark: backend.previewDark
                        accent: root.s.accent
                        wallpaper: backend.thumbFor(root.s.wallpaper, backend.previewDark)
                        onPicked: (preset) => backend.choosePreset(preset)
                    }
                    Item { Layout.fillHeight: true }
                }

                // buttons
                ColumnLayout {
                    spacing: Kirigami.Units.largeSpacing
                    Kirigami.Heading { level: 2; text: "Window buttons" }
                    ButtonStylePicker {
                        Layout.fillWidth: true
                        current: root.s.buttons
                        dark: backend.previewDark
                        decorationAvailable: backend.decorationAvailable
                        onPicked: (style) => backend.set("buttons", style)
                    }
                    Item { Layout.fillHeight: true }
                }

                // focus mode
                ColumnLayout {
                    spacing: Kirigami.Units.largeSpacing * 2
                    Item { Layout.fillHeight: true }
                    Kirigami.Icon {
                        Layout.alignment: Qt.AlignHCenter
                        source: "focuswave-focus"
                        implicitWidth: Kirigami.Units.iconSizes.huge
                        implicitHeight: implicitWidth
                        isMask: true
                        color: Kirigami.Theme.highlightColor
                    }
                    Kirigami.Heading { Layout.alignment: Qt.AlignHCenter; level: 2; text: "Focus Mode" }
                    QQC2.Label {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.maximumWidth: Kirigami.Units.gridUnit * 28
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: "When you need to concentrate, Focus Mode blurs everything except the window you're using.<br><br>"
                              + "Turn it on and off with <b>" + backend.focusShortcut + "</b> or the Focus button in the top bar. "
                              + "You can also double-click the blur to leave."
                    }
                    QQC2.Button {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Try it on this window"
                        icon.name: "focuswave-focus"
                        highlighted: true
                        onClicked: backend.tryFocusMode()
                    }
                    Item { Layout.fillHeight: true }
                }

                // done
                ColumnLayout {
                    spacing: Kirigami.Units.largeSpacing * 2
                    Item { Layout.fillHeight: true }
                    Kirigami.Icon {
                        Layout.alignment: Qt.AlignHCenter
                        source: "emblem-favorite"
                        implicitWidth: Kirigami.Units.iconSizes.huge
                        implicitHeight: implicitWidth
                    }
                    Kirigami.Heading { Layout.alignment: Qt.AlignHCenter; level: 1; text: "You're all set" }
                    QQC2.Label {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.maximumWidth: Kirigami.Units.gridUnit * 28
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: "Open <b>Customize</b> from the dock any time to change colors, layout, fonts, effects and Focus Mode, or to save your look as a theme. New apps are in <b>Discover</b>."
                    }
                    QQC2.Button {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Open Customize"
                        icon.name: "focuswave-customize"
                        onClicked: {
                            backend.openCustomize()
                            root.finish()
                        }
                    }
                    Item { Layout.fillHeight: true }
                }
            }

            // ---------------------------------------------------- navigation
            RowLayout {
                Layout.fillWidth: true
                QQC2.Button {
                    text: "Back"
                    icon.name: "go-previous"
                    visible: root.step > 0
                    onClicked: root.back()
                }
                Item { Layout.fillWidth: true }
                Row {
                    spacing: Kirigami.Units.smallSpacing
                    Repeater {
                        model: root.steps.length
                        Rectangle {
                            required property int index
                            width: index === root.step ? Kirigami.Units.gridUnit : Kirigami.Units.smallSpacing * 2
                            height: Kirigami.Units.smallSpacing * 2
                            radius: height / 2
                            color: index === root.step ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor
                            Behavior on width { NumberAnimation { duration: Kirigami.Units.shortDuration } }
                        }
                    }
                }
                Item { Layout.fillWidth: true }
                QQC2.Button {
                    visible: root.step < root.steps.length - 1
                    text: root.step === 0 ? "Let's go" : "Next"
                    icon.name: "go-next"
                    highlighted: true
                    onClicked: root.next()
                }
                QQC2.Button {
                    visible: root.step === root.steps.length - 1
                    text: "Finish"
                    icon.name: "dialog-ok"
                    highlighted: true
                    onClicked: root.finish()
                }
            }
        }
    }
}
