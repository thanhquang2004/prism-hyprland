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
    readonly property color glassHover: Qt.rgba(1, 1, 1, 0.22)
    readonly property color edge: Qt.rgba(1, 1, 1, 0.32)
    readonly property color edgeTop: Qt.rgba(1, 1, 1, 0.55)

    // Text
    readonly property color text: "#ffffff"
    readonly property color textDim: Qt.rgba(1, 1, 1, 0.72)
    readonly property color accent: "#ffffff"

    // Type
    readonly property string font: "Inter"
    readonly property string iconFont: "JetBrainsMono Nerd Font"

    // Shape & motion
    readonly property int islandHeight: 36
    readonly property int islandTopMargin: 8
    readonly property int radius: islandHeight / 2
    readonly property int animFast: 180
    readonly property int animMed: 260
}
