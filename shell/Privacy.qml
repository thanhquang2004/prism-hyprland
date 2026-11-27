pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// What is recording right now: microphone, camera, screen share.
Singleton {
    id: root

    readonly property var nodes: Pipewire.nodes.values
    function prop(n, k) { return n.properties ? n.properties[k] : undefined; }

    // Real mic capture: audio input streams, minus ones that only listen to
    // an output (cava, EasyEffects meters set stream.capture.sink).
    readonly property var micStreams: nodes.filter(n =>
        prop(n, "media.class") === "Stream/Input/Audio" && String(prop(n, "stream.capture.sink")) !== "true")
    readonly property bool mic: micStreams.length > 0
    readonly property bool micMuted: Pipewire.defaultAudioSource?.audio?.muted ?? false

    // Screen share: xdg-desktop-portal-hyprland exposes its capture as a node
    readonly property var shareNodes: nodes.filter(n =>
        String(prop(n, "node.name") ?? "").startsWith("xdph") || prop(n, "media.class") === "Stream/Output/Video")
    readonly property bool sharing: shareNodes.length > 0

    // Camera: PipeWire video capture, or an app holding /dev/video* directly (Chrome)
    property bool cameraDevice: false
    readonly property bool camera: cameraDevice || nodes.some(n => prop(n, "media.class") === "Stream/Input/Video")

    readonly property bool any: mic || camera || sharing

    function toggleMic() { Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]); }

    // Stop sharing by destroying the portal's capture node; the app sees the stream end.
    function stopSharing() {
        for (const n of shareNodes) Quickshell.execDetached(["pw-cli", "destroy", String(n.id)]);
    }

    PwObjectTracker { objects: root.nodes }

    Process {
        id: fuser
        command: ["sh", "-c", "fuser /dev/video* 2>/dev/null | grep -q '[0-9]'"]
        onExited: code => root.cameraDevice = code === 0
    }
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: fuser.running = true
    }

    IpcHandler {
        target: "privacy"
        function toggleMic(): void { root.toggleMic(); }
        function state(): string { return JSON.stringify({ mic: root.mic, micMuted: root.micMuted, camera: root.camera, sharing: root.sharing, micApps: root.micStreams.map(n => root.prop(n, "application.name") || n.name) }); }
    }
}
