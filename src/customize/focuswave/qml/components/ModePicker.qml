// Light / Dark / Automatic, each with a tiny preview.
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Flow {
    id: root
    property string current: "auto"
    property color accent: "#6E5BFF"
    property url wallpaperLight
    property url wallpaperDark
    property string preset: "mix"
    property string buttons: "mac"
    signal picked(string mode)

    spacing: Kirigami.Units.largeSpacing

    Repeater {
        model: [
            { id: "light", name: "Light", desc: "Always light" },
            { id: "dark", name: "Dark", desc: "Always dark" },
            { id: "auto", name: "Automatic", desc: "Light by day, dark at night" }
        ]
        delegate: ChoiceCard {
            required property var modelData
            width: Kirigami.Units.gridUnit * 11
            label: modelData.name
            sublabel: modelData.desc
            selected: root.current === modelData.id
            onClicked: root.picked(modelData.id)
            Item {
                anchors.fill: parent
                Preview {
                    anchors.fill: parent
                    visible: modelData.id !== "auto"
                    dark: modelData.id === "dark"
                    accent: root.accent
                    wallpaper: modelData.id === "dark" ? root.wallpaperDark : root.wallpaperLight
                    preset: root.preset
                    buttons: root.buttons
                }
                Row { // automatic = half light, half dark
                    anchors.fill: parent
                    visible: modelData.id === "auto"
                    clip: true
                    Item {
                        width: parent.width / 2; height: parent.height; clip: true
                        Preview { width: parent.width * 2; height: parent.height; dark: false; accent: root.accent; wallpaper: root.wallpaperLight; preset: root.preset; buttons: root.buttons }
                    }
                    Item {
                        width: parent.width / 2; height: parent.height; clip: true
                        Preview { x: -parent.width; width: parent.width * 2; height: parent.height; dark: true; accent: root.accent; wallpaper: root.wallpaperDark; preset: root.preset; buttons: root.buttons }
                    }
                }
            }
        }
    }
}
