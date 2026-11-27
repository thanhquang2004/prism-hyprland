import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import ".."

// System tray icons. Left click activates, right click opens the app's menu.
Row {
    id: root

    property var window: null

    spacing: 8

    Repeater {
        model: SystemTray.items

        IconImage {
            id: icon
            required property var modelData

            implicitSize: 16
            source: modelData.icon
            opacity: hover.hovered ? 1 : 0.85

            HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onTapped: (point, button) => {
                    if (button === Qt.RightButton || icon.modelData.onlyMenu) {
                        if (icon.modelData.hasMenu && root.window) {
                            const p = icon.mapToItem(null, 0, icon.height + 10);
                            icon.modelData.display(root.window, p.x, p.y);
                        }
                    } else {
                        icon.modelData.activate();
                    }
                }
            }
        }
    }
}
