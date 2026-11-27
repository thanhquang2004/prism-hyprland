pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications

// Prism's own notification daemon (replaces swaync): keeps the history,
// groups it by app, queues popups and handles do-not-disturb.
Singleton {
    id: root

    property bool dnd: false
    property bool panelOpen: false
    property var panelScreen: null
    property var popups: []              // newest first, at most maxPopups
    property var times: ({})             // notification id -> arrival time (ms)
    readonly property int maxPopups: 3

    // Newest first
    readonly property var list: server.trackedNotifications.values.slice().reverse()
    readonly property int count: list.length

    // [{ key, app, items: [notification, ...] }], ordered by newest item
    readonly property var groups: {
        const out = [];
        const byKey = {};
        for (const n of list) {
            const k = keyOf(n);
            if (!byKey[k]) {
                byKey[k] = { key: k, app: n.appName || n.desktopEntry || "Unknown", items: [] };
                out.push(byKey[k]);
            }
            byKey[k].items.push(n);
        }
        return out;
    }

    function keyOf(n) { return (n.desktopEntry || n.appName || "unknown").toLowerCase(); }
    function timeOf(n) { return times[n.id] ?? Date.now(); }

    function focusedScreen() {
        return Quickshell.screens.find(s => Hyprland.monitorFor(s)?.focused) ?? Quickshell.screens[0];
    }

    function togglePanel(screen) {
        const s = screen ?? focusedScreen();
        if (panelOpen && panelScreen === s) {
            panelOpen = false;
        } else {
            panelScreen = s;
            panelOpen = true;
            popups = [];
        }
    }

    function dropPopup(n) { popups = popups.filter(p => p !== n); }
    function dismiss(n) { dropPopup(n); n.dismiss(); }
    function dismissGroup(key) { for (const n of list.filter(x => keyOf(x) === key)) dismiss(n); }
    function clearAll() { popups = []; for (const n of list) n.dismiss(); }

    // Click on a notification: run its default action, else open its app.
    function activate(n) {
        const def = n.actions.find(a => a.identifier === "default");
        if (def) {
            def.invoke();
        } else if (n.desktopEntry) {
            const entry = DesktopEntries.byId(n.desktopEntry);
            if (entry) entry.execute();
        }
        dismiss(n);
        panelOpen = false;
    }

    NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true;
            root.times = Object.assign({}, root.times, { [n.id]: Date.now() });
            if (!root.dnd && !root.panelOpen)
                root.popups = [n].concat(root.popups).slice(0, root.maxPopups);
        }
    }

    IpcHandler {
        target: "notifs"
        function toggle(): void { root.togglePanel(null); }
        function toggleDnd(): void { root.dnd = !root.dnd; }
        function clear(): void { root.clearAll(); }
    }
}
