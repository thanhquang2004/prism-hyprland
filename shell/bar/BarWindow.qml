import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import ".."
import "../power"
import "../cc"

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
    // Slide away while this monitor shows a fullscreen window (videos, games)
    readonly property bool hidden: monitor?.activeWorkspace?.hasFullscreen ?? false

    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barGap + Theme.barHeight
    exclusiveZone: hidden ? 0 : implicitHeight
    color: "transparent"

    WlrLayershell.namespace: "prism-bar"
    WlrLayershell.layer: WlrLayer.Top

    mask: Region { item: win.hidden ? null : bar }

    Rectangle {
        id: bar
        x: Theme.barGap + 2
        width: parent.width - 2 * x
        height: Theme.barHeight
        y: win.hidden ? -height - 4 : Theme.barGap
        opacity: win.hidden ? 0 : 1
        Behavior on y { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: Theme.animMed } }
        radius: Theme.radius
        color: Theme.glass
        border.width: 1
        border.color: Theme.edge

        Row {
            anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
            spacing: 4

            NotifButton {
                anchors.verticalCenter: parent.verticalCenter
                screen: win.screen
            }
            Workspaces {
                anchors.verticalCenter: parent.verticalCenter
                monitor: win.monitor
                compact: win.formFactor === "portrait"
            }
        }

        Clock {
            anchors.centerIn: parent
            formFactor: win.formFactor
        }

        Row {
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            spacing: 14

            PrivacyIndicator {
                anchors.verticalCenter: parent.verticalCenter
            }
            Tray {
                anchors.verticalCenter: parent.verticalCenter
                window: win
                visible: win.formFactor !== "portrait"
            }
            // Status cluster opens the control center
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: status.implicitWidth + 16
                implicitHeight: Theme.chipHeight
                radius: height / 2
                readonly property bool active: Cc.open && Cc.screen === win.screen
                color: active ? Theme.chipActive : (statusHover.hovered ? Theme.chipHover : "transparent")
                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Status {
                    id: status
                    anchors.centerIn: parent
                    compact: win.formFactor === "portrait"
                }
                HoverHandler { id: statusHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: Cc.toggle(win.screen) }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Theme.dark ? Icons.moon : Icons.sun
                color: modeHover.hovered ? Theme.text : Theme.textDim
                font { family: Theme.iconFont; pixelSize: 15 }
                HoverHandler { id: modeHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: Theme.toggleDark() }
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
