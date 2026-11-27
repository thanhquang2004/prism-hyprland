import QtQuick
import QtQuick.Shapes

// The Prism mark: a white beam enters a glass triangle and leaves as a
// spectrum. `draw` (0..1) grows it in; the rays shimmer while idle.
Item {
    id: e

    property real draw: 1
    readonly property var spectrum: ["#ff5f6d", "#ffa552", "#ffe066", "#6fe3a1", "#5bb8ff", "#a78bfa"]

    implicitWidth: 168
    implicitHeight: 64

    readonly property real cx: width / 2
    readonly property real cy: height / 2 + 4
    readonly property real tri: height * 0.34   // half the triangle's side

    // Incoming beam
    Rectangle {
        x: 0
        y: e.cy - 2 - 0.5
        width: (e.cx - e.tri * 0.55) * Math.min(1, e.draw * 2)
        height: 1.5
        rotation: 6
        transformOrigin: Item.Right
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 1; color: "#eeffffff" }
        }
    }

    // Outgoing spectrum
    Repeater {
        model: e.spectrum
        Rectangle {
            required property string modelData
            required property int index
            readonly property real spread: (index - 2.5) * 5.5     // degrees
            x: e.cx + e.tri * 0.45
            y: e.cy + 2
            width: (e.width - x) * Math.max(0, Math.min(1, e.draw * 2 - 1))
            height: 1.6
            rotation: spread
            transformOrigin: Item.Left
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: modelData }
                GradientStop { position: 1; color: "transparent" }
            }
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                PauseAnimation { duration: index * 260 }
                NumberAnimation { to: 0.45; duration: 1400; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 1400; easing.type: Easing.InOutSine }
            }
        }
    }

    // Glass triangle
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        opacity: Math.min(1, e.draw * 3)
        ShapePath {
            strokeColor: "#d9ffffff"
            strokeWidth: 1.6
            fillColor: "#14ffffff"
            joinStyle: ShapePath.RoundJoin
            startX: e.cx; startY: e.cy - e.tri
            PathLine { x: e.cx + e.tri; y: e.cy + e.tri * 0.75 }
            PathLine { x: e.cx - e.tri; y: e.cy + e.tri * 0.75 }
            PathLine { x: e.cx; y: e.cy - e.tri }
        }
    }
}
