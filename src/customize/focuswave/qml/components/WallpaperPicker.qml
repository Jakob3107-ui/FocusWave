// Grid of wallpapers (FocusWave + installed packages) plus "choose your own".
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Flow {
    id: root
    property var model: []
    property string current
    property bool dark: false
    property int maxItems: 12
    signal picked(string path)

    spacing: Kirigami.Units.largeSpacing

    Repeater {
        model: root.model.slice(0, root.maxItems)
        delegate: ChoiceCard {
            required property var modelData
            width: Kirigami.Units.gridUnit * 9
            label: modelData.name
            selected: modelData.path === root.current
            onClicked: root.picked(modelData.path)
            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                source: root.dark && modelData.thumbDark ? modelData.thumbDark : modelData.thumb
                sourceSize.width: 320
            }
        }
    }

    ChoiceCard {
        width: Kirigami.Units.gridUnit * 9
        label: "Your own picture…"
        onClicked: fileDialog.open()
        Kirigami.Icon {
            anchors.centerIn: parent
            width: Kirigami.Units.iconSizes.large; height: width
            source: "folder-pictures"
        }
    }

    FileDialog {
        id: fileDialog
        title: "Choose a wallpaper"
        nameFilters: ["Pictures (*.jpg *.jpeg *.png *.webp *.avif *.jxl)", "All files (*)"]
        onAccepted: root.picked(backend.localPath(selectedFile.toString()))
    }
}
