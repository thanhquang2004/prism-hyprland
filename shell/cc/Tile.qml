import QtQuick
import ".."

// Quick toggle. Click the tile to toggle; tiles with a detail page show a
// chevron that opens it.
Rectangle {
    id: root

    property string icon
    property string label
    property string sublabel: ""
    property bool active: false
    property bool hasDetail: false
    signal toggled()
    signal detail()

    implicitHeight: 64
    radius: 20
    color: active ? Theme.accent : (hover.hovered ? Theme.chipHover : Theme.chip)
    Behavior on color { ColorAnimation { duration: Theme.animMed } }

    readonly property color ink: active ? Theme.onAccent : Theme.text

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    // Taps on the chevron belong to it alone (both handlers see the same tap)
    TapHandler {
        onTapped: point => {
            if (root.hasDetail && point.position.x >= root.width - more.width) return;
            root.toggled();
        }
    }

    Text {
        id: glyph
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
        text: root.icon
        color: root.ink
        font { family: Theme.iconFont; pixelSize: 20 }
    }

    Column {
        anchors { left: glyph.right; leftMargin: 11; right: more.left; rightMargin: 4; verticalCenter: parent.verticalCenter }
        spacing: 1
        Text {
            width: parent.width
            text: root.label
            elide: Text.ElideRight
            color: root.ink
            font { family: Theme.font; pixelSize: 13; styleName: "SemiBold" }
        }
        Text {
            visible: root.sublabel !== ""
            width: parent.width
            text: root.sublabel
            elide: Text.ElideRight
            color: Qt.alpha(root.ink, 0.72)
            font { family: Theme.font; pixelSize: 11 }
        }
    }

    // Detail chevron gets its own hit area
    Item {
        id: more
        visible: root.hasDetail
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
        width: root.hasDetail ? 34 : 0

        Text {
            anchors.centerIn: parent
            text: Icons.chevronRight
            color: moreHover.hovered ? root.ink : Qt.alpha(root.ink, 0.6)
            font { family: Theme.iconFont; pixelSize: 18 }
        }
        HoverHandler { id: moreHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: root.detail() }
    }
}
