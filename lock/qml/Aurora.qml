import QtQuick
import QtQuick.Shapes

// Slow, soft light fields drifting over the backdrop, tinted from the
// accent and its spectral neighbours.
Item {
    id: a

    property color accent: "#9ab4ff"

    component Blob: Item {
        id: b
        property color tint
        property real size: 700
        property real fromX
        property real fromY
        property real toX
        property real toY
        property int period: 20000
        width: size
        height: size
        x: fromX
        y: fromY

        Shape {
            anchors.fill: parent
            ShapePath {
                strokeColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: b.size / 2; centerY: b.size / 2; centerRadius: b.size / 2
                    focalX: b.size / 2; focalY: b.size / 2
                    GradientStop { position: 0; color: Qt.alpha(b.tint, 0.32) }
                    GradientStop { position: 0.55; color: Qt.alpha(b.tint, 0.10) }
                    GradientStop { position: 1; color: Qt.alpha(b.tint, 0) }
                }
                startX: 0; startY: 0
                PathLine { x: b.size; y: 0 }
                PathLine { x: b.size; y: b.size }
                PathLine { x: 0; y: b.size }
                PathLine { x: 0; y: 0 }
            }
        }

        SequentialAnimation on x {
            loops: Animation.Infinite
            NumberAnimation { to: b.toX; duration: b.period; easing.type: Easing.InOutSine }
            NumberAnimation { to: b.fromX; duration: b.period; easing.type: Easing.InOutSine }
        }
        SequentialAnimation on y {
            loops: Animation.Infinite
            NumberAnimation { to: b.toY; duration: b.period * 1.3; easing.type: Easing.InOutSine }
            NumberAnimation { to: b.fromY; duration: b.period * 1.3; easing.type: Easing.InOutSine }
        }
    }

    readonly property real s: Math.max(width, height)

    Blob {
        tint: a.accent
        size: a.s * 0.75
        fromX: -size * 0.3; fromY: -size * 0.25
        toX: a.width * 0.25; toY: a.height * 0.1
        period: 21000
    }
    Blob {
        tint: Qt.hsla((a.accent.hslHue + 0.14) % 1, 0.7, 0.6, 1)
        size: a.s * 0.65
        fromX: a.width - size * 0.6; fromY: a.height - size * 0.55
        toX: a.width * 0.35; toY: a.height * 0.3
        period: 26000
    }
    Blob {
        tint: Qt.hsla((a.accent.hslHue + 0.86) % 1, 0.7, 0.6, 1)
        size: a.s * 0.55
        fromX: a.width * 0.55; fromY: -size * 0.4
        toX: a.width * 0.05; toY: a.height * 0.5
        period: 31000
    }
}
