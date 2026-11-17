// FocusWave Customize — main window
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
    id: root
    title: "FocusWave Customize"
    width: Kirigami.Units.gridUnit * 60
    height: Kirigami.Units.gridUnit * 42
    minimumWidth: Kirigami.Units.gridUnit * 32
    minimumHeight: Kirigami.Units.gridUnit * 26

    property string current: "Look"

    readonly property var sections: [
        { name: "Look", icon: "preferences-desktop-color", page: "pages/LookPage.qml" },
        { name: "Layout", icon: "preferences-desktop", page: "pages/LayoutPage.qml" },
        { name: "Windows & Effects", icon: "preferences-system-windows", page: "pages/WindowsPage.qml" },
        { name: "Focus Mode", icon: "focuswave-focus", page: "pages/FocusPage.qml" },
        { name: "Fonts", icon: "preferences-desktop-font", page: "pages/FontsPage.qml" },
        { name: "Themes", icon: "color-management", page: "pages/ThemesPage.qml" },
        { name: "Advanced", icon: "configure", page: "pages/AdvancedPage.qml" }
    ]

    function show(name) {
        for (var i = 0; i < sections.length; ++i) {
            if (sections[i].name === name) {
                current = name
                pageStack.clear()
                pageStack.push(Qt.resolvedUrl(sections[i].page))
                return
            }
        }
    }

    globalDrawer: Kirigami.GlobalDrawer {
        title: "FocusWave"
        titleIcon: "focuswave-logo"
        isMenu: false
        modal: !root.wideScreen
        collapsible: false
        actions: [
            Kirigami.Action {
                text: "Look"
                icon.name: "preferences-desktop-color"
                checkable: true
                checked: root.current === "Look"
                onTriggered: root.show("Look")
            },
            Kirigami.Action {
                text: "Layout"
                icon.name: "preferences-desktop"
                checkable: true
                checked: root.current === "Layout"
                onTriggered: root.show("Layout")
            },
            Kirigami.Action {
                text: "Windows & Effects"
                icon.name: "preferences-system-windows"
                checkable: true
                checked: root.current === "Windows & Effects"
                onTriggered: root.show("Windows & Effects")
            },
            Kirigami.Action {
                text: "Focus Mode"
                icon.name: "focuswave-focus"
                checkable: true
                checked: root.current === "Focus Mode"
                onTriggered: root.show("Focus Mode")
            },
            Kirigami.Action {
                text: "Fonts"
                icon.name: "preferences-desktop-font"
                checkable: true
                checked: root.current === "Fonts"
                onTriggered: root.show("Fonts")
            },
            Kirigami.Action {
                text: "Themes"
                icon.name: "color-management"
                checkable: true
                checked: root.current === "Themes"
                onTriggered: root.show("Themes")
            },
            Kirigami.Action {
                text: "Advanced"
                icon.name: "configure"
                checkable: true
                checked: root.current === "Advanced"
                onTriggered: root.show("Advanced")
            }
        ]
    }

    footer: QQC2.ProgressBar {
        visible: backend.busy
        indeterminate: true
    }

    Connections {
        target: backend
        function onMessage(text) {
            root.showPassiveNotification(text)
        }
    }

    Component.onCompleted: show("Look")
}
