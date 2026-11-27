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
    property var expanded: ({})          // group key -> expanded, kept across panel reopen
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

    function toggleGroup(key) { expanded = Object.assign({}, expanded, { [key]: !expanded[key] }); }

    // Removal is two-step so cards can animate out: mark as leaving (cards
    // play their exit animation), then the reaper removes them for real.
    property var leaving: ({})           // id -> { at: exit start (ms), n, popupOnly }
    readonly property int leaveMs: 340   // must cover NotifCard's exit animation
    readonly property int stagger: 35

    function isLeaving(n) { return !!n && leaving[n.id] !== undefined; }
    function leaveDelay(n) { return isLeaving(n) ? Math.max(0, leaving[n.id].at - Date.now()) : 0; }

    function markLeaving(n, delay, popupOnly) {
        if (!n || isLeaving(n)) return;
        leaving = Object.assign({}, leaving, { [n.id]: { at: Date.now() + delay, n: n, popupOnly: popupOnly } });
        reaper.start();
    }

    function dropPopup(n) { popups = popups.filter(p => p !== n); }
    function hidePopup(n) { markLeaving(n, 0, true); }
    function dismiss(n, delay) { markLeaving(n, delay ?? 0, false); }
    function dismissGroup(key) { list.filter(x => keyOf(x) === key).forEach((n, i) => dismiss(n, i * stagger)); }
    function clearAll() { list.forEach((n, i) => dismiss(n, i * stagger)); }

    Timer {
        id: reaper
        interval: 40
        repeat: true
        onTriggered: {
            const now = Date.now();
            const keep = {};
            let changed = false;
            for (const id in root.leaving) {
                const e = root.leaving[id];
                if (now >= e.at + root.leaveMs) {
                    root.dropPopup(e.n);
                    if (!e.popupOnly) e.n.dismiss();
                    changed = true;
                } else {
                    keep[id] = e;
                }
            }
            if (changed) root.leaving = keep;
            if (Object.keys(keep).length === 0) stop();
        }
    }

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
            // Volume/brightness/mute feedback from the old hypr scripts: the OSD
            // already shows these, so don't keep or pop them.
            const h = n.hints || {};
            if (n.transient && (h["x-canonical-private-synchronous"] !== undefined || h["SWAYNC_BYPASS_DND"] !== undefined))
                return;
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
        function dismissGroup(key: string): void { root.dismissGroup(key); }
        function dismissLatest(): void { root.dismiss(root.list.find(n => !root.isLeaving(n))); }
        function toggleGroup(key: string): void { root.toggleGroup(key); }
    }
}
