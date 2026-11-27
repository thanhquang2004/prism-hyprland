import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.UPower

// Cyberpunk lock for one screen: dark HUD, one neon (yellow), cyan used
// sparingly, red only for errors.
//
// Lock:   the desktop glitches, collapses like a CRT switching off, a neon
//         line opens into the HUD, and a scan line draws it top to bottom
//         while every label decodes.
// Idle:   clock glitches now and then, a faint band drifts down, the
//         seconds marker walks the ruler.
// Type:   each key lands as a flickering glyph, the frame pulses.
// Check:  cyan frame, segmented progress.
// Wrong:  red frame, shake, RGB split, ACCESS DENIED.
// Unlock: ACCESS GRANTED, the HUD switches off like a CRT and the desktop
//         switches back on.
Item {
    id: s

    required property var ctx
    required property string screenName

    readonly property var out: (ctx.session.outputs ?? {})[screenName] ?? ({})
    readonly property bool portrait: height > width
    readonly property real u: Math.min(height / 1200, 1.45)
    readonly property real m: Math.round(52 * u)

    readonly property color neon: "#f3e600"
    readonly property color cyan: "#00e5ff"
    readonly property color red: "#ff3355"
    readonly property color ink: "#e9e7e2"
    readonly property color dim: "#8a8f98"
    readonly property color faint: "#3a3f47"
    readonly property string mono: "JetBrains Mono"

    // --- timeline state
    property bool glitching: false
    property real shotScaleY: 1
    property real shotOpacity: 1
    property real lineW: 0
    property real lineOpacity: 0
    property real boxY: 0.004
    property real boxX: 1
    property real scanY: 0
    property bool scanning: false
    property bool go: false              // labels start decoding
    property real shakeX: 0
    property real split: 0               // RGB split amount on the panel
    property real pulse: 0               // keypress flash on the panel

    Component.onCompleted: boot.start()

    SequentialAnimation {
        id: boot
        ScriptAction { script: s.glitching = true }
        PauseAnimation { duration: 380 }
        ScriptAction { script: s.glitching = false }
        NumberAnimation { target: s; property: "shotScaleY"; to: 0.004; duration: 170; easing.type: Easing.InQuad }
        NumberAnimation { target: s; property: "shotOpacity"; to: 0; duration: 70 }
        ScriptAction { script: s.lineOpacity = 1 }
        NumberAnimation { target: s; property: "lineW"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
        ParallelAnimation {
            NumberAnimation { target: s; property: "boxY"; to: 1; duration: 260; easing.type: Easing.OutCubic }
            NumberAnimation { target: s; property: "lineOpacity"; to: 0; duration: 260 }
        }
        ScriptAction { script: { s.scanning = true; s.go = true; } }
        NumberAnimation { target: s; property: "scanY"; from: 0; to: s.height; duration: 950; easing.type: Easing.InOutSine }
        ScriptAction { script: { s.scanning = false; if (s.ctx.phase === "enter") s.ctx.phase = "idle"; } }
    }

    SequentialAnimation {
        id: leave
        PauseAnimation { duration: 340 }
        ParallelAnimation {
            NumberAnimation { target: s; property: "boxY"; to: 0.004; duration: 220; easing.type: Easing.InCubic }
            NumberAnimation { target: s; property: "pulse"; to: 1; duration: 120 }
        }
        NumberAnimation { target: s; property: "boxX"; to: 0; duration: 160; easing.type: Easing.InCubic }
        ScriptAction { script: { s.shotScaleY = 0.004; s.shotOpacity = 1; } }
        NumberAnimation { target: s; property: "shotScaleY"; to: 1; duration: 300; easing.type: Easing.OutCubic }
    }

    Connections {
        target: s.ctx
        function onPhaseChanged() { if (s.ctx.phase === "unlocking") { boot.stop(); s.scanning = false; leave.start(); } }
        function onWrongCountChanged() { denied.restart(); }
        function onBufferChanged() { if (s.ctx.buffer.length > 0) keyPulse.restart(); }
    }
    NumberAnimation { id: keyPulse; target: s; property: "pulse"; from: 1; to: 0; duration: 260; easing.type: Easing.OutQuad }
    ParallelAnimation {
        id: denied
        NumberAnimation { target: s; property: "split"; from: 1; to: 0; duration: 520; easing.type: Easing.OutCubic }
        SequentialAnimation {
            NumberAnimation { target: s; property: "shakeX"; to: -14; duration: 40 }
            NumberAnimation { target: s; property: "shakeX"; to: 12; duration: 50 }
            NumberAnimation { target: s; property: "shakeX"; to: -7; duration: 50 }
            NumberAnimation { target: s; property: "shakeX"; to: 4; duration: 50 }
            NumberAnimation { target: s; property: "shakeX"; to: 0; duration: 70 }
        }
    }

    // ---------------------------------------------------------------- desktop snapshot

    Rectangle { anchors.fill: parent; color: "black" }

    Item {
        id: shotLayer
        anchors.fill: parent
        opacity: s.shotOpacity
        visible: opacity > 0
        transform: Scale { origin.x: s.width / 2; origin.y: s.height / 2; yScale: s.shotScaleY }

        // Horizontal slices that jump sideways while glitching
        Repeater {
            model: 14
            Item {
                id: slice
                required property int index
                property real off: 0
                y: index * s.height / 14
                width: s.width
                height: Math.ceil(s.height / 14)
                clip: true
                Image {
                    x: slice.off
                    y: -slice.y
                    width: s.width
                    height: s.height
                    source: s.out.shot ? "file://" + s.out.shot : ""
                    fillMode: Image.PreserveAspectCrop
                }
                Timer {
                    interval: 45
                    repeat: true
                    running: s.glitching
                    onTriggered: slice.off = Math.random() < 0.55 ? 0 : (Math.random() - 0.5) * 90 * s.u
                    onRunningChanged: if (!running) slice.off = 0
                }
            }
        }
        // Colour fringes over the glitch
        Repeater {
            model: 6
            Rectangle {
                id: fringe
                property real r: 0
                visible: s.glitching
                x: 0
                width: s.width
                y: r * s.height
                height: 2 + Math.random() * 8
                color: index % 2 ? s.cyan : s.red
                opacity: 0.18
                Timer { interval: 60; repeat: true; running: s.glitching; onTriggered: fringe.r = Math.random() }
            }
        }
    }

    // CRT line that opens into the HUD
    Item {
        anchors.centerIn: parent
        width: s.width * s.lineW
        height: 2
        opacity: s.lineOpacity
        Rectangle { anchors.centerIn: parent; width: parent.width; height: 14; color: s.neon; opacity: 0.18 }
        Rectangle { anchors.fill: parent; color: "white" }
    }

    // ---------------------------------------------------------------- HUD

    Item {
        id: box
        anchors.fill: parent
        visible: s.boxY > 0.005 && s.boxX > 0.01
        transform: Scale { origin.x: s.width / 2; origin.y: s.height / 2; yScale: s.boxY; xScale: s.boxX }

        // Backdrop: the wallpaper, drained of colour and pushed into the dark
        Image {
            id: wall
            anchors.fill: parent
            source: s.out.wall ? "file://" + s.out.wall : (s.out.shot ? "file://" + s.out.shot : "")
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: wall
            blurEnabled: true
            blur: 0.35
            blurMax: 32
            saturation: -0.85
            brightness: -0.5
            contrast: 0.15
        }
        Rectangle { anchors.fill: parent; color: "#0a0c10"; opacity: 0.35 }

        // Grid
        Canvas {
            anchors.fill: parent
            opacity: 0.05
            onPaint: {
                const g = getContext("2d");
                g.strokeStyle = "white";
                g.lineWidth = 1;
                const step = Math.round(64 * s.u);
                for (let x = step; x < width; x += step) { g.beginPath(); g.moveTo(x + 0.5, 0); g.lineTo(x + 0.5, height); g.stroke(); }
                for (let y = step; y < height; y += step) { g.beginPath(); g.moveTo(0, y + 0.5); g.lineTo(width, y + 0.5); g.stroke(); }
            }
        }

        // Faint band drifting down
        Rectangle {
            width: parent.width
            height: 160 * s.u
            opacity: 0.6
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.85; color: Qt.alpha(s.neon, 0.035) }
                GradientStop { position: 1; color: Qt.alpha(s.neon, 0.07) }
            }
            NumberAnimation on y { from: -200 * s.u; to: s.height; duration: 7000; loops: Animation.Infinite }
        }

        // Everything below is drawn by the scan line
        Item {
            id: hud
            width: parent.width
            height: s.scanning ? s.scanY : parent.height
            clip: true
            transform: Translate { x: s.shakeX }

            Item {
                width: s.width
                height: s.height

                // ---- top left: system block
                Row {
                    x: s.m; y: s.m
                    spacing: 14
                    Rectangle { width: 2; height: sysCol.height; color: s.neon }
                    Column {
                        id: sysCol
                        spacing: 5
                        ScrambleText {
                            go: s.go; delay: 40
                            target: "◢ SYS://SESSION.LOCKED"
                            color: s.neon
                            font { family: s.mono; pixelSize: Math.round(14 * s.u); styleName: "Bold"; letterSpacing: 2 }
                        }
                        ScrambleText {
                            go: s.go; delay: 120
                            target: "NODE    " + (s.ctx.sys.user ?? "") + "@" + (s.ctx.sys.host ?? "")
                            color: s.dim
                            font { family: s.mono; pixelSize: Math.round(12 * s.u); letterSpacing: 1 }
                        }
                        ScrambleText {
                            go: s.go; delay: 180
                            target: "KERNEL  " + (s.ctx.sys.kernel ?? "")
                            color: s.dim
                            font { family: s.mono; pixelSize: Math.round(12 * s.u); letterSpacing: 1 }
                        }
                        Text {
                            opacity: s.go ? 1 : 0
                            text: "UPTIME  " + s.ctx.uptime
                            color: s.dim
                            font { family: s.mono; pixelSize: Math.round(12 * s.u); letterSpacing: 1; features: { "tnum": 1 } }
                        }
                    }
                }

                // ---- top right: date + secure badge
                Column {
                    anchors { right: parent.right; rightMargin: s.m }
                    y: s.m
                    spacing: 8
                    ScrambleText {
                        anchors.right: parent.right
                        go: s.go; delay: 60
                        target: Qt.formatDate(s.ctx.now, "yyyy.MM.dd")
                        color: s.ink
                        font { family: s.mono; pixelSize: Math.round(22 * s.u); styleName: "Light"; letterSpacing: 2 }
                    }
                    ScrambleText {
                        anchors.right: parent.right
                        go: s.go; delay: 140
                        target: Qt.formatDate(s.ctx.now, "ddd").toUpperCase() + "  //  WK" + s.week(s.ctx.now)
                        color: s.dim
                        font { family: s.mono; pixelSize: Math.round(12 * s.u); letterSpacing: 2 }
                    }
                    Item {
                        anchors.right: parent.right
                        width: badge.implicitWidth + 28
                        height: 26
                        opacity: s.go ? 1 : 0
                        Chamfer { anchors.fill: parent; cut: 7; stroke: Qt.alpha(s.neon, 0.8) }
                        Text {
                            id: badge
                            anchors.centerIn: parent
                            text: "SECURE"
                            color: s.neon
                            font { family: s.mono; pixelSize: 11; styleName: "Bold"; letterSpacing: 3 }
                        }
                    }
                }

                // ---- clock
                Item {
                    id: clockBox
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: s.height * (s.portrait ? 0.27 : 0.25)
                    width: clockRow.width + 90 * s.u
                    height: clockRow.height + 50 * s.u
                    readonly property real size: Math.round(Math.min((s.portrait ? 190 : 200) * s.u, s.width * 0.8 / 3.9))

                    property real glitch: 0
                    Timer {
                        interval: 7000 + Math.random() * 7000
                        running: s.go
                        repeat: true
                        onTriggered: { interval = 7000 + Math.random() * 7000; clockGlitch.restart(); }
                    }
                    SequentialAnimation {
                        id: clockGlitch
                        NumberAnimation { target: clockBox; property: "glitch"; to: 1; duration: 30 }
                        PauseAnimation { duration: 70 }
                        NumberAnimation { target: clockBox; property: "glitch"; to: 0.4; duration: 20 }
                        PauseAnimation { duration: 40 }
                        NumberAnimation { target: clockBox; property: "glitch"; to: 0; duration: 60 }
                    }

                    // Corner brackets fly in
                    Repeater {
                        model: 4
                        Item {
                            required property int index
                            readonly property bool isRight: index % 2 === 1
                            readonly property bool isBottom: index > 1
                            readonly property real fly: (1 - bracketIn.t) * 60 * s.u
                            width: 28 * s.u; height: 28 * s.u
                            x: (isRight ? clockBox.width - width + fly : -fly)
                            y: (isBottom ? clockBox.height - height + fly : -fly)
                            opacity: bracketIn.t
                            Rectangle { width: parent.width; height: 2; color: s.neon; y: parent.isBottom ? parent.height - 2 : 0 }
                            Rectangle { width: 2; height: parent.height; color: s.neon; x: parent.isRight ? parent.width - 2 : 0 }
                        }
                    }
                    QtObject {
                        id: bracketIn
                        property real t: 0
                    }
                    NumberAnimation { running: s.go; target: bracketIn; property: "t"; from: 0; to: 1; duration: 600; easing.type: Easing.OutCubic }

                    // RGB ghosts during a glitch
                    Repeater {
                        model: [{ c: "#ff3355", dx: -1 }, { c: "#00e5ff", dx: 1 }]
                        Row {
                            required property var modelData
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: modelData.dx * 6 * clockBox.glitch
                            opacity: 0.7 * clockBox.glitch
                            Text {
                                text: Qt.formatTime(s.ctx.now, "HH:mm")
                                color: modelData.c
                                font { family: s.mono; pixelSize: clockBox.size; styleName: "Bold"; features: { "tnum": 1 } }
                            }
                        }
                    }

                    Row {
                        id: clockRow
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: clockBox.glitch * (Math.random() - 0.5) * 10
                        readonly property int h: s.ctx.now.getHours()
                        readonly property int mi: s.ctx.now.getMinutes()
                        readonly property int se: s.ctx.now.getSeconds()

                        component Big: CyberDigit {
                            go: s.go
                            color: s.ink
                            font { family: s.mono; pixelSize: clockBox.size; styleName: "Bold" }
                        }
                        Big { value: Math.floor(clockRow.h / 10); delay: 200 }
                        Big { value: clockRow.h % 10; delay: 260 }
                        Text {
                            text: ":"
                            color: s.neon
                            opacity: s.go ? (clockRow.se % 2 ? 0.35 : 1) : 0
                            Behavior on opacity { NumberAnimation { duration: 180 } }
                            font { family: s.mono; pixelSize: clockBox.size; styleName: "Light" }
                        }
                        Big { value: Math.floor(clockRow.mi / 10); delay: 320 }
                        Big { value: clockRow.mi % 10; delay: 380 }
                    }
                    // Seconds, top right of the clock
                    Row {
                        anchors { left: clockRow.right; leftMargin: 10 * s.u; top: clockRow.top; topMargin: clockBox.size * 0.2 }
                        CyberDigit { go: s.go; delay: 420; value: Math.floor(clockRow.se / 10); color: s.cyan; font { family: s.mono; pixelSize: clockBox.size * 0.2; styleName: "Medium" } }
                        CyberDigit { go: s.go; delay: 440; value: clockRow.se % 10; color: s.cyan; font { family: s.mono; pixelSize: clockBox.size * 0.2; styleName: "Medium" } }
                    }
                }

                // Ruler under the clock with a seconds marker
                Item {
                    id: ruler
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: clockBox.y + clockBox.height + 10 * s.u
                    width: clockBox.width
                    height: 34
                    opacity: s.go ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 400 } }

                    Repeater {
                        model: 61
                        Rectangle {
                            required property int index
                            x: index * (ruler.width - 1) / 60
                            width: 1
                            height: index % 5 === 0 ? 10 : 5
                            color: index % 15 === 0 ? s.dim : s.faint
                        }
                    }
                    Rectangle {
                        x: s.ctx.now.getSeconds() * (ruler.width - 1) / 60 - 1
                        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                        y: -3
                        width: 3; height: 16
                        color: s.neon
                    }
                    Text {
                        y: 18
                        text: "T+LOCAL"
                        color: s.dim
                        font { family: s.mono; pixelSize: 10; letterSpacing: 2 }
                    }
                    Text {
                        anchors.right: parent.right
                        y: 18
                        text: s.utcOffset() + "  //  " + s.greeting()
                        color: s.dim
                        font { family: s.mono; pixelSize: 10; letterSpacing: 2 }
                    }
                }

                // ---- auth panel
                Item {
                    id: auth
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: s.height * (s.portrait ? 0.53 : 0.6)
                    width: Math.round(560 * Math.min(s.u, 1.15))
                    height: 62

                    readonly property string phase: s.ctx.phase
                    readonly property color frame: phase === "checking" ? s.cyan
                        : (s.split > 0.05 ? s.red : (phase === "unlocking" ? s.neon : Qt.alpha(s.neon, 0.55 + 0.45 * s.pulse)))

                    Row {
                        anchors { left: parent.left; bottom: parent.top; bottomMargin: 10 }
                        spacing: 10
                        opacity: s.go ? 1 : 0
                        ScrambleText {
                            go: s.go; delay: 520
                            target: "USER // " + (s.ctx.session.user ?? "").toUpperCase()
                            color: s.neon
                            font { family: s.mono; pixelSize: 12; styleName: "Bold"; letterSpacing: 2 }
                        }
                    }
                    Row {
                        anchors { right: parent.right; bottom: parent.top; bottomMargin: 10 }
                        spacing: 8
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 6; height: 6
                            color: auth.phase === "checking" ? s.cyan : s.neon
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.15; duration: 600 }
                                NumberAnimation { to: 1; duration: 600 }
                            }
                        }
                        ScrambleText {
                            go: s.go; delay: 560
                            target: auth.phase === "checking" ? "VERIFYING" : auth.phase === "unlocking" ? "ACCESS.OK" : "AUTH.REQUIRED"
                            color: s.dim
                            font { family: s.mono; pixelSize: 12; letterSpacing: 2 }
                        }
                    }

                    // RGB split ghosts on a wrong password
                    Chamfer {
                        anchors.fill: parent; anchors.leftMargin: -8 * s.split; anchors.rightMargin: 8 * s.split
                        cut: 14; stroke: s.red; opacity: 0.7 * s.split
                    }
                    Chamfer {
                        anchors.fill: parent; anchors.leftMargin: 8 * s.split; anchors.rightMargin: -8 * s.split
                        cut: 14; stroke: s.cyan; opacity: 0.7 * s.split
                    }
                    Chamfer {
                        id: frame
                        anchors.fill: parent
                        cut: 14
                        stroke: auth.frame
                        strokeWidth: 1.5
                        fill: auth.phase === "unlocking" ? Qt.alpha(s.neon, 0.14) : Qt.alpha("#0a0c10", 0.72)
                        opacity: s.go ? 1 : 0
                    }

                    Text {
                        id: prompt
                        anchors { left: parent.left; leftMargin: 22; verticalCenter: parent.verticalCenter }
                        opacity: s.go ? 1 : 0
                        text: "AUTH>"
                        color: s.neon
                        font { family: s.mono; pixelSize: 16; styleName: "Bold"; letterSpacing: 1 }
                    }

                    // Typed characters: a random glyph flickers, then settles into a block
                    Row {
                        id: cells
                        anchors { left: prompt.right; leftMargin: 16; verticalCenter: parent.verticalCenter }
                        spacing: 6
                        visible: auth.phase !== "checking"
                        Repeater {
                            model: Math.min(s.ctx.buffer.length, 22)
                            Text {
                                id: cell
                                required property int index
                                property int flicker: 5
                                readonly property string glyphs: "アカサタナハマヤラワ#%&$@"
                                text: flicker > 0 ? glyphs[Math.floor(Math.random() * glyphs.length)] : "■"
                                color: flicker > 0 ? s.ink : s.neon
                                font { family: s.mono; pixelSize: flicker > 0 ? 15 : 11 }
                                Timer { interval: 34; repeat: true; running: cell.flicker > 0; onTriggered: cell.flicker-- }
                            }
                        }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 10; height: 20
                            color: s.neon
                            visible: s.go && auth.phase !== "unlocking"
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                NumberAnimation { to: 0; duration: 1; }
                                PauseAnimation { duration: 480 }
                                NumberAnimation { to: 1; duration: 1 }
                                PauseAnimation { duration: 480 }
                            }
                        }
                    }

                    // Verifying: segments sweep across
                    Row {
                        anchors { left: prompt.right; leftMargin: 16; verticalCenter: parent.verticalCenter }
                        spacing: 4
                        visible: auth.phase === "checking"
                        property int head: 0
                        Timer { interval: 70; repeat: true; running: parent.visible; onTriggered: parent.head = (parent.head + 1) % 24 }
                        Repeater {
                            model: 18
                            Rectangle {
                                required property int index
                                width: 12; height: 12
                                readonly property int dist: (parent.head - index + 24) % 24
                                color: s.cyan
                                opacity: dist < 6 ? 1 - dist / 6 : 0.12
                            }
                        }
                    }

                    // Right side: entropy readout
                    Text {
                        anchors { right: parent.right; rightMargin: 22; verticalCenter: parent.verticalCenter }
                        opacity: s.go ? 1 : 0
                        text: {
                            const n = s.ctx.buffer.length;
                            if (auth.phase === "unlocking") return "OK";
                            if (n === 0) return "[ENTER]";
                            let h = 2166136261;
                            for (let i = 0; i < n; i++) h = Math.imul(h ^ (i * 131 + 7), 16777619);
                            return "0x" + ((h >>> 0) & 0xffff).toString(16).toUpperCase().padStart(4, "0");
                        }
                        color: s.dim
                        font { family: s.mono; pixelSize: 12; letterSpacing: 1 }
                    }

                    // Status line under the panel
                    ScrambleText {
                        anchors { left: parent.left; top: parent.bottom; topMargin: 14 }
                        go: true
                        speed: 3
                        target: auth.phase === "unlocking" ? "> ACCESS GRANTED"
                              : s.ctx.message ? "> ACCESS DENIED  //  " + s.ctx.message.toUpperCase()
                              : ""
                        color: auth.phase === "unlocking" ? s.neon : s.red
                        font { family: s.mono; pixelSize: 12; styleName: "Bold"; letterSpacing: 2 }
                    }
                }

                // ---- bottom left: audio
                readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? null
                Timer { interval: 1000; running: parent.player !== null; repeat: true; onTriggered: parent.player.positionChanged() }

                Row {
                    id: audio
                    readonly property var player: parent.player
                    visible: player !== null
                    x: s.m
                    y: s.height - s.m - height
                    spacing: 16
                    opacity: s.go ? 1 : 0

                    Item {
                        width: 64; height: 64
                        ClippingRectangle {
                            anchors.fill: parent; anchors.margins: 4
                            color: "#11151a"
                            Image {
                                anchors.fill: parent
                                source: audio.player?.trackArtUrl ?? ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }
                        Chamfer { anchors.fill: parent; cut: 10; stroke: Qt.alpha(s.neon, 0.7) }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Text {
                            text: "▶ AUDIO.STREAM"
                            color: s.neon
                            font { family: s.mono; pixelSize: 11; styleName: "Bold"; letterSpacing: 2 }
                        }
                        ScrambleText {
                            go: s.go; delay: 700
                            width: Math.min(implicitWidth, 340)
                            elide: Text.ElideRight
                            target: (audio.player?.trackTitle || "UNKNOWN")
                            color: s.ink
                            font { family: s.mono; pixelSize: 14; styleName: "SemiBold" }
                        }
                        Text {
                            width: Math.min(implicitWidth, 340)
                            elide: Text.ElideRight
                            text: (audio.player?.trackArtist ?? "").toUpperCase()
                            color: s.dim
                            font { family: s.mono; pixelSize: 11; letterSpacing: 1 }
                        }
                        Row {
                            spacing: 3
                            readonly property real frac: audio.player && audio.player.length > 0 ? Math.min(1, audio.player.position / audio.player.length) : 0
                            Repeater {
                                model: 28
                                Rectangle {
                                    required property int index
                                    width: 8; height: 4
                                    color: index < Math.round(parent.frac * 28) ? s.neon : s.faint
                                }
                            }
                        }
                    }
                }

                // ---- bottom right: telemetry
                Column {
                    id: tele
                    anchors { right: parent.right; rightMargin: s.m }
                    y: s.height - s.m - height
                    spacing: 7
                    opacity: s.go ? 1 : 0
                    readonly property var bat: UPower.displayDevice

                    component Line: Row {
                        property string key
                        property string value
                        property int delay: 0
                        anchors.right: parent.right
                        spacing: 14
                        Text {
                            text: parent.key
                            color: s.dim
                            font { family: s.mono; pixelSize: 12; letterSpacing: 2 }
                        }
                        ScrambleText {
                            go: s.go; delay: parent.delay
                            target: parent.value
                            color: s.ink
                            font { family: s.mono; pixelSize: 12; styleName: "Medium"; letterSpacing: 1 }
                        }
                    }

                    Line {
                        visible: tele.bat && tele.bat.isLaptopBattery
                        readonly property real pct: tele.bat ? tele.bat.percentage : 0
                        readonly property bool charging: tele.bat && tele.bat.state === UPowerDeviceState.Charging
                        key: "PWR"
                        delay: 760
                        value: "▮".repeat(Math.round(pct * 8)) + "▯".repeat(8 - Math.round(pct * 8)) + "  "
                               + String(Math.round(pct * 100)).padStart(3, " ") + "%" + (charging ? " +" : "")
                    }
                    Line { key: "ENV"; delay: 800; value: s.ctx.weatherShort }
                    Line { key: "KBD"; delay: 840; value: s.ctx.layout.toUpperCase() }
                }

                // Footer rule
                Rectangle {
                    x: s.m; width: s.width - 2 * s.m
                    y: s.height - s.m * 0.55
                    height: 1
                    color: s.faint
                    opacity: s.go ? 0.6 : 0
                }
            }
        }

        // Scan line drawing the HUD
        Item {
            visible: s.scanning
            y: s.scanY
            width: s.width
            Rectangle {
                y: -40 * s.u
                width: parent.width
                height: 40 * s.u
                gradient: Gradient {
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 1; color: Qt.alpha(s.neon, 0.16) }
                }
            }
            Rectangle { width: parent.width; height: 2; color: s.neon }
        }

        // Scanlines over everything
        Canvas {
            anchors.fill: parent
            opacity: 0.22
            onPaint: {
                const g = getContext("2d");
                g.fillStyle = "black";
                for (let y = 0; y < height; y += 3) g.fillRect(0, y, width, 1);
            }
        }
        // Vignette
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: "#66000000" }
                GradientStop { position: 0.3; color: "transparent" }
                GradientStop { position: 0.75; color: "transparent" }
                GradientStop { position: 1; color: "#88000000" }
            }
        }
    }

    function week(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        const day = t.getUTCDay() || 7;
        t.setUTCDate(t.getUTCDate() + 4 - day);
        const y0 = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
        return String(Math.ceil(((t - y0) / 86400000 + 1) / 7)).padStart(2, "0");
    }
    function utcOffset() {
        const o = -new Date().getTimezoneOffset();
        const a = Math.abs(o);
        return "UTC" + (o >= 0 ? "+" : "-") + String(Math.floor(a / 60)).padStart(2, "0") + ":" + String(a % 60).padStart(2, "0");
    }
    function greeting() {
        const h = ctx.now.getHours();
        return h < 5 ? "NIGHT.SHIFT" : h < 12 ? "MORNING" : h < 18 ? "AFTERNOON" : "EVENING";
    }
}
