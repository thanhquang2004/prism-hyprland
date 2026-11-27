import QtQuick
import ".."
import "../cc"

// Bell with unread count. Left click opens the notification panel on this
// screen, right click toggles do-not-disturb.
Rectangle {
    id: root

    property var screen: null
    readonly property bool active: Notifs.panelOpen && Notifs.panelScreen === screen

    implicitWidth: row.implicitWidth + 16
    implicitHeight: Theme.chipHeight
    radius: height / 2
    color: active ? Theme.chipActive : (hover.hovered ? Theme.chipHover : Theme.chip)
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Notifs.dnd ? Icons.bellOff : (Notifs.count > 0 ? Icons.bell : Icons.bellNone)
            color: Notifs.count > 0 || root.active ? Theme.text : Theme.textDim
            font { family: Theme.iconFont; pixelSize: 15 }
        }
        Text {
            visible: Notifs.count > 0 && !Notifs.dnd
            anchors.verticalCenter: parent.verticalCenter
            text: Notifs.count > 99 ? "99+" : Notifs.count
            color: Theme.text
            font { family: Theme.font; pixelSize: 12; styleName: "Bold"; features: { "tnum": 1 } }
        }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler {
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onTapped: (point, button) => {
            if (button === Qt.RightButton) {
                Notifs.dnd = !Notifs.dnd;
            } else {
                Cc.open = false;
                Notifs.togglePanel(root.screen);
            }
        }
    }
}
