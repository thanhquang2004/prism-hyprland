import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.UPower

// Everything one screen shows while locked.
//
// Entry: a spectral beam sweeps diagonally across the frozen desktop and
// leaves the blurred wallpaper behind it; then the content rises in.
// Exit: content falls away and the beam sweeps back, uncovering the desktop.
Item {
    id: s

    required property var ctx
    required property string screenName

    readonly property var out: (ctx.session.outputs ?? {})[screenName] ?? ({})
    readonly property bool portrait: height > width
    readonly property real u: Math.min(height / 1200, 1.45)
    readonly property color accent: ctx.accent
    readonly property color glass: "#6b0f1217"
    readonly property color edge: "#26ffffff"
    readonly property color warn: "#ffb4a2"
    readonly property string font: "Inter"
    readonly property string display: "Inter"
    readonly property string icons: "JetBrainsMono Nerd Font"

    // Sweep geometry: a square big enough to cover the screen at any angle
    readonly property real angle: -28
    readonly property real diag: Math.sqrt(width * width + height * height) + 80

    property real reveal: 0             // 0 = desktop, 1 = lock backdrop
    property real contentIn: 0          // content entrance 0..1
    // Staggered entrance: each element starts at its own point of contentIn
    function stage(start) { return Math.max(0, Math.min(1, (contentIn - start) / 0.45)); }

    Component.onCompleted: enter.start()
    SequentialAnimation {
        id: enter
        PauseAnimation { duration: 60 }
        ParallelAnimation {
            NumberAnimation { target: s; property: "reveal"; from: 0; to: 1; duration: 1050; easing.type: Easing.InOutCubic }
            SequentialAnimation {
                PauseAnimation { duration: 520 }
                NumberAnimation { target: s; property: "contentIn"; from: 0; to: 1; duration: 1100; easing.type: Easing.OutCubic }
            }
        }
        ScriptAction { script: if (s.ctx.phase === "enter") s.ctx.phase = "idle" }
    }
    Connections {
        target: s.ctx
        function onPhaseChanged() {
            if (s.ctx.phase === "unlocking") { enter.stop(); leave.start(); }
        }
    }
    SequentialAnimation {
        id: leave
        NumberAnimation { target: s; property: "contentIn"; to: 0; duration: 340; easing.type: Easing.InCubic }
        NumberAnimation { target: s; property: "reveal"; to: 0; duration: 700; easing.type: Easing.InOutCubic }
    }

    // ---------------------------------------------------------------- backdrop

    Image {
        id: shot
        anchors.fill: parent
        source: s.out.shot ? "file://" + s.out.shot : ""
        fillMode: Image.PreserveAspectCrop
        cache: false
    }

    Item {
        id: sweep
        width: s.diag
        height: s.diag
        x: (s.width - s.diag) / 2
        y: (s.height - s.diag) / 2
        rotation: s.angle

        Item {
            width: sweep.width * s.reveal
            height: sweep.height
            clip: true

            // Counter-rotated so the backdrop lines up with the screen
            Item {
                x: (sweep.width - s.width) / 2
                y: (sweep.height - s.height) / 2
                width: s.width
                height: s.height
                rotation: -s.angle

                Rectangle { anchors.fill: parent; color: "#101216" }
                Image {
                    id: wall
                    anchors.fill: parent
                    source: s.out.wall ? "file://" + s.out.wall : shot.source
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                }
                MultiEffect {
                    anchors.fill: parent
                    source: wall
                    blurEnabled: true
                    blur: 1
                    blurMax: 64
                    blurMultiplier: 1.4
                    brightness: -0.22
                    saturation: 0.2
                }
                Aurora { anchors.fill: parent; accent: s.accent }
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#33000000" }
                        GradientStop { position: 0.5; color: "#1a000000" }
                        GradientStop { position: 1; color: "#8c000000" }
                    }
                }
            }
        }

        // The beam rides the edge of the reveal, trailing a spectrum
        Item {
            x: sweep.width * s.reveal
            width: 1
            height: sweep.height
            opacity: s.reveal > 0.002 && s.reveal < 0.998 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            Rectangle {
                x: -width
                width: 220 * s.u
                height: parent.height
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.00; color: "#00a78bfa" }
                    GradientStop { position: 0.25; color: "#4da78bfa" }
                    GradientStop { position: 0.42; color: "#555bb8ff" }
                    GradientStop { position: 0.58; color: "#5a6fe3a1" }
                    GradientStop { position: 0.72; color: "#5effe066" }
                    GradientStop { position: 0.85; color: "#66ffa552" }
                    GradientStop { position: 0.95; color: "#80ff5f6d" }
                    GradientStop { position: 1.00; color: "#ccffffff" }
                }
            }
            Rectangle {
                x: -1.5
                width: 3
                height: parent.height
                color: "white"
            }
            Rectangle {
                width: 60 * s.u
                height: parent.height
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "#99ffffff" }
                    GradientStop { position: 1; color: "#00ffffff" }
                }
            }
        }
    }

    // ---------------------------------------------------------------- clock

    readonly property real clockSize: Math.round(Math.min(portrait ? 250 * u / 1.45 : 200 * u, width * 0.85 / 4.3))

    Column {
        id: head
        anchors.horizontalCenter: parent.horizontalCenter
        y: s.height * (s.portrait ? 0.15 : 0.11)
        spacing: 0

        Emblem {
            anchors.horizontalCenter: parent.horizontalCenter
            width: implicitWidth * 1.35 * s.u
            height: implicitHeight * 1.35 * s.u
            draw: s.stage(0)
            opacity: s.stage(0)
        }
        Item { width: 1; height: 14 * s.u }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            readonly property real t: s.stage(0.05)
            opacity: t
            text: Qt.formatDate(s.ctx.now, "dddd  ·  d MMMM").toUpperCase()
            color: "#c8ffffff"
            font { family: s.font; pixelSize: Math.round(14 * s.u); styleName: "SemiBold"; letterSpacing: 1 + 4 * t }
        }

        Item { width: 1; height: 4 * s.u }

        Row {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            readonly property date now: s.ctx.now
            readonly property int h: now.getHours()
            readonly property int m: now.getMinutes()
            readonly property int sec: now.getSeconds()

            FontMetrics { id: bigM; font { family: s.display; pixelSize: s.clockSize } }
            FontMetrics { id: smallM; font { family: s.display; pixelSize: s.clockSize * 0.24 } }

            component Rise: Digit {
                property real delay: 0
                readonly property real t: s.stage(delay)
                opacity: t
                transform: Translate { y: (1 - t) * 60 }
            }

            Rise { delay: 0.10; value: Math.floor(clock.h / 10); size: s.clockSize; style: "SemiBold" }
            Rise { delay: 0.14; value: clock.h % 10; size: s.clockSize; style: "SemiBold" }
            Text {
                readonly property real t: s.stage(0.18)
                opacity: t * (0.55 + 0.45 * Math.abs(Math.cos(clock.sec * Math.PI / 2)))
                Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.InOutSine } }
                text: ":"
                color: s.accent
                font { family: s.display; pixelSize: s.clockSize; styleName: "Light" }
            }
            Rise { delay: 0.22; value: Math.floor(clock.m / 10); size: s.clockSize; style: "ExtraLight" }
            Rise { delay: 0.26; value: clock.m % 10; size: s.clockSize; style: "ExtraLight" }
            Item { width: s.clockSize * 0.12; height: 1 }
            Row {
                anchors.bottom: parent.bottom
                // sit on the big digits' baseline
                anchors.bottomMargin: bigM.descent - smallM.descent
                Rise { delay: 0.30; value: Math.floor(clock.sec / 10); size: s.clockSize * 0.24; style: "Medium"; color: s.accent }
                Rise { delay: 0.32; value: clock.sec % 10; size: s.clockSize * 0.24; style: "Medium"; color: s.accent }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            readonly property real t: s.stage(0.34)
            opacity: t * 0.8
            transform: Translate { y: (1 - s.stage(0.34)) * 20 }
            text: {
                const h = s.ctx.now.getHours();
                const g = h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening";
                return g + ", " + (s.ctx.session.user ?? "");
            }
            color: "white"
            font { family: s.font; pixelSize: Math.round(19 * s.u) }
        }
    }

    // ---------------------------------------------------------------- login

    Item {
        id: login
        anchors.horizontalCenter: parent.horizontalCenter
        y: s.height * (s.portrait ? 0.56 : 0.6) - height / 2
        width: 420
        height: 64 + 40
        readonly property real t: s.stage(0.38)
        opacity: Math.min(1, t * 2)

        property real shakeX: 0
        property real chroma: 0
        property real wave: 0
        NumberAnimation on wave {
            running: s.ctx.phase === "checking"
            from: 0; to: Math.PI * 2; duration: 900; loops: Animation.Infinite
        }
        Connections {
            target: s.ctx
            function onWrongCountChanged() { shake.restart(); }
        }
        SequentialAnimation {
            id: shake
            ParallelAnimation {
                NumberAnimation { target: login; property: "chroma"; from: 1; to: 0; duration: 650; easing.type: Easing.OutCubic }
                SequentialAnimation {
                    NumberAnimation { target: login; property: "shakeX"; to: -18; duration: 50 }
                    NumberAnimation { target: login; property: "shakeX"; to: 15; duration: 70 }
                    NumberAnimation { target: login; property: "shakeX"; to: -10; duration: 70 }
                    NumberAnimation { target: login; property: "shakeX"; to: 6; duration: 70 }
                    NumberAnimation { target: login; property: "shakeX"; to: 0; duration: 90; easing.type: Easing.OutQuad }
                }
            }
        }

        // Chromatic split flash on a wrong password
        Repeater {
            model: [{ c: "#ff3b5c", dx: -6 }, { c: "#3bd9ff", dx: 6 }]
            Rectangle {
                required property var modelData
                anchors.horizontalCenter: pill.horizontalCenter
                anchors.horizontalCenterOffset: modelData.dx * login.chroma
                y: pill.y
                width: pill.width
                height: pill.height
                radius: height / 2
                color: "transparent"
                border.width: 2
                border.color: modelData.c
                opacity: login.chroma * 0.8
            }
        }

        Rectangle {
            id: pill
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: login.shakeX
            width: 64 + (login.width - 64) * s.stage(0.42)
            height: 64
            radius: 32
            color: s.glass
            border.width: 1
            border.color: s.ctx.buffer.length > 0 ? Qt.alpha(s.accent, 0.55) : s.edge
            Behavior on border.color { ColorAnimation { duration: 240 } }
            clip: true

            // Avatar: monogram in an accent ring
            Rectangle {
                id: avatar
                x: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 48
                height: 48
                radius: 24
                color: "#14ffffff"
                border.width: 2
                border.color: s.accent
                Text {
                    anchors.centerIn: parent
                    text: (s.ctx.session.user ?? "?").charAt(0).toUpperCase()
                    color: s.accent
                    font { family: s.font; pixelSize: 21; styleName: "SemiBold" }
                }
            }
            // Spinning arc while PAM checks
            Rectangle {
                anchors.centerIn: avatar
                width: 56
                height: 56
                radius: 28
                color: "transparent"
                border.width: 2
                border.color: "transparent"
                visible: s.ctx.phase === "checking"
                Rectangle {
                    width: 8; height: 8; radius: 4
                    color: "white"
                    x: 24 + 26 * Math.cos(login.wave * 2) ; y: 24 + 26 * Math.sin(login.wave * 2)
                }
            }

            Text {
                anchors { left: avatar.right; leftMargin: 18; verticalCenter: parent.verticalCenter }
                opacity: s.ctx.buffer.length === 0 && s.stage(0.6) > 0 ? 0.55 * s.stage(0.6) : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                text: s.ctx.phase === "unlocking" ? "Welcome back" : "Type your password"
                color: "white"
                font { family: s.font; pixelSize: 15 }
            }

            // Password dots, one spectral color per character
            Row {
                anchors { left: avatar.right; leftMargin: 20; verticalCenter: parent.verticalCenter }
                spacing: 9
                Repeater {
                    model: Math.min(s.ctx.buffer.length, 20)
                    Rectangle {
                        id: dot
                        required property int index
                        width: 11; height: 11; radius: 5.5
                        color: s.ctx.phase === "unlocking" ? "white" : Qt.hsla((0.98 - index * 0.06 + 1) % 1, 0.85, 0.68, 1)
                        opacity: s.ctx.phase === "checking" ? 0.35 + 0.65 * (0.5 + 0.5 * Math.sin(login.wave * 2 - index * 0.7)) : 1
                        scale: 0
                        Component.onCompleted: pop.start()
                        NumberAnimation { id: pop; target: dot; property: "scale"; to: 1; duration: 260; easing.type: Easing.OutBack; easing.overshoot: 2.2 }
                    }
                }
            }

            Text {
                anchors { right: parent.right; rightMargin: 22; verticalCenter: parent.verticalCenter }
                visible: s.ctx.buffer.length > 0
                text: "\u{F0054}"           // arrow-right
                color: s.accent
                font { family: s.icons; pixelSize: 20 }
            }
        }

        Text {
            anchors { horizontalCenter: parent.horizontalCenter; top: pill.bottom; topMargin: 14 }
            text: s.ctx.message
            opacity: s.ctx.message ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            color: s.warn
            font { family: s.font; pixelSize: 13; styleName: "Medium" }
        }
    }

    // ---------------------------------------------------------------- bottom

    readonly property real edgeGap: Math.round(36 * u)

    // Now playing
    readonly property var player: s.ctx.demo ? null : (Mpris.players.values.find(p => p.isPlaying) ?? null)
    Timer {
        interval: 1000; running: s.player !== null; repeat: true
        onTriggered: s.player.positionChanged()
    }

    Rectangle {
        id: music
        visible: s.player !== null
        width: 400
        height: 96
        radius: 28
        color: s.glass
        border.width: 1
        border.color: s.edge
        x: s.portrait ? (s.width - width) / 2 : s.edgeGap
        y: s.height - s.edgeGap - height - (s.portrait ? 40 + 18 : 0)
        readonly property real t: s.stage(0.5)
        opacity: t
        transform: Translate { y: (1 - music.t) * 40 }

        ClippingRectangle {
            id: art
            x: 16
            anchors.verticalCenter: parent.verticalCenter
            width: 64; height: 64; radius: 16
            color: "#14ffffff"
            Image {
                anchors.fill: parent
                source: s.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
            // Slow spin of the art's sheen while playing
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0; color: "#22ffffff" }
                    GradientStop { position: 0.5; color: "transparent" }
                }
            }
        }
        Column {
            anchors { left: art.right; leftMargin: 16; right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }
            spacing: 3
            Text {
                text: "NOW PLAYING"
                color: s.accent
                font { family: s.font; pixelSize: 10; styleName: "SemiBold"; letterSpacing: 2 }
            }
            Text {
                width: parent.width
                text: s.player?.trackTitle || "Unknown"
                elide: Text.ElideRight
                color: "white"
                font { family: s.font; pixelSize: 15; styleName: "SemiBold" }
            }
            Text {
                width: parent.width
                text: s.player?.trackArtist ?? ""
                elide: Text.ElideRight
                color: "#b3ffffff"
                font { family: s.font; pixelSize: 13 }
            }
            Item { width: 1; height: 4 }
            Rectangle {
                width: parent.width; height: 3; radius: 1.5
                color: "#24ffffff"
                Rectangle {
                    height: parent.height; radius: 1.5
                    color: s.accent
                    width: s.player && s.player.length > 0 ? parent.width * Math.min(1, s.player.position / s.player.length) : 0
                    Behavior on width { NumberAnimation { duration: 900 } }
                }
            }
        }
    }

    // Status chips
    component Chip: Rectangle {
        property string text
        height: 40
        width: label.implicitWidth + 32
        radius: 20
        color: s.glass
        border.width: 1
        border.color: s.edge
        Text {
            id: label
            anchors.centerIn: parent
            text: parent.text
            color: "white"
            font { family: s.font; pixelSize: 13; styleName: "Medium" }
        }
    }

    Row {
        id: chips
        spacing: 10
        x: s.portrait ? (s.width - width) / 2 : s.width - s.edgeGap - width
        y: s.height - s.edgeGap - height
        readonly property real t: s.stage(0.55)
        opacity: t
        transform: Translate { y: (1 - chips.t) * 40 }

        readonly property var bat: UPower.displayDevice
        Chip {
            visible: chips.bat && chips.bat.isLaptopBattery
            readonly property real pct: chips.bat ? chips.bat.percentage : 0
            readonly property bool charging: chips.bat && chips.bat.state === UPowerDeviceState.Charging
            text: (charging ? "\u{F0084}" : pct > 0.9 ? "\u{F0079}" : pct > 0.7 ? "\u{F0080}" : pct > 0.5 ? "\u{F007E}" : pct > 0.3 ? "\u{F007C}" : pct > 0.15 ? "\u{F007A}" : "\u{F008E}") + "  " + Math.round(pct * 100) + "%"
        }
        Chip { visible: s.ctx.weather !== ""; text: s.ctx.weather }
        Chip { visible: s.ctx.layout !== ""; text: "\u{F030C}  " + s.ctx.layout }
    }
}
