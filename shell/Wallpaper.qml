pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Current wallpaper per output, as reported by swww. The primary output's
// image drives the accent color (see Theme).
Singleton {
    id: root

    property var byOutput: ({})          // output name -> image path
    readonly property string primaryOutput: "eDP-1"
    readonly property string primary: byOutput[primaryOutput] ?? Object.values(byOutput)[0] ?? ""

    // ": eDP-1: 1920x1200, scale: 1, currently displaying: image: /path.png"
    Process {
        id: query
        command: ["swww", "query"]
        property var acc: ({})
        stdout: SplitParser {
            onRead: line => {
                const m = line.match(/^:?\s*([^:]+):.*image:\s*(.+)$/);
                if (m) query.acc[m[1].trim()] = m[2].trim();
            }
        }
        onExited: {
            if (JSON.stringify(acc) !== JSON.stringify(root.byOutput)) root.byOutput = acc;
            acc = {};
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: query.running = true
    }
}
