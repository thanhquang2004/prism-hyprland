import QtQuick
import Quickshell
import Quickshell.Hyprland
import ".."

// Workspaces on this bar's monitor: number plus icons of the apps inside.
Row {
    id: root

    property var monitor: null
    property bool compact: false          // portrait screens: fewer icons
    readonly property int maxIcons: compact ? 1 : 3

    spacing: 4

    readonly property var workspaces: Hyprland.workspaces.values
        .filter(ws => ws.id > 0 && ws.monitor && root.monitor && ws.monitor.name === root.monitor.name)
        .sort((a, b) => a.id - b.id)

    function focusWorkspace(id) {
        // 0.57+ speaks Lua over IPC; 0.56 still takes the legacy dispatcher.
        if (Hyprland.usingLua)
            Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
        else
            Hyprland.dispatch(`workspace ${id}`);
    }

    Repeater {
        model: root.workspaces

        Rectangle {
            id: chip
            required property var modelData
            readonly property bool current: modelData.active
            readonly property var apps: {
                const seen = [];
                for (const t of modelData.toplevels.values) {
                    const id = t.wayland?.appId ?? t.lastIpcObject?.class ?? "";
                    if (id && !seen.includes(id)) seen.push(id);
                }
                return seen;
            }

            height: Theme.chipHeight
            width: content.implicitWidth + 18
            radius: height / 2
            color: current ? Theme.chipActive : (hover.hovered ? Theme.chipHover : Theme.chip)
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
            Behavior on width { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }

            HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: root.focusWorkspace(chip.modelData.id) }

            Row {
                id: content
                anchors.centerIn: parent
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: chip.modelData.id
                    color: chip.current ? Theme.text : Theme.textDim
                    font { family: Theme.font; pixelSize: 13; weight: chip.current ? Font.Bold : Font.Medium; features: { "tnum": 1 } }
                }

                Repeater {
                    model: chip.apps.slice(0, root.maxIcons)

                    Text {
                        required property string modelData
                        anchors.verticalCenter: parent.verticalCenter
                        text: Icons.app(modelData)
                        color: chip.current ? Theme.text : Theme.textDim
                        font { family: Theme.iconFont; pixelSize: 15 }
                    }
                }

                Text {
                    visible: chip.apps.length > root.maxIcons
                    anchors.verticalCenter: parent.verticalCenter
                    text: "+" + (chip.apps.length - root.maxIcons)
                    color: Theme.textFaint
                    font { family: Theme.font; pixelSize: 11 }
                }
            }
        }
    }
}
