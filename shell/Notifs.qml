pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Notification count and do-not-disturb state, streamed from swaync.
Singleton {
    id: root

    property int count: 0
    property bool dnd: false

    function togglePanel() { Quickshell.execDetached(["swaync-client", "-t", "-sw"]); }
    function toggleDnd() { Quickshell.execDetached(["swaync-client", "-d", "-sw"]); }

    // Emits one JSON line per change: {"text": "3", "alt": "dnd-notification", ...}
    Process {
        id: sub
        command: ["swaync-client", "-swb"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    const s = JSON.parse(line);
                    root.count = parseInt(s.text) || 0;
                    root.dnd = (s.alt || "").startsWith("dnd");
                } catch (e) {}
            }
        }
        // swaync restarts (e.g. after a theme reload) end the stream; reconnect.
        onExited: retry.start()
    }

    Timer {
        id: retry
        interval: 2000
        onTriggered: sub.running = true
    }
}
