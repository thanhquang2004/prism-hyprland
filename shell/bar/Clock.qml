import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import ".."

// Center of the bar: clock, plus a live waveform and track title while
// something is playing. Hover reveals the date.
Row {
    id: root

    property string formFactor: "laptop"

    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? null
    readonly property bool playing: player !== null
    readonly property int titleMax: formFactor === "wide" ? 320 : formFactor === "laptop" ? 240 : 0

    spacing: 10

    HoverHandler { id: hover }
    SystemClock { id: clock; precision: SystemClock.Seconds }

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
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(clock.date, hover.hovered ? "ddd, MMM d  ·  HH:mm:ss" : "HH:mm:ss")
        color: Theme.text
        font { family: Theme.font; pixelSize: 14; weight: Font.DemiBold; features: { "tnum": 1 } }
    }
}
