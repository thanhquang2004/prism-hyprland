pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Design tokens for Prism. Two glass modes:
//   dark  = "Smoke" (smoky dark glass, white text)
//   light = "Milky" (milky light glass, dark text)
// The mode follows night light (hyprsunset on -> dark, off -> light) unless
// toggled by hand from the bar; the manual choice lasts until night light
// changes again.
Singleton {
    id: root

    // Night light state, written by ~/.config/hypr/scripts/Hyprsunset.sh
    FileView {
        id: nightLight
        path: Quickshell.env("HOME") + "/.cache/.hyprsunset_state"
        watchChanges: true
        onFileChanged: {
            reload();
            root.setManual("");
        }
    }

    // Manual override: "", "dark" or "light"
    FileView {
        id: manualFile
        path: Quickshell.env("HOME") + "/.cache/prism/theme"
        printErrors: false
    }
    readonly property string manual: manualFile.text().trim()
    readonly property bool nightOn: nightLight.text().trim() === "on"
    readonly property bool dark: manual !== "" ? manual === "dark" : nightOn

    function setManual(mode) {
        if (manual !== mode) manualFile.setText(mode);
    }
    IpcHandler {
        target: "theme"
        function toggle(): void { root.toggleDark(); }
        function mode(): string { return root.dark ? "dark" : "light"; }
    }

    function toggleDark() {
        const next = dark ? "light" : "dark";
        // Back to following night light if that already gives the wanted mode
        setManual((next === "dark") === nightOn ? "" : next);
    }

    // Glass. Keep alpha above the layer's ignore_alpha (0.1) or Hyprland skips the blur.
    readonly property color glass: dark ? Qt.rgba(0.06, 0.07, 0.09, 0.48) : Qt.rgba(0.97, 0.97, 0.99, 0.62)
    readonly property color edge: dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.50)
    readonly property color chip: dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)
    readonly property color chipHover: dark ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(0, 0, 0, 0.10)
    readonly property color chipActive: dark ? Qt.rgba(1, 1, 1, 0.28) : Qt.rgba(0, 0, 0, 0.15)
    readonly property color scrim: dark ? Qt.rgba(0.03, 0.03, 0.05, 0.45) : Qt.rgba(0.95, 0.95, 0.97, 0.35)

    // Text and icons (monochrome: one ink color at three strengths)
    readonly property color text: dark ? "#ffffff" : "#17181c"
    readonly property color textDim: Qt.alpha(text, 0.72)
    readonly property color textFaint: Qt.alpha(text, 0.45)
    readonly property color accent: text
    readonly property color warn: dark ? "#ffb4a2" : "#b3261e"

    // Type
    readonly property string font: "Inter"
    readonly property string iconFont: "JetBrainsMono Nerd Font"

    // Bar geometry
    readonly property int barHeight: 38
    readonly property int barGap: 8        // distance from screen edges
    readonly property int radius: barHeight / 2
    readonly property int chipHeight: 26

    // Motion
    readonly property int animFast: 160
    readonly property int animMed: 240
}
