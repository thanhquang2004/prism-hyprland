import QtQuick
import ".."

// Row in a detail page: icon, title, subtitle, trailing text, selected state.
Rectangle {
    id: root

    property string icon
    property string title
    property string subtitle: ""
    property string trailing: ""
    property bool selected: false
    property bool busy: false
    signal clicked()

    implicitHeight: subtitle !== "" ? 52 : 44
    radius: 14
    color: selected ? Qt.alpha(Theme.accent, 0.22) : (hover.hovered ? Theme.chipHover : "transparent")
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: root.clicked() }

    Text {
        id: glyph
        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
        text: root.icon
        color: root.selected ? Theme.accent : Theme.text
        font { family: Theme.iconFont; pixelSize: 18 }
    }

    Column {
        anchors { left: glyph.right; leftMargin: 12; right: tail.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
        Text {
            width: parent.width
            text: root.title
            elide: Text.ElideRight
            color: Theme.text
            font { family: Theme.font; pixelSize: 13; styleName: root.selected ? "SemiBold" : "Regular" }
        }
        Text {
            visible: root.subtitle !== ""
            width: parent.width
            text: root.subtitle
            elide: Text.ElideRight
            color: Theme.textFaint
            font { family: Theme.font; pixelSize: 11 }
        }
    }

    Text {
        id: tail
        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        text: root.busy ? "…" : (root.selected ? Icons.check : root.trailing)
        color: root.selected ? Theme.accent : Theme.textFaint
        font { family: root.busy ? Theme.font : Theme.iconFont; pixelSize: root.selected ? 16 : 14 }
    }
}
