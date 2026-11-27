import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import ".."

// Fullscreen power menu on the focused screen. Keyboard: arrows to move,
// Enter to choose, L/E/S/R/P shortcuts, Esc to cancel or close.
Scope {
    id: root

    IpcHandler {
        target: "power"
        function toggle(): void { Power.toggle(); }
        function close(): void { Power.close(); }
        function choose(action: string): void { Power.open = true; Power.choose(action); }
        function state(): string { return JSON.stringify({ open: Power.open, pending: Power.pending, remaining: Power.remaining, dryRun: Power.dryRun }); }
    }

    LazyLoader {
        active: Power.open

        PanelWindow {
            id: win

            screen: Quickshell.screens.find(s => Hyprland.monitorFor(s)?.focused) ?? Quickshell.screens[0]
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            WlrLayershell.namespace: "prism-power"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            property int selected: 0
            readonly property bool portrait: screen && screen.height > screen.width
            readonly property var pendingAction: Power.actions.find(a => a.id === Power.pending) ?? null

            Rectangle {
                anchors.fill: parent
                color: Theme.scrim

                // Click on empty space closes (or cancels a countdown).
                TapHandler { onTapped: Power.pending ? Power.cancel() : Power.close() }
            }

            Item {
                anchors.fill: parent
                focus: true

                Keys.onPressed: event => {
                    const n = Power.actions.length;
                    if (event.key === Qt.Key_Escape) {
                        Power.pending ? Power.cancel() : Power.close();
                    } else if (Power.pending) {
                        return;                       // only Esc/Cancel while counting down
                    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                        win.selected = (win.selected + n - 1) % n;
                    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                        win.selected = (win.selected + 1) % n;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        Power.choose(Power.actions[win.selected].id);
                    } else {
                        const a = Power.actions.find(x => x.key === event.text.toUpperCase());
                        if (a) Power.choose(a.id);
                    }
                    event.accepted = true;
                }
            }

            // Action grid (hidden while a countdown runs)
            Grid {
                anchors.centerIn: parent
                visible: !Power.pending
                columns: win.portrait ? 1 : Power.actions.length
                spacing: win.portrait ? 14 : 20

                Repeater {
                    model: Power.actions

                    Rectangle {
                        id: btn
                        required property var modelData
                        required property int index
                        readonly property bool active: win.selected === index

                        width: win.portrait ? 320 : 132
                        height: win.portrait ? 76 : 132
                        radius: 28
                        color: active ? Theme.chipActive : (hover.hovered ? Theme.chipHover : Theme.glass)
                        border.width: 1
                        border.color: Theme.edge
                        scale: active ? 1.04 : 1
                        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor; onHoveredChanged: if (hovered) win.selected = btn.index }
                        TapHandler { onTapped: Power.choose(btn.modelData.id) }

                        Grid {
                            anchors.centerIn: parent
                            columns: win.portrait ? 3 : 1
                            rowSpacing: 10
                            columnSpacing: 16
                            horizontalItemAlignment: Grid.AlignHCenter
                            verticalItemAlignment: Grid.AlignVCenter

                            Text {
                                text: Icons[btn.modelData.id]
                                color: Theme.text
                                font { family: Theme.iconFont; pixelSize: 38 }
                            }
                            Text {
                                text: btn.modelData.label
                                color: Theme.text
                                font { family: Theme.font; pixelSize: 15; styleName: "SemiBold" }
                            }
                            Text {
                                text: btn.modelData.key
                                color: Theme.textFaint
                                font { family: Theme.font; pixelSize: 12; styleName: "Medium" }
                            }
                        }
                    }
                }
            }

            // Countdown
            Column {
                anchors.centerIn: parent
                visible: Power.pending !== ""
                spacing: 22

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: win.pendingAction ? Icons[win.pendingAction.id] : ""
                    color: Theme.text
                    font { family: Theme.iconFont; pixelSize: 56 }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: win.pendingAction ? `${win.pendingAction.label} in ${Power.remaining}…` : ""
                    color: Theme.text
                    font { family: Theme.font; pixelSize: 30; styleName: "SemiBold"; features: { "tnum": 1 } }
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 160; height: 44; radius: 22
                    color: cancelHover.hovered ? Theme.chipActive : Theme.glass
                    border.width: 1
                    border.color: Theme.edge
                    HoverHandler { id: cancelHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: Power.cancel() }
                    Text {
                        anchors.centerIn: parent
                        text: "Cancel  ·  Esc"
                        color: Theme.text
                        font { family: Theme.font; pixelSize: 15; styleName: "SemiBold" }
                    }
                }
            }
        }
    }
}
