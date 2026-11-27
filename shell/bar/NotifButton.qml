import QtQuick
import ".."

// Bell with unread count. Left click opens the swaync panel,
// right click toggles do-not-disturb.
Item {
    id: root

    implicitWidth: bell.implicitWidth + (badge.visible ? badge.width - 4 : 0)
    implicitHeight: 20

    Text {
        id: bell
        anchors.verticalCenter: parent.verticalCenter
        text: Notifs.dnd ? Icons.bellOff : (Notifs.count > 0 ? Icons.bell : Icons.bellNone)
        color: hover.hovered || Notifs.count > 0 ? Theme.text : Theme.textDim
        font { family: Theme.iconFont; pixelSize: 15 }
    }

    // Count badge, inverted ink so it reads in both modes
    Rectangle {
        id: badge
        visible: Notifs.count > 0 && !Notifs.dnd
        x: bell.width - 5
        y: -1
        height: 14
        width: Math.max(14, label.implicitWidth + 7)
        radius: 7
        color: Theme.text

        Text {
            id: label
            anchors.centerIn: parent
            text: Notifs.count > 99 ? "99+" : Notifs.count
            color: Theme.dark ? "#000000" : "#ffffff"
            font { family: Theme.font; pixelSize: 9; weight: Font.Bold; features: { "tnum": 1 } }
        }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler {
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onTapped: (point, button) => button === Qt.RightButton ? Notifs.toggleDnd() : Notifs.togglePanel()
    }
}
