pragma Singleton

import QtQuick
import Quickshell

// Design tokens for Prism. Colors are static placeholders until the
// wallust palette lands in phase 3.
Singleton {
    id: root

    // Glass ("Frost": white frosted glass). Keep alpha above the
    // layer's ignore_alpha (0.1) or Hyprland skips the blur.
    readonly property color glass: Qt.rgba(1, 1, 1, 0.16)
    readonly property color edge: Qt.rgba(1, 1, 1, 0.18)
    readonly property color chip: Qt.rgba(1, 1, 1, 0.10)
    readonly property color chipHover: Qt.rgba(1, 1, 1, 0.20)
    readonly property color chipActive: Qt.rgba(1, 1, 1, 0.30)

    // Text
    readonly property color text: "#ffffff"
    readonly property color textDim: Qt.rgba(1, 1, 1, 0.72)
    readonly property color textFaint: Qt.rgba(1, 1, 1, 0.45)
    readonly property color accent: "#ffffff"
    readonly property color warn: "#ffb4a2"

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
