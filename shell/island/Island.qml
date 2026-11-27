import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import ".."

// Collapsed island: clock, plus a live waveform and track title while
// something is playing. Hover reveals the date.
Item {
    id: root

    property string formFactor: "laptop"   // "laptop" | "wide" | "portrait"

    readonly property var player: {
        const ps = Mpris.players.values;
        return ps.find(p => p.isPlaying) ?? null;
    }
    readonly property bool playing: player !== null
    readonly property int titleMax: formFactor === "wide" ? 260 : formFactor === "laptop" ? 200 : 0

    implicitWidth: row.implicitWidth + 32
    implicitHeight: Theme.islandHeight
    width: implicitWidth
    height: implicitHeight

    Behavior on width { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }

    Rectangle {
        id: pill
        anchors.fill: parent
        radius: Theme.radius
        color: hover.hovered ? Theme.glassHover : Theme.glass
        border.width: 1
        border.color: Theme.edge
        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        // Thin highlight along the top edge sells the glass.
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.radius / 2 }
            anchors.topMargin: 1
            height: 1
            color: Theme.edgeTop
            opacity: 0.6
        }
    }

    HoverHandler { id: hover }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10

        Waveform {
            visible: root.playing
            playing: root.playing
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: root.playing && root.titleMax > 0
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, root.titleMax)
            elide: Text.ElideRight
            text: root.player ? root.player.trackTitle : ""
            color: Theme.textDim
            font { family: Theme.font; pixelSize: 13 }
        }

        Text {
            id: time
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(clock.date, hover.hovered ? "ddd, MMM d  ·  HH:mm" : "HH:mm")
            color: Theme.text
            font { family: Theme.font; pixelSize: 14; weight: Font.DemiBold; features: { "tnum": 1 } }
        }
    }
}
