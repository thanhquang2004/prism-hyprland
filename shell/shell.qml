import QtQuick
import Quickshell
import "bar"
import "power"

// Prism: one floating bar per screen. Each bar reads its own screen's
// geometry, so new or rotated monitors adapt without config changes.
ShellRoot {
    Variants {
        model: Quickshell.screens

        BarWindow {
            required property var modelData
            screen: modelData
        }
    }

    PowerMenu {}
}
