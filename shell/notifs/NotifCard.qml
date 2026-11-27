import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import ".."

// One notification: optional image, summary, body, time, action buttons.
// Click runs the default action (or opens the app); hover shows a close button.
Rectangle {
    id: root

    required property var notif
    property bool popup: false           // popups carry their own glass and app name
    property bool showApp: popup

    readonly property bool critical: notif && notif.urgency === NotificationUrgency.Critical
    readonly property var buttons: notif ? notif.actions.filter(a => a.identifier !== "default" && a.text) : []

    implicitHeight: body.implicitHeight + 24
    radius: 16
    color: popup ? Theme.glass : (hover.hovered ? Theme.chipHover : Theme.chip)
    border.width: popup || critical ? 1 : 0
    border.color: critical ? Theme.warn : Theme.edge
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    HoverHandler { id: hover }
    TapHandler { onTapped: Notifs.activate(root.notif) }
    SystemClock { id: clock; precision: SystemClock.Minutes }

    function ago(t) {
        const s = Math.max(0, (clock.date.getTime() - t) / 1000);
        if (s < 60) return "now";
        if (s < 3600) return Math.floor(s / 60) + "m";
        if (s < 86400) return Math.floor(s / 3600) + "h";
        return Math.floor(s / 86400) + "d";
    }

    Row {
        id: body
        x: 12
        y: 12
        width: parent.width - 24
        spacing: 12

        ClippingRectangle {
            id: image
            visible: img.status === Image.Ready
            width: visible ? 40 : 0
            height: 40
            radius: 12
            color: "transparent"

            Image {
                id: img
                anchors.fill: parent
                source: root.notif && root.notif.image ? root.notif.image : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(80, 80)
            }
        }

        Column {
            width: parent.width - (image.visible ? image.width + parent.spacing : 0)
            spacing: 3

            Row {
                width: parent.width
                spacing: 8

                Text {
                    visible: root.showApp
                    text: Icons.app(root.notif ? (root.notif.desktopEntry || root.notif.appName) : "")
                    color: Theme.textDim
                    font { family: Theme.iconFont; pixelSize: 13 }
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    width: parent.width - time.width - closeBtn.width - 16 - (root.showApp ? 21 : 0)
                    text: root.notif ? root.notif.summary : ""
                    elide: Text.ElideRight
                    color: Theme.text
                    font { family: Theme.font; pixelSize: 13; weight: Font.DemiBold }
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    id: time
                    text: root.notif ? root.ago(Notifs.timeOf(root.notif)) : ""
                    color: Theme.textFaint
                    font { family: Theme.font; pixelSize: 11 }
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    id: closeBtn
                    text: Icons.close
                    opacity: hover.hovered ? 1 : 0
                    color: closeHover.hovered ? Theme.text : Theme.textDim
                    font { family: Theme.iconFont; pixelSize: 13 }
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                    HoverHandler { id: closeHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: Notifs.dismiss(root.notif) }
                }
            }

            Text {
                visible: text !== ""
                width: parent.width
                text: root.notif ? root.notif.body : ""
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: root.popup ? 2 : 4
                elide: Text.ElideRight
                color: Theme.textDim
                font { family: Theme.font; pixelSize: 12 }
                lineHeight: 1.15
            }

            Row {
                visible: root.buttons.length > 0
                topPadding: 6
                spacing: 6

                Repeater {
                    model: root.buttons

                    Rectangle {
                        id: btn
                        required property var modelData
                        height: 26
                        width: label.implicitWidth + 22
                        radius: 13
                        color: btnHover.hovered ? Theme.chipActive : Theme.chipHover

                        Text {
                            id: label
                            anchors.centerIn: parent
                            text: btn.modelData.text
                            color: Theme.text
                            font { family: Theme.font; pixelSize: 12; weight: Font.Medium }
                        }
                        HoverHandler { id: btnHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                btn.modelData.invoke();
                                Notifs.dismiss(root.notif);
                            }
                        }
                    }
                }
            }
        }
    }
}
