import QtQuick

// A clock digit that flickers through random glyphs before settling,
// whenever its value changes (and once when `go` turns true).
Text {
    id: d

    property int value: 0
    property bool go: false
    property int delay: 0
    readonly property string glyphs: "0123456789ABCDEF#%"
    property int frames: 0                 // scramble frames remaining

    text: frames > 0 ? glyphs[Math.floor(Math.random() * glyphs.length)] + "" : (go ? value + "" : "")
    font.features: { "tnum": 1 }

    function scramble(n) { frames = n; ticker.start(); }
    onValueChanged: if (go) scramble(6)
    onGoChanged: if (go) entry.start()

    Timer { id: entry; interval: Math.max(1, d.delay); onTriggered: d.scramble(10) }
    Timer {
        id: ticker
        interval: 38
        repeat: true
        onTriggered: { d.frames--; if (d.frames <= 0) stop(); }
    }
}
