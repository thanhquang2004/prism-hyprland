import QtQuick
import ".."

// Notifications from one app. Collapsed: newest card with a stacked edge
// hinting at the rest. Expanded: every card.
Column {
    id: root

    required property var group
    readonly property bool expanded: !!Notifs.expanded[group.key]
    readonly property int extra: group.items.length - 1

    spacing: 8

    // Header: app glyph, name, count, expand and clear-group buttons
    Item {
        width: parent.width
        height: 26

        HoverHandler { id: headHover }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            x: 4
            spacing: 7

            Text {
                text: Icons.app(root.group.key)
                color: Theme.textDim
                font { family: Theme.iconFont; pixelSize: 15 }
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: root.group.app
                color: Theme.textDim
                font { family: Theme.font; pixelSize: 14; weight: Font.DemiBold }
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                visible: root.extra > 0
                text: root.group.items.length
                color: Theme.textFaint
                font { family: Theme.font; pixelSize: 12; features: { "tnum": 1 } }
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Row {
            anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
            spacing: 10

            Text {
                visible: root.extra > 0
                text: Icons.chevronDown
                rotation: root.expanded ? 180 : 0
                color: expandHover.hovered ? Theme.text : Theme.textDim
                font { family: Theme.iconFont; pixelSize: 18 }
                Behavior on rotation { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutCubic } }
                HoverHandler { id: expandHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: Notifs.toggleGroup(root.group.key) }
            }
            Text {
                text: Icons.close
                opacity: headHover.hovered ? 1 : 0
                color: clearHover.hovered ? Theme.text : Theme.textDim
                font { family: Theme.iconFont; pixelSize: 15 }
                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                HoverHandler { id: clearHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: Notifs.dismissGroup(root.group.key) }
            }
        }
    }

    // Every card is always laid out; expanding just grows this clipped
    // viewport, so the motion is one continuous height animation.
    Item {
        id: viewport
        width: parent.width
        clip: true

        readonly property real firstHeight: rep.count > 0 && rep.itemAt(0) ? rep.itemAt(0).height : 0
        readonly property real collapsedHeight: firstHeight + (root.extra > 0 ? 8 : 0)
        height: root.expanded ? cards.implicitHeight : collapsedHeight
        Behavior on height { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutCubic } }

        // A sliver of the next card peeking out under the newest one
        Rectangle {
            x: 10
            width: parent.width - 20
            y: viewport.firstHeight - 10
            height: 18
            radius: 14
            color: Theme.chip
            opacity: !root.expanded && root.extra > 0 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        }

        Column {
            id: cards
            width: parent.width
            spacing: 8

            Repeater {
                id: rep
                model: root.group.items

                NotifCard {
                    required property var modelData
                    required property int index
                    width: cards.width
                    notif: modelData
                    opacity: index === 0 || root.expanded ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutCubic } }
                }
            }
        }
    }
}
