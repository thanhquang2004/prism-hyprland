import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import ".."

// System tray icons, flattened to the ink color so they match the
// monochrome set. Left click activates, right click opens the app's menu.
Row {
    id: root

    property var window: null

    spacing: 10

    Repeater {
        model: SystemTray.items

        Item {
            id: slot
            required property var modelData

            width: 16
            height: 16
            opacity: hover.hovered ? 1 : 0.8

            IconImage {
                id: icon
                anchors.fill: parent
                source: slot.modelData.icon
                visible: false
            }

            // Silhouette: push every opaque pixel to white, then tint.
            MultiEffect {
                anchors.fill: parent
                source: icon
                brightness: 1.0
                colorization: 1.0
                colorizationColor: Theme.text
            }

            HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onTapped: (point, button) => {
                    if (button === Qt.RightButton || slot.modelData.onlyMenu) {
                        if (slot.modelData.hasMenu && root.window) {
                            const p = slot.mapToItem(null, 0, slot.height + 10);
                            slot.modelData.display(root.window, p.x, p.y);
                        }
                    } else {
                        slot.modelData.activate();
                    }
                }
            }
        }
    }
}
