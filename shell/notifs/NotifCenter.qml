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
            implicitWidth: portrait ? 360 : 400
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
                implicitHeight: body.y + body.implicitHeight + 12
                radius: 22
                color: Theme.glass
                border.width: 1
                border.color: Theme.edge
                focus: true
                Keys.onEscapePressed: Notifs.panelOpen = false

                // Header: title, do-not-disturb, clear all
                Item {
                    id: header
                    x: 16
                    y: 14
                    width: parent.width - 32
                    height: 28

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Notifications"
                        color: Theme.text
                        font { family: Theme.font; pixelSize: 15; weight: Font.Bold }
                    }

                    Row {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        spacing: 6

                        Rectangle {
                            height: 26
                            width: dndRow.implicitWidth + 18
                            radius: 13
                            color: Notifs.dnd ? Theme.chipActive : (dndHover.hovered ? Theme.chipHover : Theme.chip)
                            Row {
                                id: dndRow
                                anchors.centerIn: parent
                                spacing: 5
                                Text {
                                    text: Icons.bellOff
                                    color: Theme.text
                                    font { family: Theme.iconFont; pixelSize: 13 }
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
                            height: 26
                            width: clearText.implicitWidth + 18
                            radius: 13
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
                    x: 12
                    y: header.y + header.height + 12
                    width: parent.width - 24
                    height: parent.height - y - 12
                    implicitHeight: Notifs.count > 0 ? list.implicitHeight : empty.implicitHeight
                    contentHeight: list.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: list
                        width: body.width
                        spacing: 14
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
                            font { family: Theme.iconFont; pixelSize: 30 }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "No notifications"
                            color: Theme.textFaint
                            font { family: Theme.font; pixelSize: 13 }
                        }
                    }
                }
            }
        }
    }
}
