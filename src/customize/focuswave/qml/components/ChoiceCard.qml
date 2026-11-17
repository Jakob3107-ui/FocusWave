// A selectable card: content on top, label underneath, accent ring when selected.
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

QQC2.AbstractButton {
    id: card
    property bool selected: false
    property string label
    property string sublabel
    default property alias content: holder.data

    implicitWidth: Kirigami.Units.gridUnit * 11
    implicitHeight: column.implicitHeight + Kirigami.Units.smallSpacing * 2
    hoverEnabled: true
    Accessible.name: label

    background: Rectangle {
        radius: Kirigami.Units.largeSpacing
        color: card.hovered ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g,
                                      Kirigami.Theme.highlightColor.b, 0.08) : "transparent"
        border.width: card.selected ? 2 : 1
        border.color: card.selected ? Kirigami.Theme.highlightColor
                                    : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g,
                                              Kirigami.Theme.textColor.b, 0.15)
    }

    contentItem: ColumnLayout {
        id: column
        spacing: Kirigami.Units.smallSpacing
        Item {
            id: holder
            clip: true
            Layout.fillWidth: true
            Layout.preferredHeight: (card.width - Kirigami.Units.smallSpacing * 2) * 0.62
            Layout.margins: Kirigami.Units.smallSpacing
        }
        QQC2.Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: card.label
            font.bold: card.selected
            elide: Text.ElideRight
        }
        QQC2.Label {
            visible: card.sublabel.length > 0
            Layout.fillWidth: true
            Layout.bottomMargin: Kirigami.Units.smallSpacing
            horizontalAlignment: Text.AlignHCenter
            text: card.sublabel
            opacity: 0.7
            font: Kirigami.Theme.smallFont
            wrapMode: Text.WordWrap
        }
    }
}
