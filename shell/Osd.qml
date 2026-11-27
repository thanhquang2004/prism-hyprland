pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "cc"

// On-screen display state: shows volume, mic mute and brightness changes
// for a moment under the bar on the focused screen.
Singleton {
    id: root

    property string kind: "volume"       // "volume" | "mic" | "brightness"
    property real value: 0               // 0..1 (volume may exceed 1 with boost)
    property bool muted: false
    property bool shown: false           // visible (fading in / holding)
    property bool alive: false           // window exists (also while fading out)
    property real brightness: 1          // backlight level 0..1, kept current for the control center

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    PwObjectTracker { objects: [root.sink, root.source] }

    function show(k, v, m) {
        if (Cc.open) return;             // the control center shows its own sliders
        kind = k;
        value = v;
        muted = m;
        alive = true;
        shown = true;
        hold.restart();
    }

    // Ignore the burst of change signals while PipeWire binds at startup
    property bool armed: false
    Timer { running: true; interval: 1500; onTriggered: root.armed = true }
    Component.onCompleted: readBrightness.running = true

    function setBrightness(v) {
        Quickshell.execDetached(["brightnessctl", "-q", "--class=backlight", "set", Math.round(Math.max(0.01, v) * 100) + "%"]);
    }

    Timer { id: hold; interval: 1400; onTriggered: { root.shown = false; fade.restart(); } }
    Timer { id: fade; interval: 260; onTriggered: if (!root.shown) root.alive = false }

    Connections {
        target: root.sink ? root.sink.audio : null
        function onVolumeChanged() { if (root.armed) root.show("volume", root.sink.audio.volume, root.sink.audio.muted); }
        function onMutedChanged() { if (root.armed) root.show("volume", root.sink.audio.volume, root.sink.audio.muted); }
    }

    Connections {
        target: root.source ? root.source.audio : null
        function onMutedChanged() { if (root.armed) root.show("mic", root.source.audio.volume, root.source.audio.muted); }
    }

    // Brightness: the kernel emits a udev "change" event on every backlight
    // write, so listen instead of polling, then ask brightnessctl for the level.
    Process {
        command: ["udevadm", "monitor", "--kernel", "--subsystem-match=backlight"]
        running: true
        stdout: SplitParser {
            onRead: line => { if (line.includes("change")) readBrightness.running = true; }
        }
    }

    // Machine output: "device,class,current,percent%,max"
    Process {
        id: readBrightness
        command: ["brightnessctl", "-m", "--class=backlight"]
        stdout: SplitParser {
            onRead: line => {
                const pct = parseInt(line.split(",")[3]);
                if (isNaN(pct)) return;
                root.brightness = pct / 100;
                if (root.armed) root.show("brightness", root.brightness, false);
            }
        }
    }

    IpcHandler {
        target: "osd"
        function test(kind: string): void { root.show(kind, 0.62, false); }
    }
}
