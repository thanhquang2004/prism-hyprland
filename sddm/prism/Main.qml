import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import "components"

// Prism login (SDDM): the Prism lock screen's cyberpunk HUD, piece for
// piece, plus session and power controls. Live data comes from /proc and
// /sys through XMLHttpRequest (needs QML_XHR_ALLOW_FILE_READ=1, set by
// install.sh as GreeterEnvironment); panels show "--" without it.
//
// Boot:    a neon line opens into the HUD, a scan line draws it, panels
//          bracket in, gauges sweep up, labels decode.
// Type:    each key lights a tumbler and drops a flickering glyph.
// Check:   the ring races in cyan.
// Wrong:   red flash, tears, split, shake.
// Success: ACCESS GRANTED, the shackle lifts, the ring whips round and the
//          HUD switches off like a CRT while the session starts.
Item {
    id: s

    width: 1920
    height: 1080

    readonly property bool portrait: height > width
    readonly property real m: Math.round(Math.min(width, height) * 0.035)

    readonly property color orange: "#ff7b1c"
    readonly property color cyan: "#2ee6ff"
    readonly property color red: "#ff2a3d"
    readonly property color ink: "#eef3f5"
    readonly property color dim: "#7f8a96"
    readonly property color faint: "#1e2a33"
    readonly property string display: oswald.name || "Oswald"
    readonly property string mono: "JetBrains Mono"

    FontLoader { id: oswald; source: "assets/Oswald.ttf" }

    // ================================================================ data

    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    // users.count / sessions.count re-run these once the repeaters fill
    readonly property string userName: users.count > 0 ? (users.itemAt(userIndex)?.name ?? userModel.lastUser) : userModel.lastUser
    readonly property string userReal: config.previewUser || (users.count > 0 ? users.itemAt(userIndex)?.realName : "") || userName
    readonly property string sessionName: sessions.count > 0 ? (sessions.itemAt(sessionIndex)?.name ?? "") : ""
    Repeater { id: users; model: userModel; delegate: Item { required property string name; required property string realName } }
    Repeater { id: sessions; model: sessionModel; delegate: Item { required property string name } }

    function readFile(path, cb) {
        const x = new XMLHttpRequest();
        x.onreadystatechange = () => { if (x.readyState === XMLHttpRequest.DONE) cb(x.responseText || ""); };
        try { x.open("GET", "file://" + path); x.send(); } catch (e) { cb(""); }
    }

    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: s.now = new Date() }

    // previewUser / previewHost in theme.conf replace the real names (screenshots)
    property string host: config.previewHost || sddm.hostName
    property string kernel: ""
    property real bootEpoch: 0
    readonly property string uptime: {
        if (!bootEpoch) return "--:--:--";
        const t = Math.max(0, Math.floor(now.getTime() / 1000 - bootEpoch));
        const p = n => String(n).padStart(2, "0");
        return p(Math.floor(t / 3600)) + ":" + p(Math.floor(t / 60) % 60) + ":" + p(t % 60);
    }
    property real cpu: 0
    property var cpuLast: null
    property real battery: -1
    property bool charging: false
    property real temp: -1
    property string tempPath: ""

    Component.onCompleted: {
        boot.start();
        pass.forceActiveFocus();
        readFile("/proc/sys/kernel/osrelease", t => s.kernel = t.trim());
        if (!host) readFile("/proc/sys/kernel/hostname", t => s.host = t.trim());
        readFile("/proc/uptime", t => { const u = parseFloat(t); if (u) s.bootEpoch = Date.now() / 1000 - u; });
        // CPU package sensor: k10temp (AMD) or coretemp (Intel), else the first thermal zone
        for (let i = 0; i < 16; i++) {
            const dir = "/sys/class/hwmon/hwmon" + i;
            readFile(dir + "/name", t => {
                if (!s.tempPath && /^(k10temp|coretemp|zenpower)$/.test(t.trim())) { s.tempPath = dir + "/temp1_input"; poll(); }
            });
        }
        fallbackTemp.start();
        poll();
    }
    Timer { id: fallbackTemp; interval: 800; onTriggered: if (!s.tempPath) { s.tempPath = "/sys/class/thermal/thermal_zone0/temp"; s.poll(); } }

    function poll() {
        readFile("/proc/stat", t => {
            const f = (t.split("\n")[0] || "").trim().split(/\s+/).slice(1).map(Number);
            if (f.length < 4) return;
            const idle = f[3] + (f[4] || 0), total = f.reduce((a, b) => a + b, 0);
            if (s.cpuLast && total > s.cpuLast.total) s.cpu = Math.max(0, Math.min(1, 1 - (idle - s.cpuLast.idle) / (total - s.cpuLast.total)));
            s.cpuLast = { total: total, idle: idle };
        });
        readFile("/sys/class/power_supply/BAT0/capacity", t => { const v = parseInt(t); s.battery = isNaN(v) ? -1 : v / 100; });
        readFile("/sys/class/power_supply/BAT0/status", t => s.charging = t.trim() === "Charging");
        if (tempPath) readFile(tempPath, t => { const v = parseInt(t); s.temp = isNaN(v) ? -1 : v / 1000; });
    }
    Timer { interval: 700; running: true; repeat: true; onTriggered: s.poll() }

    readonly property string layoutName: {
        const l = keyboard.layouts && keyboard.layouts[keyboard.currentLayout];
        return l ? (l.longName || l.shortName || "") : "";
    }

    // ================================================================ state

    property string phase: "idle"          // idle | checking | granted
    property string message: ""
    property color main: orange
    readonly property bool busy: phase === "checking"

    function submit() {
        if (busy || phase === "granted" || pass.text === "") return;
        message = "";
        phase = "checking";
        sddm.login(userName, pass.text, sessionIndex);
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            pass.text = "";
            s.phase = "idle";
            s.message = "WRONG PASSWORD";
            denied.restart();
        }
        function onLoginSucceeded() {
            s.phase = "granted";
            leave.start();
        }
    }

    // ================================================================ timeline

    property real lineW: 0
    property real lineOpacity: 0
    property real boxY: 0.004
    property real boxX: 1
    property real scanY: 0
    property bool scanning: false
    property bool go: false
    property real intro: 0
    property real ringDraw: 0
    property real ringSpin: 0
    property real lockOpen: 0
    property real shakeX: 0
    property real split: 0
    property real pulse: 0
    function stage(start) { return Math.max(0, Math.min(1, (intro - start) / 0.35)); }

    SequentialAnimation {
        id: boot
        PauseAnimation { duration: 250 }
        ScriptAction { script: s.lineOpacity = 1 }
        NumberAnimation { target: s; property: "lineW"; from: 0; to: 1; duration: 260; easing.type: Easing.OutCubic }
        ParallelAnimation {
            NumberAnimation { target: s; property: "boxY"; to: 1; duration: 280; easing.type: Easing.OutCubic }
            NumberAnimation { target: s; property: "lineOpacity"; to: 0; duration: 280 }
        }
        ScriptAction { script: { s.scanning = true; s.go = true; } }
        ParallelAnimation {
            NumberAnimation { target: s; property: "scanY"; from: 0; to: s.height; duration: 900; easing.type: Easing.InOutSine }
            NumberAnimation { target: s; property: "ringDraw"; from: 0; to: 1; duration: 1000; easing.type: Easing.OutCubic }
            NumberAnimation { target: s; property: "intro"; from: 0; to: 1; duration: 1400; easing.type: Easing.OutCubic }
        }
        ScriptAction { script: s.scanning = false }
    }

    SequentialAnimation {
        id: leave
        ScriptAction { script: { boot.stop(); s.scanning = false; s.ringDraw = 1; s.intro = 1; s.boxY = 1; } }
        NumberAnimation { target: s; property: "lockOpen"; to: 1; duration: 300; easing.type: Easing.OutBack; easing.overshoot: 2 }
        ParallelAnimation {
            NumberAnimation { target: s; property: "ringSpin"; to: 600; duration: 460; easing.type: Easing.InCubic }
            NumberAnimation { target: s; property: "intro"; to: 0; duration: 400; easing.type: Easing.InCubic }
        }
        NumberAnimation { target: s; property: "boxY"; to: 0.004; duration: 180; easing.type: Easing.InCubic }
        NumberAnimation { target: s; property: "boxX"; to: 0; duration: 130; easing.type: Easing.InCubic }
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

    // ================================================================ scene

    Rectangle { anchors.fill: parent; color: "black" }

    // Hidden input that holds the password; the HUD only shows glyphs
    TextInput {
        id: pass
        width: 1; height: 1; opacity: 0
        echoMode: TextInput.Password
        focus: true
        enabled: s.phase !== "granted"
        onTextChanged: { if (text.length > 0) { keyPulse.restart(); s.message = ""; } }
        Keys.onReturnPressed: s.submit()
        Keys.onEnterPressed: s.submit()
        Keys.onEscapePressed: text = ""
        Keys.onUpPressed: s.userIndex = (s.userIndex + userModel.count - 1) % Math.max(1, userModel.count)
        Keys.onDownPressed: s.userIndex = (s.userIndex + 1) % Math.max(1, userModel.count)
    }
    MouseArea { anchors.fill: parent; onClicked: pass.forceActiveFocus(); z: -1 }

    Item {
        anchors.centerIn: parent
        width: s.width * s.lineW
        height: 2
        opacity: s.lineOpacity
        Rectangle { anchors.centerIn: parent; width: parent.width; height: 18; color: s.orange; opacity: 0.25 }
        Rectangle { anchors.fill: parent; color: "white" }
    }

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
            source: s.portrait ? config.backgroundPortrait : config.background
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
        Canvas {
            anchors.fill: parent
            opacity: 0.16
            onPaint: {
                const g = getContext("2d");
                g.fillStyle = "#2ee6ff";
                for (let x = 32; x < width; x += 32)
                    for (let y = 32; y < height; y += 32) g.fillRect(x, y, 1, 1);
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
                        target: "PRISM.SEC  //  NODE " + s.host.toUpperCase()
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
                        target: "CODE/" + String(s.now.getDate()).padStart(2, "0") + String(s.now.getMonth() + 1).padStart(2, "0")
                        color: s.ink
                        font { family: s.display; pixelSize: 20; variableAxes: { "wght": 500 }; letterSpacing: 3 }
                    }
                    ScrambleText {
                        anchors.right: parent.right
                        go: s.go; delay: 160
                        target: s.utcOffset() + "  //  WK" + s.week(s.now)
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
                        text: Qt.formatDate(s.now, "ddd dd MMM yyyy").toUpperCase()
                        color: s.cyan
                        font { family: s.mono; pixelSize: 10; letterSpacing: 3 }
                    }
                    Item {
                        anchors.fill: parent
                        layer.enabled: true
                        layer.effect: Glow { color: s.cyan; strength: 0.65 }
                        Chamfer { anchors.fill: parent; cut: 12; stroke: Qt.alpha(s.cyan, 0.8); strokeWidth: 1.5; fill: Qt.alpha(s.cyan, 0.04) }
                        Repeater {
                            model: 6
                            Rectangle {
                                required property int index
                                readonly property int k: index % 3
                                x: index < 3 ? 12 + k * 9 : parent.width - 16 - k * 9
                                y: parent.height * 0.25
                                width: 4; height: parent.height * 0.5
                                color: s.cyan
                                opacity: 0.9 - k * 0.3
                            }
                        }
                    }
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
                        text: Qt.formatTime(s.now, "HH:mm:ss")
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
                        count: pass.text.length
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
                        text: s.phase === "granted" ? "ACCESS GRANTED" : s.busy ? "VERIFYING" : "SECURITY LOCK"
                        color: s.busy ? s.cyan : s.main
                        font { family: s.display; pixelSize: 30; variableAxes: { "wght": 600 }; letterSpacing: 4 }
                        layer.enabled: true
                        layer.effect: Glow { color: s.busy ? s.cyan : s.main; strength: 0.8 }
                    }
                    // "USER // NAME · n/12 TUMBLERS", arrows switch account when there are several
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 10
                        Text {
                            visible: userModel.count > 1
                            text: "◂"
                            color: s.cyan
                            font { family: s.mono; pixelSize: 12 }
                            MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: { s.userIndex = (s.userIndex + userModel.count - 1) % userModel.count; pass.forceActiveFocus(); } }
                        }
                        Text {
                            text: "USER // " + s.userReal.toUpperCase() + "   ·   " + Math.min(pass.text.length, 12) + "/12 TUMBLERS"
                            color: s.dim
                            font { family: s.mono; pixelSize: 11; letterSpacing: 2 }
                        }
                        Text {
                            visible: userModel.count > 1
                            text: "▸"
                            color: s.cyan
                            font { family: s.mono; pixelSize: 12 }
                            MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: { s.userIndex = (s.userIndex + 1) % userModel.count; pass.forceActiveFocus(); } }
                        }
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
                    MouseArea { anchors.fill: parent; onClicked: pass.forceActiveFocus() }

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
                            model: Math.min(pass.text.length, 16)
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
                            visible: pass.activeFocus && !s.busy && s.phase !== "granted"
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
                        text: keyboard.capsLock ? "CAPS" : s.phase === "granted" ? "OK" : s.busy ? "····" : "[ENTER]"
                        color: keyboard.capsLock ? s.red : s.dim
                        font { family: s.mono; pixelSize: 11; letterSpacing: 2 }
                    }
                    ScrambleText {
                        anchors { horizontalCenter: parent.horizontalCenter; top: parent.bottom; topMargin: 14 }
                        go: true
                        speed: 3
                        target: s.message ? "ACCESS DENIED  //  " + s.message : ""
                        color: s.red
                        font { family: s.mono; pixelSize: 12; styleName: "Bold"; letterSpacing: 3 }
                    }
                }

                // ---------- side columns (same panels as the lock screen)
                readonly property real colW: s.portrait ? (s.width - 2 * s.m * 1.6 - 40) / 2 : Math.min(380, s.width * 0.21)
                readonly property real colTop: s.portrait ? auth.y + auth.height + 70 : s.height * 0.22

                Column {
                    x: s.m * 1.6
                    y: page.colTop
                    width: page.colW
                    spacing: 26

                    Panel {
                        width: parent.width; height: 118
                        title: "SYSTEM"; tag: "ID-" + (s.host.length * 4099).toString(16).toUpperCase()
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
                            KV { k: "USER"; v: config.previewUser || s.userName }
                            KV { k: "KERNEL"; v: s.kernel || "--" }
                            KV { k: "UPTIME"; v: s.uptime }
                        }
                    }

                    Panel {
                        width: parent.width; height: 150
                        title: "CPU LOAD"; tag: "LIVE"
                        accent: s.main; draw: s.stage(0.38); go: s.go; delay: 380
                        Text {
                            anchors { left: parent.left; top: parent.top; topMargin: -6 }
                            text: Math.round(s.cpu * 100) + "%"
                            color: s.ink
                            font { family: s.display; pixelSize: 40; variableAxes: { "wght": 600 }; features: { "tnum": 1 } }
                        }
                        Wave {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; top: parent.top; leftMargin: 96 }
                            value: s.cpu
                            accent: s.main
                            grid: s.faint
                        }
                    }

                    Panel {
                        width: parent.width; height: 168
                        title: "POWER"; tag: s.charging ? "CHARGING" : "BATTERY"
                        accent: s.cyan; draw: s.stage(0.46); go: s.go; delay: 460
                        Gauge {
                            width: 128; height: 128
                            anchors.verticalCenter: parent.verticalCenter
                            value: Math.max(0, s.battery)
                            draw: s.stage(0.5)
                            text: s.battery < 0 ? "--" : Math.round(s.battery * 100)
                            unit: s.battery < 0 ? "" : "%"
                            caption: s.charging ? "⚡ AC" : "CELL"
                            accent: s.battery >= 0 && s.battery <= 0.15 && !s.charging ? s.red : s.cyan
                            track: s.faint
                        }
                        Column {
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            spacing: 8
                            Repeater {
                                model: 6
                                Rectangle {
                                    required property int index
                                    readonly property bool on: (5 - index) / 6 < s.battery
                                    width: 54; height: 8
                                    color: on ? s.cyan : s.faint
                                    opacity: on ? 1 : 0.4
                                }
                            }
                        }
                    }
                }

                Column {
                    x: s.width - s.m * 1.6 - width
                    y: page.colTop
                    width: page.colW
                    spacing: 26

                    Panel {
                        width: parent.width; height: 168
                        title: "ENVIRONMENT"; tag: "CPU.SENSOR"
                        accent: s.main; draw: s.stage(0.34); go: s.go; delay: 340
                        Gauge {
                            id: tempGauge
                            width: 128; height: 128
                            anchors.verticalCenter: parent.verticalCenter
                            value: s.temp < 0 ? 0 : Math.min(1, s.temp / 100)
                            draw: s.stage(0.42)
                            text: s.temp < 0 ? "--" : Math.round(s.temp)
                            unit: s.temp < 0 ? "" : "°C"
                            caption: "CORE"
                            accent: s.temp >= 85 ? s.red : s.main
                            track: s.faint
                        }
                        Column {
                            anchors { left: tempGauge.right; leftMargin: 18; right: parent.right; verticalCenter: parent.verticalCenter }
                            spacing: 6
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: s.temp < 0 ? "NO SENSOR" : s.temp < 60 ? "NOMINAL" : s.temp < 85 ? "WARM" : "HOT"
                                color: s.ink
                                font { family: s.display; pixelSize: 22; variableAxes: { "wght": 500 }; letterSpacing: 2 }
                            }
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: "KBD  " + (s.layoutName || "--").toUpperCase()
                                color: s.dim
                                font { family: s.mono; pixelSize: 11; letterSpacing: 2 }
                            }
                        }
                    }

                    Panel {
                        width: parent.width; height: 150
                        title: "AUDIO.STREAM"; tag: "IDLE"
                        accent: s.cyan; draw: s.stage(0.42); go: s.go; delay: 420
                        Text {
                            anchors { left: parent.left; top: parent.top }
                            text: "NO SIGNAL"
                            color: s.dim
                            font { family: s.display; pixelSize: 20; variableAxes: { "wght": 500 }; letterSpacing: 1 }
                        }
                        Row {
                            anchors { left: parent.left; bottom: parent.bottom }
                            spacing: 4
                            layer.enabled: true
                            layer.effect: Glow { color: s.cyan; strength: 0.6 }
                            Repeater {
                                model: 22
                                Rectangle {
                                    required property int index
                                    anchors.bottom: parent.bottom
                                    width: 7
                                    // a slow idle shimmer instead of levels
                                    property real lv: 0.06
                                    height: 4 + lv * 46
                                    color: s.cyan
                                    opacity: 0.35 + 0.65 * lv
                                    SequentialAnimation on lv {
                                        loops: Animation.Infinite
                                        PauseAnimation { duration: index * 90 }
                                        NumberAnimation { to: 0.16; duration: 900; easing.type: Easing.InOutSine }
                                        NumberAnimation { to: 0.04; duration: 900; easing.type: Easing.InOutSine }
                                    }
                                }
                            }
                        }
                    }

                    Panel {
                        width: parent.width; height: 118
                        title: "NETWORK.TRACE"; tag: "SECURE"
                        accent: s.main; draw: s.stage(0.5); go: s.go; delay: 500
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

                // ---------- bottom: session (left), power (right), ticker (middle)
                Item {
                    x: s.m * 1.6
                    y: s.height - s.m * 1.6 - height
                    width: sessionLabel.implicitWidth + 56
                    height: 32
                    opacity: s.stage(0.55)
                    Chamfer { anchors.fill: parent; cut: 9; stroke: Qt.alpha(s.cyan, sessionHover.containsMouse ? 1 : 0.6); fill: Qt.alpha(s.cyan, 0.05) }
                    Text {
                        id: sessionLabel
                        anchors.centerIn: parent
                        text: "SESSION  ◂ " + s.sessionName.toUpperCase() + " ▸"
                        color: s.cyan
                        font { family: s.mono; pixelSize: 11; letterSpacing: 2 }
                    }
                    MouseArea {
                        id: sessionHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            const n = Math.max(1, sessions.count);
                            s.sessionIndex = mouse.button === Qt.RightButton ? (s.sessionIndex + n - 1) % n : (s.sessionIndex + 1) % n;
                            pass.forceActiveFocus();
                        }
                    }
                }
                Row {
                    x: s.width - s.m * 1.6 - width
                    y: s.height - s.m * 1.6 - height
                    spacing: 8
                    opacity: s.stage(0.55)
                    component PowerChip: Item {
                        id: chip
                        property string label
                        property color tint: s.orange
                        signal activated()
                        visible: enabled
                        width: chipText.implicitWidth + 28
                        height: 32
                        Chamfer { anchors.fill: parent; cut: 9; stroke: Qt.alpha(chip.tint, hover.containsMouse ? 1 : 0.55); fill: Qt.alpha(chip.tint, hover.containsMouse ? 0.14 : 0.04) }
                        Text {
                            id: chipText
                            anchors.centerIn: parent
                            text: chip.label
                            color: hover.containsMouse ? s.ink : chip.tint
                            font { family: s.mono; pixelSize: 11; letterSpacing: 2 }
                        }
                        MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; onClicked: chip.activated() }
                    }
                    PowerChip { label: "SUSPEND"; tint: s.cyan; enabled: sddm.canSuspend; onActivated: sddm.suspend() }
                    PowerChip { label: "REBOOT"; enabled: sddm.canReboot; onActivated: sddm.reboot() }
                    PowerChip { label: "SHUTDOWN"; tint: s.red; enabled: sddm.canPowerOff; onActivated: sddm.powerOff() }
                }
                Item {
                    visible: !s.portrait
                    x: s.width * 0.28
                    width: s.width * 0.44
                    y: s.height - s.m * 1.6 - 18
                    height: 18
                    clip: true
                    opacity: s.stage(0.6)
                    Rectangle { width: parent.width; height: 1; color: s.faint }
                    Text {
                        id: ticker
                        y: 6
                        readonly property string msg: "PRISM SECURITY LAYER ACTIVE  ///  INPUT CHANNEL ENCRYPTED  ///  NODE " + s.host.toUpperCase()
                            + " COLD BOOT  ///  UPTIME " + s.uptime + "  ///  AWAITING PASSCODE  ///  "
                        text: msg + msg
                        color: s.dim
                        opacity: 0.8
                        font { family: s.mono; pixelSize: 10; letterSpacing: 3 }
                        NumberAnimation on x { from: 0; to: -ticker.implicitWidth / 2; duration: 38000; loops: Animation.Infinite }
                    }
                }
            }
        }

        // tears on a wrong password
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

        // scan line
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
