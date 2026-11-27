import QtQuick
import ".."

// Small decorative equalizer shown in the island while media plays.
Row {
    id: root

    property bool playing: false

    spacing: 2
    height: 14

    Repeater {
        model: 4

        Rectangle {
            required property int index

            width: 3
            radius: 1.5
            anchors.bottom: parent.bottom
            color: Theme.accent
            height: 4

            SequentialAnimation on height {
                running: root.playing
                loops: Animation.Infinite
                NumberAnimation { to: 14 - index * 2; duration: 320 + index * 90; easing.type: Easing.InOutSine }
                NumberAnimation { to: 4 + index; duration: 280 + index * 70; easing.type: Easing.InOutSine }
            }
        }
    }
}
