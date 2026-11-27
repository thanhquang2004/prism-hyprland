import QtQuick
import ".."

// Glass slider: icon (click = mute), draggable track, percentage.
Item {
    id: root

    property string icon
    property real value: 0               // 0..1
    property bool muted: false
    property bool showDetail: false
    signal moved(real v)
    signal iconClicked()
    signal detail()

    implicitHeight: 40

    Text {
        id: glyph
        anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
        width: 24
        text: root.icon
        color: root.muted ? Theme.textFaint : Theme.text
        font { family: Theme.iconFont; pixelSize: 19 }
        HoverHandler { cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: root.iconClicked() }
    }

    Rectangle {
        id: track
        anchors { left: glyph.right; leftMargin: 12; right: pct.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
        height: 10
        radius: 5
        color: Theme.chip

        Rectangle {
            width: Math.max(height, parent.width * Math.min(1, root.value))
            height: parent.height
            radius: parent.radius
            color: root.muted ? Theme.textFaint : Theme.accent
            Behavior on width { enabled: !drag.active; NumberAnimation { duration: 120 } }
        }

        // Thumb
        Rectangle {
            x: Math.min(1, root.value) * (parent.width - width)
            anchors.verticalCenter: parent.verticalCenter
            width: 18
            height: 18
            radius: 9
            color: Theme.dark ? "#ffffff" : "#ffffff"
            border.width: 1
            border.color: Qt.rgba(0, 0, 0, 0.15)
            scale: drag.active || trackHover.hovered ? 1 : 0.85
            Behavior on scale { NumberAnimation { duration: Theme.animFast } }
        }

        HoverHandler { id: trackHover; cursorShape: Qt.PointingHandCursor }

        // Click or drag anywhere on the track
        MouseArea {
            id: drag
            property bool active: pressed
            anchors { fill: parent; topMargin: -10; bottomMargin: -10 }
            function apply(mx) { root.moved(Math.max(0, Math.min(1, mx / track.width))); }
            onPressed: mouse => apply(mouse.x)
            onPositionChanged: mouse => { if (pressed) apply(mouse.x); }
            onWheel: wheel => root.moved(Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
        }
    }

    Text {
        id: pct
        anchors { right: more.left; rightMargin: 4; verticalCenter: parent.verticalCenter }
        width: 40
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.value * 100) + "%"
        color: Theme.textDim
        font { family: Theme.font; pixelSize: 12; weight: Font.Medium; features: { "tnum": 1 } }
    }

    Item {
        id: more
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        width: root.showDetail ? 28 : 0
        height: parent.height
        visible: root.showDetail
        Text {
            anchors.centerIn: parent
            text: Icons.chevronRight
            color: moreHover.hovered ? Theme.text : Theme.textDim
            font { family: Theme.iconFont; pixelSize: 18 }
        }
        HoverHandler { id: moreHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: root.detail() }
    }
}
