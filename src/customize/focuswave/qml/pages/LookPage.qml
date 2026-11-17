import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../components"

Kirigami.ScrollablePage {
    id: page
    title: "Look"
    readonly property var s: backend.settings

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

        Kirigami.Heading { level: 3; text: "Light or dark" }
        ModePicker {
            Layout.fillWidth: true
            current: page.s.mode
            accent: page.s.accent
            wallpaperLight: backend.thumbFor(page.s.wallpaper, false)
            wallpaperDark: backend.thumbFor(page.s.wallpaper, true)
            preset: page.s.layout.preset
            buttons: page.s.buttons
            onPicked: (mode) => backend.set("mode", mode)
        }
        RowLayout {
            visible: page.s.mode === "auto"
            spacing: Kirigami.Units.largeSpacing
            QQC2.Label { text: "Light from" }
            QQC2.TextField {
                inputMask: "99:99"
                text: page.s.autoLight
                implicitWidth: Kirigami.Units.gridUnit * 4
                onEditingFinished: backend.set("autoLight", text)
            }
            QQC2.Label { text: "Dark from" }
            QQC2.TextField {
                inputMask: "99:99"
                text: page.s.autoDark
                implicitWidth: Kirigami.Units.gridUnit * 4
                onEditingFinished: backend.set("autoDark", text)
            }
        }

        Kirigami.Heading { level: 3; text: "Accent color" }
        Swatches {
            Layout.fillWidth: true
            current: page.s.accent
            onPicked: (color) => backend.set("accent", color)
        }

        Kirigami.Heading { level: 3; text: "Wallpaper" }
        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            opacity: 0.75
            text: "FocusWave wallpapers have a light and a dark version and switch automatically."
        }
        WallpaperPicker {
            Layout.fillWidth: true
            model: backend.wallpapers
            current: page.s.wallpaper
            dark: backend.previewDark
            onPicked: (path) => backend.set("wallpaper", path)
        }
    }
}
