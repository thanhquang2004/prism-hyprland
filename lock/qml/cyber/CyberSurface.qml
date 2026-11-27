import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.UPower

// Cyberpunk lock for one screen, after the orange/cyan HUD look: glowing
// lines on a dark field, ring gauges, a live graph, a security-lock core.
// Orange is the main colour, cyan the second, red only for errors.
//
// Lock:   the desktop glitches and collapses like a CRT; a line opens into
//         the HUD, a scan line draws it, panels bracket in, gauges sweep up,
//         labels decode.
// Idle:   rings turn, the CPU graph scrolls, audio bars move, the padlock
//         breathes, the clock glitches now and then.
// Type:   each key lights a tumbler on the ring and drops a flickering glyph
//         into the input.
// Check:  the ring races in cyan.
// Wrong:  everything flashes red, tears and shakes; tumblers reset.
// Unlock: ACCESS GRANTED, the shackle lifts, the ring whips round, the HUD
//         switches off like a CRT and the desktop comes back.
Item {
    id: s

    required property var ctx
    required property string screenName

    readonly property var out: (ctx.session.outputs ?? {})[screenName] ?? ({})
    readonly property bool portrait: height > width
    readonly property real m: Math.round(Math.min(width, height) * 0.035)

    readonly property color orange: "#ff7b1c"
    readonly property color cyan: "#2ee6ff"
    readonly property color red: "#ff2a3d"
    readonly property color ink: "#eef3f5"
    readonly property color dim: "#7f8a96"
    readonly property color faint: "#1e2a33"
    readonly property string display: "Oswald"
    readonly property string mono: "JetBrains Mono"

    // Live main colour: orange, red during a wrong-password flash
    property color main: orange
    readonly property bool busy: ctx.phase === "checking"

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
    property bool go: false
    property real intro: 0               // staged entrance of panels 0..1
    property real ringDraw: 0
    property real ringSpin: 0
    property real lockOpen: 0
    property real shakeX: 0
    property real split: 0
    property real pulse: 0
    function stage(start) { return Math.max(0, Math.min(1, (intro - start) / 0.35)); }

    Component.onCompleted: boot.start()

    SequentialAnimation {
        id: boot
        ScriptAction { script: s.glitching = true }
        PauseAnimation { duration: 360 }
        ScriptAction { script: s.glitching = false }
        NumberAnimation { target: s; property: "shotScaleY"; to: 0.004; duration: 170; easing.type: Easing.InQuad }
        NumberAnimation { target: s; property: "shotOpacity"; to: 0; duration: 60 }
        ScriptAction { script: s.lineOpacity = 1 }
        NumberAnimation { target: s; property: "lineW"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
        ParallelAnimation {
            NumberAnimation { target: s; property: "boxY"; to: 1; duration: 260; easing.type: Easing.OutCubic }
            NumberAnimation { target: s; property: "lineOpacity"; to: 0; duration: 260 }
        }
        ScriptAction { script: { s.scanning = true; s.go = true; } }
        ParallelAnimation {
            NumberAnimation { target: s; property: "scanY"; from: 0; to: s.height; duration: 900; easing.type: Easing.InOutSine }
            NumberAnimation { target: s; property: "ringDraw"; from: 0; to: 1; duration: 1000; easing.type: Easing.OutCubic }
            NumberAnimation { target: s; property: "intro"; from: 0; to: 1; duration: 1400; easing.type: Easing.OutCubic }
        }
        ScriptAction { script: { s.scanning = false; if (s.ctx.phase === "enter") s.ctx.phase = "idle"; } }
    }

    SequentialAnimation {
        id: leave
        PauseAnimation { duration: 120 }
        NumberAnimation { target: s; property: "lockOpen"; to: 1; duration: 320; easing.type: Easing.OutBack; easing.overshoot: 2 }
        PauseAnimation { duration: 160 }
        ParallelAnimation {
            NumberAnimation { target: s; property: "ringSpin"; to: 600; duration: 480; easing.type: Easing.InCubic }
            NumberAnimation { target: s; property: "intro"; to: 0; duration: 420; easing.type: Easing.InCubic }
        }
        NumberAnimation { target: s; property: "boxY"; to: 0.004; duration: 190; easing.type: Easing.InCubic }
        NumberAnimation { target: s; property: "boxX"; to: 0; duration: 140; easing.type: Easing.InCubic }
        ScriptAction { script: { s.shotScaleY = 0.004; s.shotOpacity = 1; } }
        NumberAnimation { target: s; property: "shotScaleY"; to: 1; duration: 240; easing.type: Easing.OutCubic }
    }

    Connections {
        target: s.ctx
        function onPhaseChanged() {
            if (s.ctx.phase === "unlocking") { boot.stop(); s.scanning = false; s.ringDraw = 1; s.intro = 1; leave.start(); }
        }
        function onWrongCountChanged() { denied.restart(); }
        function onBufferChanged() { if (s.ctx.buffer.length > 0) keyPulse.restart(); }
    }
    NumberAnimation { id: keyPulse; target: s; property: "pulse"; from: 1; to: 0; duration: 280; easing.type: Easing.OutQuad }
    ParallelAnimation {
        id: denied
        SequentialAnimation {
            ColorAnimation { target: s; property: "main"; to: s.red; duration: 40 }
            PauseAnimation { duration: 700 }
            ColorAnimation { target: s; property: "main"; to: s.orange; duration: 500 }
        }
        NumberAnimation { target: s; property: "split"; from: 1; to: 0; duration: 620; easing.type: Easing.OutCubic }
        SequentialAnimation {
            NumberAnimation { target: s; property: "shakeX"; to: -16; duration: 40 }
            NumberAnimation { target: s; property: "shakeX"; to: 13; duration: 50 }
            NumberAnimation { target: s; property: "shakeX"; to: -8; duration: 50 }
            NumberAnimation { target: s; property: "shakeX"; to: 4; duration: 50 }
            NumberAnimation { target: s; property: "shakeX"; to: 0; duration: 70 }
        }
    }

    // ================================================================ desktop snapshot

    Rectangle { anchors.fill: parent; color: "black" }

    Item {
        anchors.fill: parent
        opacity: s.shotOpacity
        visible: opacity > 0
        transform: Scale { origin.x: s.width / 2; origin.y: s.height / 2; yScale: s.shotScaleY }
        Repeater {
            model: 16
            Item {
                id: slice
                required property int index
                property real off: 0
                y: index * s.height / 16
                width: s.width
                height: Math.ceil(s.height / 16)
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
                    interval: 45; repeat: true; running: s.glitching
                    onTriggered: slice.off = Math.random() < 0.5 ? 0 : (Math.random() - 0.5) * 110
                    onRunningChanged: if (!running) slice.off = 0
                }
            }
        }
        Repeater {
            model: 7
            Rectangle {
                id: fringe
                required property int index
                property real r: Math.random()
                visible: s.glitching
                width: s.width
                y: r * s.height
                height: 2 + (index % 3) * 4
                color: index % 2 ? s.cyan : s.orange
                opacity: 0.25
                Timer { interval: 55; repeat: true; running: s.glitching; onTriggered: fringe.r = Math.random() }
            }
        }
    }

    Item {
        anchors.centerIn: parent
        width: s.width * s.lineW
        height: 2
        opacity: s.lineOpacity
        Rectangle { anchors.centerIn: parent; width: parent.width; height: 18; color: s.orange; opacity: 0.25 }
        Rectangle { anchors.fill: parent; color: "white" }
    }

    // ================================================================ HUD

    Item {
        id: box
        anchors.fill: parent
        visible: s.boxY > 0.005 && s.boxX > 0.01
        transform: Scale { origin.x: s.width / 2; origin.y: s.height / 2; yScale: s.boxY; xScale: s.boxX }

        // ---- backdrop
        Rectangle { anchors.fill: parent; color: "#05080c" }
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
            blur: 0.7
            blurMax: 48
            saturation: -0.7
            brightness: -0.5
            colorization: 0.4
            colorizationColor: "#0a2030"
        }
        Shape {
            anchors.fill: parent
            ShapePath {
                strokeColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: s.width / 2; centerY: s.height * 0.5
                    centerRadius: Math.max(s.width, s.height) * 0.72
                    focalX: centerX; focalY: centerY
                    GradientStop { position: 0; color: "#40000000" }
                    GradientStop { position: 0.6; color: "#99000000" }
                    GradientStop { position: 1; color: "#f2000000" }
                }
                startX: 0; startY: 0
                PathLine { x: s.width; y: 0 }
                PathLine { x: s.width; y: s.height }
                PathLine { x: 0; y: s.height }
                PathLine { x: 0; y: 0 }
            }
        }
        // Dot grid
        Canvas {
            anchors.fill: parent
            opacity: 0.16
            onPaint: {
                const g = getContext("2d");
                g.fillStyle = "#2ee6ff";
                const step = 32;
                for (let x = step; x < width; x += step)
                    for (let y = step; y < height; y += step) g.fillRect(x, y, 1, 1);
            }
        }

        Item {
            id: hud
            width: parent.width
            height: s.scanning ? s.scanY : parent.height
            clip: true
            transform: Translate { x: s.shakeX }

            Item {
                id: page
                width: s.width
                height: s.height

                // ---------- screen corner brackets
                Repeater {
                    model: 4
                    Item {
                        required property int index
                        readonly property bool isRight: index % 2 === 1
                        readonly property bool isBottom: index > 1
                        readonly property real fly: (1 - s.stage(0)) * 60
                        width: 54; height: 54
                        x: isRight ? s.width - s.m * 0.6 - width + fly : s.m * 0.6 - fly
                        y: isBottom ? s.height - s.m * 0.6 - height + fly : s.m * 0.6 - fly
                        opacity: s.stage(0)
                        layer.enabled: true
                        layer.effect: Glow { color: s.main; strength: 0.6 }
                        Rectangle { width: parent.width; height: 2; color: s.main; y: parent.isBottom ? parent.height - 2 : 0 }
                        Rectangle { width: 2; height: parent.height; color: s.main; x: parent.isRight ? parent.width - 2 : 0 }
                        Rectangle { width: 6; height: 6; color: s.cyan; x: parent.isRight ? parent.width - 12 : 6; y: parent.isBottom ? parent.height - 12 : 6 }
                    }
                }

                // ---------- top labels
                Column {
                    x: s.m * 1.6; y: s.m * 1.3
                    spacing: 4
                    opacity: s.stage(0.05)
                    ScrambleText {
                        go: s.go; delay: 40
                        target: "SYS://SESSION.LOCKED"
                        color: s.main
                        font { family: s.display; pixelSize: 20; variableAxes: { "wght": 600 }; letterSpacing: 3 }
                    }
                    ScrambleText {
                        go: s.go; delay: 120
                        target: "PRISM.SEC  //  NODE " + (s.ctx.sys.host ?? "").toUpperCase()
                        color: s.dim
                        font { family: s.mono; pixelSize: 11; letterSpacing: 2 }
                    }
                }
                Column {
                    anchors { right: parent.right; rightMargin: s.m * 1.6 }
                    y: s.m * 1.3
                    spacing: 4
                    opacity: s.stage(0.05)
                    ScrambleText {
                        anchors.right: parent.right
                        go: s.go; delay: 80
                        target: "CODE/" + String(s.ctx.now.getDate()).padStart(2, "0") + String(s.ctx.now.getMonth() + 1).padStart(2, "0")
                        color: s.ink
                        font { family: s.display; pixelSize: 20; variableAxes: { "wght": 500 }; letterSpacing: 3 }
                    }
                    ScrambleText {
                        anchors.right: parent.right
                        go: s.go; delay: 160
                        target: s.utcOffset() + "  //  WK" + s.week(s.ctx.now)
                        color: s.dim
                        font { family: s.mono; pixelSize: 11; letterSpacing: 2 }
                    }
                }

                // ---------- clock box
                Item {
                    id: clock
                    readonly property real size: Math.round(Math.min(s.height * 0.095, s.width * 0.11))
                    property real glitch: 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: s.height * (s.portrait ? 0.06 : 0.07)
                    width: time.implicitWidth + 110
                    height: clock.size * 1.42
                    opacity: s.stage(0.1)

                    Timer {
                        interval: 6000 + Math.random() * 8000
                        running: s.go; repeat: true
                        onTriggered: { interval = 6000 + Math.random() * 8000; clockGlitch.restart(); }
                    }
                    SequentialAnimation {
                        id: clockGlitch
                        NumberAnimation { target: clock; property: "glitch"; to: 1; duration: 20 }
                        PauseAnimation { duration: 80 }
                        NumberAnimation { target: clock; property: "glitch"; to: 0.5; duration: 20 }
                        PauseAnimation { duration: 50 }
                        NumberAnimation { target: clock; property: "glitch"; to: 0; duration: 60 }
                    }

                    Text {
                        anchors { left: parent.left; bottom: parent.top; bottomMargin: 6 }
                        text: "LOCAL TIME"
                        color: s.dim
                        font { family: s.mono; pixelSize: 10; letterSpacing: 3 }
                    }
                    Text {
                        anchors { right: parent.right; bottom: parent.top; bottomMargin: 6 }
                        text: Qt.formatDate(s.ctx.now, "ddd dd MMM yyyy").toUpperCase()
                        color: s.cyan
                        font { family: s.mono; pixelSize: 10; letterSpacing: 3 }
                    }

                    // Frame with side stripes
                    Item {
                        anchors.fill: parent
                        layer.enabled: true
                        layer.effect: Glow { color: s.cyan; strength: 0.65 }
                        Chamfer { anchors.fill: parent; cut: 12; stroke: Qt.alpha(s.cyan, 0.8); strokeWidth: 1.5; fill: Qt.alpha(s.cyan, 0.04) }
                        Repeater {
                            model: 3
                            Rectangle {
                                required property int index
                                x: 12 + index * 9; y: parent.height * 0.25
                                width: 4; height: parent.height * 0.5
                                color: s.cyan
                                opacity: 0.9 - index * 0.3
                            }
                        }
                        Repeater {
                            model: 3
                            Rectangle {
                                required property int index
                                x: parent.width - 16 - index * 9; y: parent.height * 0.25
                                width: 4; height: parent.height * 0.5
                                color: s.cyan
                                opacity: 0.9 - index * 0.3
                            }
                        }
                    }

                    // RGB ghosts during a glitch
                    Repeater {
                        model: [{ c: "#ff2a3d", dx: -1 }, { c: "#2ee6ff", dx: 1 }]
                        Text {
                            required property var modelData
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: modelData.dx * 7 * Math.max(clock.glitch, s.split)
                            opacity: 0.6 * Math.max(clock.glitch, s.split)
                            visible: opacity > 0.01
                            text: time.text
                            color: modelData.c
                            font: time.font
                        }
                    }
                    Text {
                        id: time
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: (Math.random() - 0.5) * 10 * clock.glitch
                        text: Qt.formatTime(s.ctx.now, "HH:mm:ss")
                        color: s.cyan
                        font { family: s.display; pixelSize: clock.size; variableAxes: { "wght": 500 }; letterSpacing: 4; features: { "tnum": 1 } }
                        layer.enabled: true
                        layer.effect: Glow { color: s.cyan; strength: 0.9 }
                    }
                }

                // ---------- security core
                Item {
                    id: core
                    readonly property real d: s.portrait ? s.width * 0.5 : s.height * 0.36
                    width: d; height: d
                    x: (s.width - d) / 2
                    y: (s.portrait ? s.height * 0.31 : s.height * 0.5) - d / 2

                    SecurityRing {
                        anchors.fill: parent
                        draw: s.ringDraw
                        spin: s.ringSpin
                        busy: s.busy
                        count: s.ctx.buffer.length
                        open: s.lockOpen
                        main: s.main
                        second: s.cyan
                        track: s.faint
                    }
                }
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: core.y + core.height + 14
                    spacing: 2
                    opacity: s.stage(0.2)
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: s.ctx.phase === "unlocking" ? "ACCESS GRANTED" : s.busy ? "VERIFYING" : "SECURITY LOCK"
                        color: s.busy ? s.cyan : s.main
                        font { family: s.display; pixelSize: 30; variableAxes: { "wght": 600 }; letterSpacing: 4 }
                        layer.enabled: true
                        layer.effect: Glow { color: s.busy ? s.cyan : s.main; strength: 0.8 }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "USER // " + (s.ctx.session.user ?? "").toUpperCase() + "   ·   " + Math.min(s.ctx.buffer.length, 12) + "/12 TUMBLERS"
                        color: s.dim
                        font { family: s.mono; pixelSize: 11; letterSpacing: 2 }
                    }
                }

                // ---------- input
                Item {
                    id: auth
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: core.y + core.height + 92
                    width: Math.min(520, s.width * 0.8)
                    height: 54
                    opacity: s.stage(0.25)
                    readonly property string phase: s.ctx.phase

                    Chamfer {
                        anchors.fill: parent; anchors.leftMargin: -10 * s.split; anchors.rightMargin: 10 * s.split
                        cut: 14; stroke: s.red; opacity: 0.7 * s.split; visible: opacity > 0.01
                    }
                    Chamfer {
                        anchors.fill: parent; anchors.leftMargin: 10 * s.split; anchors.rightMargin: -10 * s.split
                        cut: 14; stroke: s.cyan; opacity: 0.7 * s.split; visible: opacity > 0.01
                    }
                    Chamfer { anchors.fill: parent; cut: 14; stroke: "transparent"; fill: Qt.alpha("#05080c", 0.85) }
                    Item {
                        anchors.fill: parent
                        layer.enabled: true
                        layer.effect: Glow { color: s.main; strength: 0.55 + 0.35 * s.pulse }
                        Chamfer { anchors.fill: parent; cut: 14; stroke: Qt.alpha(s.main, 0.65 + 0.35 * s.pulse); strokeWidth: 1.5 }
                    }

                    Text {
                        id: prompt
                        anchors { left: parent.left; leftMargin: 20; verticalCenter: parent.verticalCenter }
                        text: "PASSCODE"
                        color: s.main
                        font { family: s.display; pixelSize: 16; variableAxes: { "wght": 600 }; letterSpacing: 3 }
                    }
                    Row {
                        anchors { left: prompt.right; leftMargin: 16; verticalCenter: parent.verticalCenter }
                        spacing: 6
                        Repeater {
                            model: Math.min(s.ctx.buffer.length, 16)
                            // Each character becomes a symbol chosen by its position, never by
                            // what was typed: it flickers through random glyphs, settles, and
                            // re-glitches now and then.
                            Text {
                                id: cell
                                required property int index
                                property int flicker: 7
                                readonly property var glyphs: ["ア", "Ψ", "ジ", "Ж", "Σ", "ム", "λ", "ネ", "Ω", "ヲ", "Ξ", "ツ", "Φ", "ゾ", "∆", "セ", "¥", "ヌ", "Π", "≡"]
                                readonly property string symbol: glyphs[(index * 7 + 3) % glyphs.length]
                                anchors.verticalCenter: parent.verticalCenter
                                width: 20
                                horizontalAlignment: Text.AlignHCenter
                                text: flicker > 0 ? glyphs[Math.floor(Math.random() * glyphs.length)] : symbol
                                color: flicker > 0 ? s.ink : (s.busy ? s.cyan : s.main)
                                font { family: s.mono; pixelSize: 18; variableAxes: { "wght": 600 } }
                                layer.enabled: flicker === 0
                                layer.effect: Glow { color: s.busy ? s.cyan : s.main; strength: 0.7 }
                                Timer { interval: 34; repeat: true; running: cell.flicker > 0; onTriggered: cell.flicker-- }
                                Timer {
                                    interval: 2500 + Math.random() * 6000; repeat: true; running: true
                                    onTriggered: { interval = 2500 + Math.random() * 6000; if (cell.flicker === 0) cell.flicker = 3; }
                                }
                            }
                        }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 9; height: 20
                            color: s.main
                            visible: auth.phase !== "unlocking" && !s.busy
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                NumberAnimation { to: 0; duration: 1 }
                                PauseAnimation { duration: 480 }
                                NumberAnimation { to: 1; duration: 1 }
                                PauseAnimation { duration: 480 }
                            }
                        }
                    }
                    Text {
                        anchors { right: parent.right; rightMargin: 20; verticalCenter: parent.verticalCenter }
                        text: auth.phase === "unlocking" ? "OK" : s.busy ? "····" : "[ENTER]"
                        color: s.dim
                        font { family: s.mono; pixelSize: 11; letterSpacing: 2 }
                    }
                    ScrambleText {
                        anchors { horizontalCenter: parent.horizontalCenter; top: parent.bottom; topMargin: 14 }
                        go: true
                        speed: 3
                        target: s.ctx.message ? "ACCESS DENIED  //  " + s.ctx.message.toUpperCase() : ""
                        color: s.red
                        font { family: s.mono; pixelSize: 12; styleName: "Bold"; letterSpacing: 3 }
                    }
                }

                // ---------- side columns
                readonly property real colW: s.portrait ? (s.width - 2 * s.m * 1.6 - 40) / 2 : Math.min(380, s.width * 0.21)
                readonly property real colTop: s.portrait ? auth.y + auth.height + 70 : s.height * 0.22
                readonly property var player: s.ctx.demo ? null : (Mpris.players.values.find(p => p.isPlaying) ?? null)
                Timer { interval: 1000; running: page.player !== null; repeat: true; onTriggered: page.player.positionChanged() }

                Column {
                    id: leftCol
                    x: s.m * 1.6
                    y: page.colTop
                    width: page.colW
                    spacing: 26

                    Panel {
                        width: parent.width; height: 118
                        title: "SYSTEM"; tag: "ID-" + ((s.ctx.sys.host ?? "").length * 4099).toString(16).toUpperCase()
                        accent: s.cyan; draw: s.stage(0.3); go: s.go; delay: 300
                        Column {
                            spacing: 6
                            component KV: Row {
                                property string k
                                property string v
                                spacing: 12
                                Text { width: 64; text: parent.k; color: s.dim; font { family: s.mono; pixelSize: 11; letterSpacing: 2 } }
                                Text { text: parent.v; color: s.ink; font { family: s.mono; pixelSize: 12; features: { "tnum": 1 } } }
                            }
                            KV { k: "USER"; v: s.ctx.sys.user ?? "" }
                            KV { k: "KERNEL"; v: s.ctx.sys.kernel ?? "" }
                            KV { k: "UPTIME"; v: s.ctx.uptime }
                        }
                    }

                    Panel {
                        width: parent.width; height: 150
                        title: "CPU LOAD"; tag: "LIVE"
                        accent: s.main; draw: s.stage(0.38); go: s.go; delay: 380
                        Text {
                            anchors { left: parent.left; top: parent.top; topMargin: -6 }
                            text: Math.round(s.ctx.cpu * 100) + "%"
                            color: s.ink
                            font { family: s.display; pixelSize: 40; variableAxes: { "wght": 600 }; features: { "tnum": 1 } }
                        }
                        Wave {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; top: parent.top; leftMargin: 96 }
                            value: s.ctx.cpu
                            accent: s.main
                            grid: s.faint
                        }
                    }

                    Panel {
                        width: parent.width; height: 168
                        title: "POWER"; tag: bat.charging ? "CHARGING" : "BATTERY"
                        accent: s.cyan; draw: s.stage(0.46); go: s.go; delay: 460
                        readonly property var dev: UPower.displayDevice
                        QtObject {
                            id: bat
                            readonly property real pct: UPower.displayDevice ? UPower.displayDevice.percentage : 0
                            readonly property bool charging: UPower.displayDevice && UPower.displayDevice.state === UPowerDeviceState.Charging
                        }
                        Gauge {
                            width: 128; height: 128
                            anchors.verticalCenter: parent.verticalCenter
                            value: bat.pct
                            draw: s.stage(0.5)
                            text: Math.round(bat.pct * 100)
                            unit: "%"
                            caption: bat.charging ? "⚡ AC" : "CELL"
                            accent: bat.pct <= 0.15 && !bat.charging ? s.red : s.cyan
                            track: s.faint
                        }
                        Column {
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            spacing: 8
                            Repeater {
                                model: 6
                                Rectangle {
                                    required property int index
                                    width: 54; height: 8
                                    color: (5 - index) / 6 < bat.pct ? s.cyan : s.faint
                                    opacity: 0.4 + 0.6 * ((5 - index) / 6 < bat.pct ? 1 : 0)
                                }
                            }
                        }
                    }
                }

                Column {
                    id: rightCol
                    x: s.width - s.m * 1.6 - width
                    y: page.colTop
                    width: page.colW
                    spacing: 26

                    Panel {
                        id: envPanel
                        width: parent.width; height: 168
                        title: "ENVIRONMENT"; tag: "EXT.SENSOR"
                        accent: s.main; draw: s.stage(0.34); go: s.go; delay: 340
                        readonly property real temp: parseFloat(s.ctx.weatherShort) || 0
                        Gauge {
                            id: tempGauge
                            width: 128; height: 128
                            anchors.verticalCenter: parent.verticalCenter
                            value: Math.max(0, Math.min(1, envPanel.temp / 45))
                            draw: s.stage(0.42)
                            text: Math.round(envPanel.temp)
                            unit: "°C"
                            caption: "TEMP"
                            accent: s.main
                            track: s.faint
                        }
                        Column {
                            anchors { left: tempGauge.right; leftMargin: 18; right: parent.right; verticalCenter: parent.verticalCenter }
                            spacing: 6
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: s.ctx.weatherShort.replace(/^-?\d+°C\s*/, "") || "--"
                                color: s.ink
                                font { family: s.display; pixelSize: 22; variableAxes: { "wght": 500 }; letterSpacing: 2 }
                            }
                            Text {
                                text: "KBD  " + s.ctx.layout.toUpperCase()
                                color: s.dim
                                font { family: s.mono; pixelSize: 11; letterSpacing: 2 }
                            }
                        }
                    }

                    Panel {
                        width: parent.width; height: 150
                        title: "AUDIO.STREAM"; tag: page.player ? "PLAYING" : "IDLE"
                        accent: s.cyan; draw: s.stage(0.42); go: s.go; delay: 420
                        Column {
                            anchors { left: parent.left; right: parent.right; top: parent.top }
                            spacing: 2
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: page.player ? (page.player.trackTitle || "UNKNOWN") : "NO SIGNAL"
                                color: page.player ? s.ink : s.dim
                                font { family: s.display; pixelSize: 20; variableAxes: { "wght": 500 }; letterSpacing: 1 }
                            }
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: (page.player?.trackArtist ?? "").toUpperCase()
                                color: s.dim
                                font { family: s.mono; pixelSize: 11; letterSpacing: 2 }
                            }
                        }
                        // Level bars: lively while playing, a flat line otherwise
                        Row {
                            anchors { left: parent.left; bottom: parent.bottom }
                            spacing: 4
                            layer.enabled: true
                            layer.effect: Glow { color: s.cyan; strength: 0.6 }
                            Repeater {
                                model: 22
                                Rectangle {
                                    id: bar
                                    required property int index
                                    property real lv: 0.08
                                    anchors.bottom: parent.bottom
                                    width: 7
                                    height: 4 + lv * 46
                                    color: s.cyan
                                    opacity: 0.35 + 0.65 * lv
                                    Behavior on lv { NumberAnimation { duration: 110 } }
                                    Timer {
                                        interval: 120; repeat: true; running: true
                                        onTriggered: bar.lv = page.player
                                            ? Math.min(1, Math.random() * (0.5 + 0.5 * Math.sin(bar.index * 0.5 + Date.now() / 300)))
                                            : 0.06
                                    }
                                }
                            }
                        }
                    }

                    Panel {
                        width: parent.width; height: 118
                        title: "NETWORK.TRACE"; tag: "SECURE"
                        accent: s.main; draw: s.stage(0.5); go: s.go; delay: 500
                        // A scrolling hex dump: purely atmospheric
                        Column {
                            spacing: 3
                            clip: true
                            Repeater {
                                model: 4
                                Text {
                                    id: hex
                                    required property int index
                                    property string line: ""
                                    text: line
                                    color: index === 0 ? s.main : s.dim
                                    opacity: 1 - index * 0.2
                                    font { family: s.mono; pixelSize: 11; letterSpacing: 1 }
                                    function gen() {
                                        let t = "0x" + Math.floor(Math.random() * 65535).toString(16).toUpperCase().padStart(4, "0") + "  ";
                                        for (let i = 0; i < 6; i++) t += Math.floor(Math.random() * 255).toString(16).toUpperCase().padStart(2, "0") + " ";
                                        return t;
                                    }
                                    Component.onCompleted: line = gen()
                                    Timer { interval: 900 + hex.index * 350; repeat: true; running: true; onTriggered: hex.line = hex.gen() }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Bottom ticker (landscape): a slow marquee of status chatter
        Item {
            visible: !s.portrait
            x: s.m * 1.6 + 70
            width: s.width - 2 * x
            y: s.height - s.m * 1.6 - 18
            height: 18
            clip: true
            opacity: s.stage(0.6)
            Rectangle { width: parent.width; height: 1; color: s.faint }
            Text {
                id: ticker
                y: 6
                readonly property string msg: "PRISM SECURITY LAYER ACTIVE  ///  INPUT CHANNEL ENCRYPTED  ///  SESSION " + (s.ctx.sys.user ?? "").toUpperCase()
                    + "@" + (s.ctx.sys.host ?? "").toUpperCase() + " SUSPENDED  ///  UPTIME " + s.ctx.uptime + "  ///  AWAITING PASSCODE  ///  "
                text: msg + msg
                color: s.dim
                opacity: 0.8
                font { family: s.mono; pixelSize: 10; letterSpacing: 3 }
                NumberAnimation on x { from: 0; to: -ticker.implicitWidth / 2; duration: 38000; loops: Animation.Infinite }
            }
        }

        // Tears on a wrong password
        Repeater {
            model: 3
            Rectangle {
                required property int index
                width: s.width
                y: s.height * (0.3 + 0.17 * index)
                height: 3 + index * 3
                color: index === 1 ? s.cyan : s.red
                opacity: s.split > 0.45 ? 0.28 : 0
            }
        }

        // Scan line
        Item {
            visible: s.scanning
            y: s.scanY
            width: s.width
            Rectangle {
                y: -48
                width: parent.width
                height: 48
                gradient: Gradient {
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 1; color: Qt.alpha(s.orange, 0.18) }
                }
            }
            Rectangle { width: parent.width; height: 2; color: s.orange }
        }

        Canvas {
            anchors.fill: parent
            opacity: 0.14
            onPaint: {
                const g = getContext("2d");
                g.fillStyle = "black";
                for (let y = 0; y < height; y += 3) g.fillRect(0, y, width, 1);
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
}
