import QtQuick
import ".."

// Recording indicator: appears while the mic, camera or a screen share is
// active. Click the mic to mute/unmute, the share icon to stop sharing.
Rectangle {
    id: root

    visible: Privacy.any
    implicitWidth: row.implicitWidth + 16
    implicitHeight: Theme.chipHeight
    radius: height / 2
    color: Qt.alpha(Theme.warn, 0.22)
    border.width: 1
    border.color: Qt.alpha(Theme.warn, 0.55)

    component Glyph: Text {
        property bool clickable: false
        signal clicked()
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.text
        font { family: Theme.iconFont; pixelSize: 14 }
        HoverHandler { enabled: parent.clickable; cursorShape: Qt.PointingHandCursor }
        TapHandler { enabled: parent.clickable; onTapped: parent.clicked() }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Glyph {
            visible: Privacy.mic
            text: Privacy.micMuted ? Icons.micOff : Icons.mic
            opacity: Privacy.micMuted ? 0.6 : 1
            clickable: true
            onClicked: Privacy.toggleMic()
        }
        Glyph {
            visible: Privacy.camera
            text: Icons.camera
        }
        Row {
            visible: Privacy.sharing
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter
            Glyph { text: Icons.share }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: stopHover.hovered ? "Stop" : "Sharing"
                color: Theme.text
                font { family: Theme.font; pixelSize: 12; weight: Font.DemiBold }
            }
            HoverHandler { id: stopHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: Privacy.stopSharing() }
        }
    }
}
