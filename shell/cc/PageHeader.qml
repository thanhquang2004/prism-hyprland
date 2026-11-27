import QtQuick
import ".."

// Detail page header: back chevron, title, optional on/off switch.
Item {
    id: root

    property string title
    property bool hasSwitch: false
    property bool switchOn: false
    signal switched()

    implicitHeight: 36

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Icons.chevronLeft
            color: backHover.hovered ? Theme.text : Theme.textDim
            font { family: Theme.iconFont; pixelSize: 22 }
            HoverHandler { id: backHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: Cc.page = "main" }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.title
            color: Theme.text
            font { family: Theme.font; pixelSize: 17; styleName: "Bold" }
        }
    }

    // Switch
    Rectangle {
        visible: root.hasSwitch
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        width: 44
        height: 24
        radius: 12
        color: root.switchOn ? Theme.accent : Theme.chipActive
        Behavior on color { ColorAnimation { duration: Theme.animMed } }

        Rectangle {
            x: root.switchOn ? parent.width - width - 3 : 3
            anchors.verticalCenter: parent.verticalCenter
            width: 18
            height: 18
            radius: 9
            color: "#ffffff"
            Behavior on x { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }
        }
        HoverHandler { cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: root.switched() }
    }
}
