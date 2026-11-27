import QtQuick
import ".."

// Notifications from one app. Collapsed: newest card with a stacked edge
// hinting at the rest. Expanded: every card.
Column {
    id: root

    required property var group
    property bool expanded: false
    readonly property int extra: group.items.length - 1

    spacing: 6

    // Header: app glyph, name, count, expand and clear-group buttons
    Item {
        width: parent.width
        height: 22

        HoverHandler { id: headHover }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            x: 4
            spacing: 7

            Text {
                text: Icons.app(root.group.key)
                color: Theme.textDim
                font { family: Theme.iconFont; pixelSize: 13 }
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: root.group.app
                color: Theme.textDim
                font { family: Theme.font; pixelSize: 12; weight: Font.DemiBold }
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                visible: root.extra > 0
                text: root.group.items.length
                color: Theme.textFaint
                font { family: Theme.font; pixelSize: 11; features: { "tnum": 1 } }
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Row {
            anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
            spacing: 10

            Text {
                visible: root.extra > 0
                text: root.expanded ? Icons.chevronUp : Icons.chevronDown
                color: expandHover.hovered ? Theme.text : Theme.textDim
                font { family: Theme.iconFont; pixelSize: 15 }
                HoverHandler { id: expandHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.expanded = !root.expanded }
            }
            Text {
                text: Icons.close
                opacity: headHover.hovered ? 1 : 0
                color: clearHover.hovered ? Theme.text : Theme.textDim
                font { family: Theme.iconFont; pixelSize: 13 }
                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                HoverHandler { id: clearHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: Notifs.dismissGroup(root.group.key) }
            }
        }
    }

    Item {
        width: parent.width
        height: cards.height + (stackEdge.visible ? 6 : 0)

        // A sliver of the next card peeking out under the newest one
        Rectangle {
            id: stackEdge
            visible: !root.expanded && root.extra > 0
            x: 10
            width: parent.width - 20
            y: cards.height - 10
            height: 16
            radius: 12
            color: Theme.chip
        }

        Column {
            id: cards
            width: parent.width
            spacing: 6

            Repeater {
                model: root.expanded ? root.group.items : root.group.items.slice(0, 1)

                NotifCard {
                    required property var modelData
                    width: cards.width
                    notif: modelData
                }
            }
        }
    }
}
