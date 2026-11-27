import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Wayland
import ".."
import "../power"

// Control center: drops down under the right side of the bar on the screen
// it was opened from. Quick toggles, sliders, detail pages for Wi-Fi,
// Bluetooth and sound. Click outside or Esc to close (Esc on a detail page goes back).
Scope {
    id: scope

    readonly property string hyprScripts: Quickshell.env("HOME") + "/.config/hypr/scripts"
    readonly property string userScripts: Quickshell.env("HOME") + "/.config/hypr/UserScripts"

    // Airplane mode = every radio soft-blocked
    property bool airplane: false
    Process {
        id: rfkill
        command: ["sh", "-c", "rfkill -n -o SOFT | grep -qv '^blocked' && echo no || echo yes"]
        stdout: SplitParser { onRead: line => scope.airplane = line.trim() === "yes" }
    }
    Timer { interval: 3000; running: Cc.open; repeat: true; triggeredOnStart: true; onTriggered: rfkill.running = true }

    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]); }

    LazyLoader {
        active: Cc.open

        PanelWindow {
            id: win

            screen: Cc.screen
            anchors { top: true; right: true }
            margins { top: 6; right: Theme.barGap + 2 }
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: 0
            implicitWidth: 430
            implicitHeight: (screen ? screen.height : 1080) * 0.85   // fixed surface, panel animates inside
            color: "transparent"
            mask: Region { item: panel }

            WlrLayershell.namespace: "prism-cc"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            HyprlandFocusGrab {
                windows: [win]
                active: true
                onCleared: Cc.open = false
            }

            readonly property var sink: Pipewire.defaultAudioSink
            readonly property var source: Pipewire.defaultAudioSource
            readonly property var bt: Bluetooth.defaultAdapter
            readonly property var btConnected: bt ? bt.devices.values.filter(d => d.connected) : []
            readonly property var wifiDev: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
            readonly property var wifiNet: wifiDev && wifiDev.networks ? wifiDev.networks.values.find(n => n.connected) ?? null : null
            readonly property var battery: UPower.displayDevice

            PwObjectTracker { objects: [win.sink, win.source] }

            Rectangle {
                id: panel
                width: parent.width
                height: Math.min(content.implicitHeight + 36, win.implicitHeight)
                Behavior on height { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutCubic } }
                radius: 28
                clip: true
                color: Theme.glass
                border.width: 1
                border.color: Theme.edge
                focus: true
                Keys.onEscapePressed: Cc.page !== "main" ? Cc.page = "main" : Cc.open = false

                // Drop in on open
                opacity: 0
                y: -12
                Component.onCompleted: { opacity = 1; y = 0; }
                Behavior on opacity { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }

                Flickable {
                    anchors { fill: parent; margins: 18 }
                    contentHeight: content.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    Item {
                        id: content
                        width: parent.width
                        implicitHeight: Cc.page === "main" ? main.implicitHeight : detail.implicitHeight

                        // Main page slides left when a detail page opens
                        Column {
                            id: main
                            width: parent.width
                            spacing: 14
                            x: Cc.page === "main" ? 0 : -width - 40
                            opacity: Cc.page === "main" ? 1 : 0
                            Behavior on x { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: Theme.animMed } }

                            // Header: date, battery
                            Item {
                                width: parent.width
                                height: 30
                                SystemClock { id: clock; precision: SystemClock.Minutes }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
                                    color: Theme.text
                                    font { family: Theme.font; pixelSize: 17; weight: Font.Bold }
                                }
                                Text {
                                    visible: win.battery && win.battery.isLaptopBattery
                                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                    readonly property real pct: win.battery ? win.battery.percentage : 0
                                    readonly property bool charging: win.battery && win.battery.state === UPowerDeviceState.Charging
                                    readonly property int secs: win.battery ? (charging ? win.battery.timeToFull : win.battery.timeToEmpty) : 0
                                    text: Math.round(pct * 100) + "%" + (secs > 0 ? "  ·  " + Math.floor(secs / 3600) + "h " + Math.round(secs % 3600 / 60) + "m" + (charging ? " to full" : " left") : "")
                                    color: Theme.textDim
                                    font { family: Theme.font; pixelSize: 12; weight: Font.Medium; features: { "tnum": 1 } }
                                }
                            }

                            // Quick toggles
                            Grid {
                                id: tiles
                                width: parent.width
                                columns: 2
                                columnSpacing: 10
                                rowSpacing: 10
                                readonly property real tileW: (width - columnSpacing) / 2

                                Tile {
                                    width: tiles.tileW
                                    icon: Networking.wifiEnabled ? Icons.wifi : Icons.wifiOff
                                    label: "Wi-Fi"
                                    sublabel: !Networking.wifiEnabled ? "Off" : win.wifiNet ? win.wifiNet.name : "Not connected"
                                    active: Networking.wifiEnabled
                                    hasDetail: true
                                    onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                                    onDetail: Cc.page = "wifi"
                                }
                                Tile {
                                    width: tiles.tileW
                                    icon: win.bt && win.bt.enabled ? Icons.bluetooth : Icons.bluetoothOff
                                    label: "Bluetooth"
                                    sublabel: !(win.bt && win.bt.enabled) ? "Off" : win.btConnected.length ? win.btConnected[0].name : "On"
                                    active: win.bt ? win.bt.enabled : false
                                    hasDetail: true
                                    onToggled: if (win.bt) win.bt.enabled = !win.bt.enabled
                                    onDetail: Cc.page = "bluetooth"
                                }
                                Tile {
                                    width: tiles.tileW
                                    icon: Icons.bellOff
                                    label: "Do not disturb"
                                    active: Notifs.dnd
                                    onToggled: Notifs.dnd = !Notifs.dnd
                                }
                                Tile {
                                    width: tiles.tileW
                                    icon: Icons.nightLight
                                    label: "Night light"
                                    active: Theme.nightOn
                                    onToggled: scope.run(scope.hyprScripts + "/Hyprsunset.sh toggle")
                                }
                                Tile {
                                    width: tiles.tileW
                                    icon: Icons.darkMode
                                    label: "Dark mode"
                                    sublabel: Theme.manual === "" ? "Follows night light" : "Manual"
                                    active: Theme.dark
                                    onToggled: Theme.toggleDark()
                                }
                                Tile {
                                    width: tiles.tileW
                                    icon: Icons.airplane
                                    label: "Airplane mode"
                                    active: scope.airplane
                                    onToggled: {
                                        scope.run(scope.airplane ? "rfkill unblock all" : "rfkill block all");
                                        scope.airplane = !scope.airplane;
                                    }
                                }
                                Tile {
                                    width: tiles.tileW
                                    icon: Icons.gamepad
                                    label: "Game mode"
                                    sublabel: Hypr.gameMode ? "Effects off" : ""
                                    active: Hypr.gameMode
                                    onToggled: Hypr.setGameMode(!Hypr.gameMode)
                                }
                                Tile {
                                    width: tiles.tileW
                                    icon: Icons.blur
                                    label: "Blur"
                                    active: Hypr.blur && !Hypr.gameMode
                                    onToggled: Hypr.setBlur(!Hypr.blur)
                                }
                                Tile {
                                    width: tiles.tileW
                                    icon: Icons.layout
                                    label: "Layout"
                                    sublabel: Hypr.layout === "master" ? "Master" : "Dwindle"
                                    active: Hypr.layout === "master"
                                    onToggled: Hypr.setLayout(Hypr.layout === "master" ? "dwindle" : "master")
                                }
                                Tile {
                                    width: tiles.tileW
                                    icon: Icons.screenshot
                                    label: "Screenshot"
                                    sublabel: "Select area"
                                    onToggled: {
                                        Cc.open = false;
                                        scope.run("sleep 0.3; " + scope.hyprScripts + "/ScreenShot.sh --area");
                                    }
                                }
                            }

                            // Sliders
                            Column {
                                width: parent.width
                                spacing: 2

                                Slider {
                                    width: parent.width
                                    icon: win.sink && win.sink.audio.muted ? Icons.volMute : Icons.volHigh
                                    value: win.sink ? win.sink.audio.volume : 0
                                    muted: win.sink ? win.sink.audio.muted : false
                                    showDetail: true
                                    onMoved: v => { if (win.sink) win.sink.audio.volume = v; }
                                    onIconClicked: if (win.sink) win.sink.audio.muted = !win.sink.audio.muted
                                    onDetail: Cc.page = "audio"
                                }
                                Slider {
                                    width: parent.width
                                    icon: win.source && win.source.audio.muted ? Icons.micOff : Icons.mic
                                    value: win.source ? win.source.audio.volume : 0
                                    muted: win.source ? win.source.audio.muted : false
                                    showDetail: true
                                    onMoved: v => { if (win.source) win.source.audio.volume = v; }
                                    onIconClicked: if (win.source) win.source.audio.muted = !win.source.audio.muted
                                    onDetail: Cc.page = "audio"
                                }
                                Slider {
                                    width: parent.width
                                    icon: Icons.brightness
                                    value: Osd.brightness
                                    showDetail: false
                                    onMoved: v => { Osd.brightness = v; Osd.setBrightness(v); }
                                }
                            }

                            // Footer
                            Row {
                                anchors.right: parent.right
                                spacing: 8

                                component FootButton: Rectangle {
                                    property string icon
                                    signal clicked()
                                    signal rightClicked()
                                    width: 40
                                    height: 40
                                    radius: 20
                                    color: fh.hovered ? Theme.chipHover : Theme.chip
                                    Text {
                                        anchors.centerIn: parent
                                        text: parent.icon
                                        color: Theme.text
                                        font { family: Theme.iconFont; pixelSize: 18 }
                                    }
                                    HoverHandler { id: fh; cursorShape: Qt.PointingHandCursor }
                                    TapHandler { onTapped: parent.clicked() }
                                    TapHandler { acceptedButtons: Qt.RightButton; onTapped: parent.rightClicked() }
                                }

                                // Next wallpaper on this screen; right click: every screen
                                FootButton {
                                    icon: Icons.wallpaper
                                    onClicked: Wallpaper.shuffle(Cc.screen ? Cc.screen.name : "")
                                    onRightClicked: Wallpaper.shuffle("")
                                }
                                FootButton {
                                    icon: Icons.lock
                                    onClicked: { Cc.open = false; scope.run("loginctl lock-session"); }
                                }
                                FootButton {
                                    icon: Icons.shutdown
                                    onClicked: { Cc.open = false; Power.show(); }
                                }
                            }
                        }

                        // Detail page slides in from the right
                        Loader {
                            id: detail
                            width: parent.width
                            x: Cc.page === "main" ? width + 40 : 0
                            opacity: Cc.page === "main" ? 0 : 1
                            Behavior on x { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: Theme.animMed } }
                            active: Cc.page !== "main"
                            source: Cc.page === "wifi" ? "WifiPage.qml" : Cc.page === "bluetooth" ? "BluetoothPage.qml" : Cc.page === "audio" ? "AudioPage.qml" : ""
                        }
                    }
                }
            }
        }
    }
}
