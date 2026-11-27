pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Read and change Hyprland options at runtime, on both config generations:
// 0.56 (hyprlang: `hyprctl keyword`) and 0.57+ (Lua: `hyprctl eval`).
Singleton {
    id: root

    property bool blur: true
    property string layout: "dwindle"
    property bool gameMode: false
    property var saved: ({})             // option values to restore when game mode ends

    // "decoration:blur:enabled" -> hl.config({ decoration = { blur = { enabled = v } } })
    function luaFor(path, value) {
        const parts = path.split(":");
        const lit = typeof value === "string" ? JSON.stringify(value) : String(value);
        let s = parts[parts.length - 1] + " = " + lit;
        for (let i = parts.length - 2; i >= 0; i--) s = parts[i] + " = { " + s + " }";
        return "hl.config({ " + s + " })";
    }

    function set(path, value) {
        if (Hyprland.usingLua)
            Quickshell.execDetached(["hyprctl", "eval", luaFor(path, value)]);
        else
            Quickshell.execDetached(["hyprctl", "keyword", path, String(value)]);
    }

    function setBlur(on) { blur = on; set("decoration:blur:enabled", on); }
    function setLayout(name) { layout = name; set("general:layout", name); }

    // Game mode: strip animations, blur, shadows, gaps and rounding; remember
    // the previous values so turning it off restores them exactly.
    readonly property var gameOptions: ({
        "animations:enabled": false,
        "decoration:blur:enabled": false,
        "decoration:shadow:enabled": false,
        "general:gaps_in": 0,
        "general:gaps_out": 0,
        "decoration:rounding": 0
    })

    function setGameMode(on) {
        if (on === gameMode) return;
        gameMode = on;
        if (on) {
            for (const k in gameOptions) set(k, gameOptions[k]);
        } else {
            for (const k in saved) set(k, saved[k]);
        }
    }

    // Snapshot current values (refreshed whenever game mode is off)
    Process {
        id: snapshot
        command: ["sh", "-c", "for o in " + Object.keys(root.gameOptions).join(" ") + " general:layout; do printf '%s\\t' \"$o\"; hyprctl -j getoption \"$o\" | tr -d '\\n'; echo; done"]
        stdout: SplitParser {
            onRead: line => {
                const [key, json] = line.split("\t");
                try {
                    const o = JSON.parse(json);
                    let v = o.int ?? o.float ?? o.str ?? o.custom;
                    if (key.endsWith("gaps_in") || key.endsWith("gaps_out"))
                        v = parseInt(String(v).trim().split(/\s+/)[0]) || 0;   // "5 5 5 5" -> 5
                    if (key === "general:layout") { root.layout = v; return; }
                    if (key === "decoration:blur:enabled") root.blur = !!v;
                    if (!root.gameMode) root.saved = Object.assign({}, root.saved, { [key]: typeof v === "number" && (key.endsWith("enabled")) ? !!v : v });
                } catch (e) {}
            }
        }
    }
    function refresh() { snapshot.running = true; }
    Component.onCompleted: refresh()
}
