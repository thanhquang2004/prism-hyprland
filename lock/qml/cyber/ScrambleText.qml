import QtQuick

// Text that decodes itself: a run of random glyphs sweeps left to right
// and leaves the real characters behind. Starts `delay` ms after `go`
// turns true; later changes to `target` decode again, faster.
Text {
    id: t

    property string target: ""
    property bool go: false
    property int delay: 0
    property int speed: 2                  // characters revealed per frame (30 ms)
    property string charset: "ABCDEF0123456789#$%&*+=<>/\\|_"

    property int revealed: -1              // -1 = not started yet
    property int frame: 0

    opacity: revealed >= 0 ? 1 : 0
    text: {
        frame;                             // re-evaluate every frame
        if (revealed < 0) return "";
        let s = "";
        for (let i = 0; i < target.length; i++) {
            const c = target[i];
            if (i < revealed || c === " ") s += c;
            else if (i < revealed + 5) s += charset[Math.floor(Math.random() * charset.length)];
        }
        return s;
    }

    function restart(fast) {
        if (fast) speed = Math.max(speed, 3);
        revealed = 0;
        ticker.start();
    }

    onGoChanged: if (go) { if (delay > 0) wait.start(); else restart(false); }
    onTargetChanged: if (revealed >= 0) restart(true)

    Timer { id: wait; interval: Math.max(1, t.delay); onTriggered: t.restart(false) }
    Timer {
        id: ticker
        interval: 30
        repeat: true
        onTriggered: {
            t.revealed += t.speed;
            t.frame++;
            if (t.revealed >= t.target.length) { t.revealed = t.target.length; stop(); }
        }
    }
}
