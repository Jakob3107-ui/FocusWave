// A miniature FocusWave desktop that redraws instantly when a setting changes.
import QtQuick
import QtQuick.Effects
import org.kde.kirigami as Kirigami

Item {
    id: root

    property bool dark: false
    property color accent: "#6E5BFF"
    property url wallpaper
    property string preset: "mix"
    property bool topBar: true
    property string buttons: "mac"
    property string dockPosition: "bottom"
    property bool dockFloating: true
    property bool showWindow: true

    readonly property real u: width / 100
    readonly property bool showTop: topBar && preset !== "windows"
    readonly property bool verticalDock: preset !== "windows" && dockPosition !== "bottom"
    readonly property color winBg: dark ? "#1E1E22" : "#F3F3F6"
    readonly property color viewBg: dark ? "#25252A" : "#FFFFFF"
    readonly property color textCol: dark ? "#F2F2F7" : "#1D1D1F"
    readonly property color lineCol: dark ? "#3A3A42" : "#E4E4EA"
    readonly property color barBg: dark ? Qt.rgba(0.11, 0.11, 0.13, 0.80) : Qt.rgba(0.98, 0.98, 0.99, 0.72)
    readonly property var appColors: ["#3DB8FF", "#FF7A59", "#2ED3B7", "#FFB020", "#8E8E93"]

    implicitWidth: 400
    implicitHeight: 250

    Item {
        id: canvas
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: roundMask
        }

        Rectangle { anchors.fill: parent; color: root.dark ? "#14121F" : "#ECEAF6" }

        Image {
            anchors.fill: parent
            source: root.wallpaper
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 640
        }

        // ---- top bar
        Rectangle {
            id: top
            visible: root.showTop
            width: parent.width
            height: root.u * 4.2
            color: root.barBg
            Row {
                anchors.left: parent.left
                anchors.leftMargin: root.u * 1.6
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.u * 1.6
                Kirigami.Icon {
                    visible: root.preset === "mac"
                    width: root.u * 2.6; height: width
                    source: "focuswave-start"
                    anchors.verticalCenter: parent.verticalCenter
                }
                Repeater {
                    model: ["Files", "Edit", "View", "Go"]
                    Text {
                        text: modelData
                        color: root.textCol
                        font.pixelSize: Math.max(5, root.u * 1.7)
                        font.bold: index === 0
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
            Row {
                anchors.right: parent.right
                anchors.rightMargin: root.u * 1.6
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.u * 1.4
                Rectangle { width: root.u * 1.8; height: width; radius: root.u * 0.4; color: "transparent"; border.color: root.textCol; border.width: Math.max(1, root.u * 0.2); anchors.verticalCenter: parent.verticalCenter }
                Rectangle { width: root.u * 1.8; height: width; radius: width / 2; color: root.textCol; opacity: 0.8; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "Mon 16 Nov  09:41"; color: root.textCol; font.pixelSize: Math.max(5, root.u * 1.7); anchors.verticalCenter: parent.verticalCenter }
            }
        }

        // ---- a background window for depth
        Rectangle {
            visible: root.showWindow
            x: root.u * 55; y: (root.showTop ? root.u * 12 : root.u * 7)
            width: root.u * 36; height: parent.height * 0.42
            radius: root.u * 1.3
            color: root.winBg
            opacity: 0.92
            border.color: Qt.rgba(0, 0, 0, root.dark ? 0.5 : 0.08)
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: root.u * 1.5 }
                height: parent.height * 0.58
                radius: root.u * 0.8
                color: root.viewBg
            }
        }

        // ---- main window
        Item {
            id: win
            visible: root.showWindow
            x: root.u * 12
            y: root.showTop ? root.u * 9 : root.u * 5
            width: root.u * 58
            height: parent.height * 0.6

            Rectangle { // shadow
                anchors.fill: parent
                anchors.topMargin: root.u * 1.2
                anchors.margins: -root.u * 0.6
                radius: root.u * 2
                color: Qt.rgba(0, 0, 0, root.dark ? 0.45 : 0.16)
            }
            Rectangle {
                id: frame
                anchors.fill: parent
                radius: root.u * 1.4
                color: root.winBg
                border.color: Qt.rgba(0, 0, 0, root.dark ? 0.6 : 0.10)
                border.width: 1

                // title bar
                Item {
                    id: titleBar
                    width: parent.width
                    height: root.u * 5
                    Row { // traffic lights
                        visible: root.buttons === "mac"
                        anchors.left: parent.left
                        anchors.leftMargin: root.u * 1.8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: root.u * 0.9
                        Repeater {
                            model: ["#FF5F57", "#FEBC2E", "#28C840"]
                            Rectangle { width: root.u * 1.5; height: width; radius: width / 2; color: modelData }
                        }
                    }
                    Row { // Windows buttons
                        visible: root.buttons !== "mac"
                        anchors.right: parent.right
                        anchors.rightMargin: root.u * 1.2
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: root.u * 2.2
                        Rectangle { width: root.u * 1.6; height: Math.max(1, root.u * 0.2); color: root.textCol; anchors.verticalCenter: parent.verticalCenter }
                        Rectangle { width: root.u * 1.5; height: width; color: "transparent"; border.color: root.textCol; border.width: Math.max(1, root.u * 0.2); anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "✕"; color: root.textCol; font.pixelSize: Math.max(6, root.u * 2); anchors.verticalCenter: parent.verticalCenter }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "Documents"
                        color: root.textCol
                        font.pixelSize: Math.max(5, root.u * 1.8)
                        font.bold: true
                    }
                }

                // sidebar
                Column {
                    x: root.u * 1.2
                    y: titleBar.height + root.u * 0.6
                    width: root.u * 13
                    spacing: root.u * 0.7
                    Repeater {
                        model: 5
                        Rectangle {
                            width: parent.width
                            height: root.u * 2.6
                            radius: root.u * 0.6
                            color: index === 1 ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22) : "transparent"
                            Rectangle {
                                x: root.u * 0.8
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width * (index === 1 ? 0.62 : 0.5 + 0.08 * (index % 3))
                                height: root.u * 0.8
                                radius: height / 2
                                color: index === 1 ? root.accent : root.textCol
                                opacity: index === 1 ? 1 : 0.35
                            }
                        }
                    }
                }

                // content
                Rectangle {
                    x: root.u * 15.5
                    y: titleBar.height
                    width: parent.width - x - root.u * 1.2
                    height: parent.height - y - root.u * 1.2
                    radius: root.u * 0.8
                    color: root.viewBg
                    Column {
                        anchors.fill: parent
                        anchors.margins: root.u * 1.4
                        spacing: root.u * 1.1
                        Repeater {
                            model: 6
                            Row {
                                spacing: root.u * 1
                                Rectangle { width: root.u * 2; height: width; radius: root.u * 0.5; color: root.appColors[index % root.appColors.length]; opacity: 0.85 }
                                Rectangle { width: root.u * (14 + (index * 7) % 13); height: root.u * 0.8; radius: height / 2; color: root.textCol; opacity: 0.28; anchors.verticalCenter: parent.verticalCenter }
                            }
                        }
                    }
                    Rectangle { // accent button
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: root.u * 1.4
                        width: root.u * 9; height: root.u * 3.2
                        radius: root.u * 0.8
                        color: root.accent
                        Rectangle { anchors.centerIn: parent; width: parent.width * 0.55; height: root.u * 0.8; radius: height / 2; color: "white"; opacity: 0.9 }
                    }
                }
            }
        }

        // ---- dock / taskbar
        Rectangle {
            id: dock
            readonly property int count: 7
            readonly property real icon: root.u * 3.6
            readonly property real pad: root.u * 1.0
            readonly property bool fullBar: root.preset === "windows"
            color: root.barBg
            border.color: Qt.rgba(1, 1, 1, root.dark ? 0.08 : 0.5)
            radius: fullBar && !root.dockFloating ? 0 : root.u * 1.6

            width: fullBar ? (root.dockFloating ? parent.width - root.u * 2 : parent.width)
                           : (root.verticalDock ? icon + pad * 2 : count * (icon + pad) + pad)
            height: fullBar ? root.u * 4.8
                            : (root.verticalDock ? count * (icon + pad) + pad : icon + pad * 2)
            x: root.verticalDock ? (root.dockPosition === "left" ? root.u * 1.2 : parent.width - width - root.u * 1.2)
                                 : (parent.width - width) / 2
            y: root.verticalDock ? (parent.height - height) / 2
                                 : parent.height - height - ((fullBar && !root.dockFloating) ? 0 : root.u * 1.2)

            Grid {
                anchors.centerIn: parent
                columns: root.verticalDock ? 1 : dock.count
                spacing: dock.pad
                Kirigami.Icon {
                    width: dock.icon; height: width
                    source: root.preset === "mac" ? "focuswave-launchpad" : "focuswave-start"
                }
                Repeater {
                    model: dock.count - 2
                    Rectangle {
                        width: dock.icon; height: width
                        radius: width * 0.26
                        color: root.appColors[index % root.appColors.length]
                        Rectangle {
                            visible: index < 2
                            width: root.u * 0.6; height: width; radius: width / 2
                            color: root.textCol
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.bottom
                            anchors.topMargin: root.u * 0.2
                        }
                    }
                }
                Rectangle {
                    width: dock.icon; height: width
                    radius: width * 0.26
                    color: root.preset === "mac" ? "#B7B7C2" : root.accent
                    opacity: 0.9
                }
            }

            Text { // clock on the Windows-style taskbar
                visible: dock.fullBar
                anchors.right: parent.right
                anchors.rightMargin: root.u * 1.6
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignRight
                text: "09:41\n16/11/2026"
                color: root.textCol
                font.pixelSize: Math.max(5, root.u * 1.5)
            }
        }
    }

    Item {
        id: roundMask
        anchors.fill: parent
        layer.enabled: true
        visible: false
        Rectangle { anchors.fill: parent; radius: root.u * 2.2; color: "black" }
    }
}
