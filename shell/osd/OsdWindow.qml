import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// Volume / mic / brightness pill, centered under the bar on the focused screen.
Scope {
    LazyLoader {
        active: Osd.alive

        PanelWindow {
            id: win

            screen: Notifs.focusedScreen()
            anchors.top: true                    // no left/right anchor: centered
            margins.top: 6
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: 0                     // sit below the bars
            implicitWidth: 320
            implicitHeight: 64
            color: "transparent"

            WlrLayershell.namespace: "prism-osd"
            WlrLayershell.layer: WlrLayer.Overlay

            mask: Region {}                      // never takes input

            readonly property real level: Math.max(0, Math.min(1, Osd.value))
            readonly property string icon: {
                if (Osd.kind === "brightness") return Icons.brightness;
                if (Osd.kind === "mic") return Osd.muted ? Icons.micOff : Icons.mic;
                if (Osd.muted) return Icons.volMute;
                return Osd.value > 0.66 ? Icons.volHigh : Osd.value > 0.33 ? Icons.volMid : Icons.volLow;
            }
            readonly property string label: {
                if (Osd.kind === "mic") return Osd.muted ? "Mic off" : "Mic on";
                if (Osd.muted) return "Muted";
                return Math.round(Osd.value * 100) + "%";
            }

            Rectangle {
                id: pill
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                height: 52
                radius: 26
                color: Theme.glass
                border.width: 1
                border.color: Theme.edge

                opacity: Osd.shown ? 1 : 0
                y: Osd.shown ? 0 : -10
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                Text {
                    id: glyph
                    anchors { left: parent.left; leftMargin: 20; verticalCenter: parent.verticalCenter }
                    text: win.icon
                    color: Theme.text
                    font { family: Theme.iconFont; pixelSize: 20 }
                }

                // Progress track (hidden for mic on/off, which has no level)
                Rectangle {
                    id: track
                    visible: Osd.kind !== "mic"
                    anchors { left: glyph.right; leftMargin: 14; right: value.left; rightMargin: 14; verticalCenter: parent.verticalCenter }
                    height: 6
                    radius: 3
                    color: Theme.chip

                    Rectangle {
                        width: parent.width * win.level
                        height: parent.height
                        radius: parent.radius
                        color: Osd.muted ? Theme.textFaint : Theme.text
                        Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    }
                }

                Text {
                    id: value
                    anchors { right: parent.right; rightMargin: 20; verticalCenter: parent.verticalCenter }
                    width: Osd.kind === "mic" ? implicitWidth : 44
                    horizontalAlignment: Text.AlignRight
                    text: win.label
                    color: Theme.text
                    font { family: Theme.font; pixelSize: 14; styleName: "SemiBold"; features: { "tnum": 1 } }
                }

                // Mic on/off: center the label next to the glyph instead of a bar
                states: State {
                    when: Osd.kind === "mic"
                    PropertyChanges { target: pill; width: glyph.implicitWidth + value.implicitWidth + 54 }
                }
            }
        }
    }
}
