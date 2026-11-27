import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// Transparent layer surface spanning the top of one screen. Only the
// island itself takes input (mask) and gets blurred (ignore_alpha rule).
PanelWindow {
    id: win

    // Screen classes drive island sizing: portrait screens get a compact island.
    readonly property bool portrait: screen && screen.height > screen.width
    readonly property real aspect: screen ? screen.width / screen.height : 16 / 9
    readonly property string formFactor: portrait ? "portrait" : (aspect < 1.7 ? "laptop" : "wide")

    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.islandHeight + Theme.islandTopMargin + 4
    exclusiveZone: Theme.islandHeight + Theme.islandTopMargin
    color: "transparent"

    WlrLayershell.namespace: "prism-island"
    WlrLayershell.layer: WlrLayer.Top

    mask: Region { item: island }

    Island {
        id: island
        formFactor: win.formFactor
        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.islandTopMargin
    }
}
