/*
 * FocusWave Focus Mode toggle for the top bar / taskbar.
 * Clicking it fires the same global shortcut as Meta+F, so the KWin script decides
 * what to focus (the window that was active before the click).
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation
    toolTipMainText: "Focus Mode"
    toolTipSubText: "Blur everything except the window you're using.\nShortcut: Meta+F · Double-click the blur to exit"
    Plasmoid.icon: "focuswave-focus"
    Plasmoid.status: PlasmaCore.Types.ActiveStatus

    P5Support.DataSource {
        id: runner
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => disconnectSource(sourceName)
    }

    function toggle() {
        runner.connectSource("busctl --user call org.kde.kglobalaccel /component/kwin "
                             + "org.kde.kglobalaccel.Component invokeShortcut s 'FocusWave Focus Mode'")
    }

    compactRepresentation: MouseArea {
        id: area
        hoverEnabled: true
        Layout.minimumWidth: Kirigami.Units.iconSizes.small
        Layout.minimumHeight: Kirigami.Units.iconSizes.small
        onClicked: root.toggle()

        Kirigami.Icon {
            anchors.fill: parent
            source: "focuswave-focus"
            isMask: true
            color: Kirigami.Theme.textColor
            active: area.containsMouse
        }
    }

    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 14
        PlasmaComponents3.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: root.toolTipSubText
        }
        PlasmaComponents3.Button {
            Layout.alignment: Qt.AlignHCenter
            icon.name: "focuswave-focus"
            text: "Toggle Focus Mode"
            onClicked: root.toggle()
        }
    }
}
