pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Power menu state and actions. Destructive actions (logout, reboot,
// shutdown) run only after a 5 second countdown that can be cancelled.
// PRISM_DRYRUN=1 logs actions instead of running them (for testing).
Singleton {
    id: root

    property bool open: false
    property string pending: ""          // action waiting on the countdown
    property int remaining: 0
    readonly property int countdown: 5
    readonly property bool dryRun: Quickshell.env("PRISM_DRYRUN") === "1"

    readonly property var actions: [
        { id: "lock",     label: "Lock",     key: "L", confirm: false },
        { id: "logout",   label: "Log out",  key: "E", confirm: true },
        { id: "suspend",  label: "Sleep",    key: "S", confirm: false },
        { id: "reboot",   label: "Restart",  key: "R", confirm: true },
        { id: "shutdown", label: "Shut down", key: "P", confirm: true }
    ]

    function toggle() { open ? close() : show(); }
    function show() { pending = ""; open = true; }
    function close() { cancel(); open = false; }

    function choose(id) {
        const a = actions.find(x => x.id === id);
        if (!a) return;
        if (a.confirm) {
            pending = id;
            remaining = countdown;
            tick.restart();
        } else {
            close();
            run(id);
        }
    }

    function cancel() { tick.stop(); pending = ""; }

    function run(id) {
        const logoutCmd = Hyprland.usingLua ? "hl.dsp.exit()" : "exit";
        const cmds = {
            lock: ["loginctl", "lock-session"],
            suspend: ["systemctl", "suspend"],
            reboot: ["systemctl", "reboot"],
            shutdown: ["systemctl", "poweroff"]
        };
        if (dryRun) {
            console.log("PRISM_DRYRUN would run:", id === "logout" ? "hyprctl dispatch " + logoutCmd : cmds[id].join(" "));
            return;
        }
        if (id === "logout")
            Hyprland.dispatch(logoutCmd);
        else
            Quickshell.execDetached(cmds[id]);
    }

    Timer {
        id: tick
        interval: 1000
        repeat: true
        onTriggered: {
            root.remaining -= 1;
            if (root.remaining <= 0) {
                const id = root.pending;
                stop();
                root.pending = "";
                root.open = false;
                root.run(id);
            }
        }
    }
}
