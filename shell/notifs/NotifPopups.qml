import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import ".."

// New-notification popups under the bell on the focused screen. Each
// popup hides after its timeout (5s default, critical ones stay) but the
// notification stays in the panel's history.
Scope {
    LazyLoader {
        active: Notifs.popups.length > 0 && !Notifs.panelOpen

        PanelWindow {
            id: win

            screen: Notifs.focusedScreen()
            anchors { top: true; left: true }
            margins { top: 6; left: Theme.barGap + 2 }
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: 0
            implicitWidth: 440
            implicitHeight: stack.implicitHeight
            color: "transparent"

            WlrLayershell.namespace: "prism-notifs"
            WlrLayershell.layer: WlrLayer.Overlay

            mask: Region { item: stack }

            Column {
                id: stack
                width: parent.width
                spacing: 10

                Repeater {
                    model: Notifs.popups

                    NotifCard {
                        id: card
                        required property var modelData
                        width: stack.width
                        notif: modelData
                        popup: true

                        // Slide in from the left edge
                        x: -20
                        opacity: 0
                        Component.onCompleted: { x = 0; opacity = 1; }
                        Behavior on x { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: Theme.animMed } }

                        HoverHandler { id: keep }

                        Timer {
                            // expireTimeout may arrive in seconds or ms; keep popups short either way
                            interval: {
                                const t = card.notif.expireTimeout;
                                return t > 0 ? Math.min(t < 1000 ? t * 1000 : t, 8000) : 5000;
                            }
                            running: !card.critical && !keep.hovered
                            onTriggered: Notifs.dropPopup(card.notif)
                        }

                        Connections {
                            target: card.notif
                            function onClosed() { Notifs.dropPopup(card.notif); }
                        }
                    }
                }
            }
        }
    }
}
