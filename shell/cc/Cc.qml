pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import ".."

// Control center state: open on which screen, which page.
Singleton {
    id: root

    property bool open: false
    property var screen: null
    property string page: "main"         // "main" | "wifi" | "bluetooth" | "audio"

    function toggle(s) {
        const target = s ?? Notifs.focusedScreen();
        if (open && screen === target) {
            open = false;
        } else {
            screen = target;
            page = "main";
            Notifs.panelOpen = false;
            open = true;
        }
    }

    IpcHandler {
        target: "cc"
        function toggle(): void { root.toggle(null); }
        function page(name: string): void { root.page = name; }
        function state(): string { return JSON.stringify({ open: root.open, page: root.page, screen: root.screen ? root.screen.name : null }); }
    }
}
