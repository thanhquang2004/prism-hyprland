import QtQuick
import Quickshell
import ".."

// Notifications from one app. Collapsed: newest card with a stacked edge
// hinting at the rest. Expanded: every card.
Column {
    id: root

    // Delegates are keyed by group key (see NotifCenter) so they survive
    // list changes and keep their animations running.
    required property string groupKey
    readonly property var group: Notifs.groups.find(g => g.key === groupKey) ?? { key: groupKey, app: "", items: [] }
    readonly property bool expanded: !!Notifs.expanded[groupKey]
    // Index of the newest card that is not animating out
    readonly property int firstLive: group.items.findIndex(n => !Notifs.isLeaving(n))
    readonly property int extra: group.items.length - Math.max(firstLive, 0) - 1
    // Whole group on its way out (cleared): fold the header away with the cards
    readonly property bool leaving: firstLive < 0

    property real fold: 1

    spacing: 8
    height: implicitHeight * fold
    clip: fold < 1
    onLeavingChanged: if (leaving) foldOut.start()
    Component.onCompleted: if (leaving) { fold = 0; opacity = 0; }

    ParallelAnimation {
        id: foldOut
        NumberAnimation { target: root; property: "fold"; to: 0; duration: Notifs.leaveMs; easing.type: Easing.InOutCubic }
        NumberAnimation { target: root; property: "opacity"; to: 0; duration: 200 }
    }

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

        // Bottom edge of the newest live card. Cards leaving above it collapse,
        // so this glides up instead of dipping and growing back.
        readonly property real firstBottom: {
            const it = rep.count > 0 && root.firstLive >= 0 ? rep.itemAt(root.firstLive) : null;
            return it ? it.y + it.height : 0;
        }
        readonly property real collapsedHeight: firstBottom + (root.extra > 0 ? 8 : 0)
        height: root.expanded ? cards.implicitHeight : collapsedHeight
        Behavior on height { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutCubic } }

        // A sliver of the next card peeking out under the newest one
        Rectangle {
            x: 10
            width: parent.width - 20
            y: viewport.firstBottom - 10
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
                model: ScriptModel { values: root.group.items }

                NotifCard {
                    required property var modelData
                    required property int index
                    width: cards.width
                    notif: modelData
                    opacity: index === root.firstLive || root.expanded ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutCubic } }
                }
            }
        }
    }
}
