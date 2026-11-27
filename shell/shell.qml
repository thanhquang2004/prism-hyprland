import QtQuick
import Quickshell
import "island"

// Prism: one island per screen. Each island reads its own screen's
// geometry, so new or rotated monitors adapt without config changes.
ShellRoot {
    Variants {
        model: Quickshell.screens

        IslandWindow {
            required property var modelData
            screen: modelData
        }
    }
}
