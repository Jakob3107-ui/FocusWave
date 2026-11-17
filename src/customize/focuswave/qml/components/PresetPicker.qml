// Pick a desktop layout: Mix, Mac-like or Windows-like.
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Flow {
    id: root
    property string current: "mix"
    property bool dark: false
    property color accent: "#6E5BFF"
    property url wallpaper
    signal picked(string preset)

    spacing: Kirigami.Units.largeSpacing

    Repeater {
        model: [
            { id: "mix", name: "Mix", desc: "Top bar + floating dock" },
            { id: "mac", name: "Mac-like", desc: "Menu bar, Launchpad, dock" },
            { id: "windows", name: "Windows-like", desc: "One centered taskbar" }
        ]
        delegate: ChoiceCard {
            required property var modelData
            width: Kirigami.Units.gridUnit * 12
            label: modelData.name
            sublabel: modelData.desc
            selected: root.current === modelData.id
            onClicked: root.picked(modelData.id)
            Preview {
                anchors.fill: parent
                dark: root.dark
                accent: root.accent
                wallpaper: root.wallpaper
                preset: modelData.id
                buttons: modelData.id === "windows" ? "windows" : "mac"
                dockFloating: modelData.id !== "windows"
            }
        }
    }
}
