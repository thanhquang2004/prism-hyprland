import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import ".."

// Notification panel: drops down under the bell on the screen whose bell
// was clicked. Click outside or press Esc to close.
Scope {
    LazyLoader {
        active: Notifs.panelOpen

        PanelWindow {
            id: win

            screen: Notifs.panelScreen
            readonly property bool portrait: screen && screen.height > screen.width

            anchors { top: true; left: true }
            margins { top: 6; left: Theme.barGap + 2 }
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: 0                      // sit below the bars, reserve nothing
            implicitWidth: portrait ? 420 : 470
            implicitHeight: Math.min(panel.implicitHeight, (screen ? screen.height : 1080) * 0.75)
            color: "transparent"

            WlrLayershell.namespace: "prism-notifs"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            HyprlandFocusGrab {
                windows: [win]
                active: true
                onCleared: Notifs.panelOpen = false
            }

            Rectangle {
                id: panel
                anchors.fill: parent
                implicitHeight: body.y + body.implicitHeight + 14
                radius: 26
                color: Theme.glass
                border.width: 1
                border.color: Theme.edge
                focus: true
                Keys.onEscapePressed: Notifs.panelOpen = false

                // Header: title, do-not-disturb, clear all
                Item {
                    id: header
                    x: 20
                    y: 18
                    width: parent.width - 40
                    height: 32

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Notifications"
                        color: Theme.text
                        font { family: Theme.font; pixelSize: 18; weight: Font.Bold }
                    }

                    Row {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        spacing: 6

                        Rectangle {
                            height: 30
                            width: dndRow.implicitWidth + 22
                            radius: 15
                            color: Notifs.dnd ? Theme.chipActive : (dndHover.hovered ? Theme.chipHover : Theme.chip)
                            Row {
                                id: dndRow
                                anchors.centerIn: parent
                                spacing: 5
                                Text {
                                    text: Icons.bellOff
                                    color: Theme.text
                                    font { family: Theme.iconFont; pixelSize: 15 }
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: "Do not disturb"
                                    color: Theme.text
                                    font { family: Theme.font; pixelSize: 12; weight: Font.Medium }
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            HoverHandler { id: dndHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: Notifs.dnd = !Notifs.dnd }
                        }

                        Rectangle {
                            visible: Notifs.count > 0
                            height: 30
                            width: clearText.implicitWidth + 22
                            radius: 15
                            color: clearHover.hovered ? Theme.chipHover : Theme.chip
                            Text {
                                id: clearText
                                anchors.centerIn: parent
                                text: "Clear all"
                                color: Theme.text
                                font { family: Theme.font; pixelSize: 12; weight: Font.Medium }
                            }
                            HoverHandler { id: clearHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: Notifs.clearAll() }
                        }
                    }
                }

                Flickable {
                    id: body
                    x: 14
                    y: header.y + header.height + 14
                    width: parent.width - 28
                    height: parent.height - y - 14
                    implicitHeight: Notifs.count > 0 ? list.implicitHeight : empty.implicitHeight
                    contentHeight: list.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: list
                        width: body.width
                        spacing: 16
                        visible: Notifs.count > 0

                        Repeater {
                            model: Notifs.groups

                            NotifGroup {
                                required property var modelData
                                width: list.width
                                group: modelData
                            }
                        }
                    }

                    Column {
                        id: empty
                        visible: Notifs.count === 0
                        width: body.width
                        topPadding: 18
                        bottomPadding: 22
                        spacing: 8

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Icons.bellNone
                            color: Theme.textFaint
                            font { family: Theme.iconFont; pixelSize: 36 }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "No notifications"
                            color: Theme.textFaint
                            font { family: Theme.font; pixelSize: 15 }
                        }
                    }
                }
            }
        }
    }
}
