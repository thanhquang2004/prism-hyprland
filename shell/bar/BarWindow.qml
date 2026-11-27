import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import ".."
import "../power"

// Floating glass bar for one screen. The layer surface spans the top
// strip; only the bar itself takes input (mask) and gets blurred
// (ignore_alpha rule), so the gaps around it stay see-through.
PanelWindow {
    id: win

    readonly property bool portrait: screen && screen.height > screen.width
    readonly property real aspect: screen ? screen.width / screen.height : 16 / 9
    // "portrait": narrow, essentials only; "laptop": 16:10; "wide": 16:9 and wider
    readonly property string formFactor: portrait ? "portrait" : (aspect < 1.7 ? "laptop" : "wide")
    readonly property var monitor: Hyprland.monitorFor(screen)

    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barGap + Theme.barHeight
    exclusiveZone: implicitHeight
    color: "transparent"

    WlrLayershell.namespace: "prism-bar"
    WlrLayershell.layer: WlrLayer.Top

    mask: Region { item: bar }

    Rectangle {
        id: bar
        anchors {
            fill: parent
            topMargin: Theme.barGap
            leftMargin: Theme.barGap + 2
            rightMargin: Theme.barGap + 2
        }
        radius: Theme.radius
        color: Theme.glass
        border.width: 1
        border.color: Theme.edge

        Workspaces {
            anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
            monitor: win.monitor
            compact: win.formFactor === "portrait"
        }

        Clock {
            anchors.centerIn: parent
            formFactor: win.formFactor
        }

        Row {
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            spacing: 14

            Tray {
                anchors.verticalCenter: parent.verticalCenter
                window: win
                visible: win.formFactor !== "portrait"
            }
            Status {
                anchors.verticalCenter: parent.verticalCenter
                compact: win.formFactor === "portrait"
            }
            NotifButton {
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.shutdown
                color: powerHover.hovered ? Theme.text : Theme.textDim
                font { family: Theme.iconFont; pixelSize: 15 }
                HoverHandler { id: powerHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: Power.toggle() }
            }
        }
    }
}
