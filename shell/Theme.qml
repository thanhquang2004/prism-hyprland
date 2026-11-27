pragma Singleton

import QtQuick
import Quickshell

// Design tokens for Prism. Colors are static placeholders until the
// wallust palette lands in phase 3.
Singleton {
    id: root

    // Glass
    readonly property color glass: Qt.rgba(0.08, 0.09, 0.12, 0.76)
    readonly property color glassHover: Qt.rgba(0.11, 0.12, 0.16, 0.82)
    readonly property color edge: Qt.rgba(1, 1, 1, 0.12)
    readonly property color edgeTop: Qt.rgba(1, 1, 1, 0.22)

    // Text
    readonly property color text: "#f2f3f7"
    readonly property color textDim: Qt.rgba(0.95, 0.96, 0.98, 0.62)
    readonly property color accent: "#8ab4ff"

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
