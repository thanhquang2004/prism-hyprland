import QtQuick
import Quickshell
import "bar"
import "cc"
import "notifs"
import "osd"
import "power"

// Prism: one floating bar per screen. Each bar reads its own screen's
// geometry, so new or rotated monitors adapt without config changes.
ShellRoot {
    // Create the Hypr singleton up front so its IPC (keybinds) is always there
    Component.onCompleted: Hypr.refresh()

    Variants {
        model: Quickshell.screens

        BarWindow {
            required property var modelData
            screen: modelData
        }
    }

    NotifCenter {}
    NotifPopups {}
    OsdWindow {}
    ControlCenter {}
    PowerMenu {}
}
