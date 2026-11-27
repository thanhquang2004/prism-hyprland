import QtQuick
import QtQuick.Shapes

// A frame with the top-left and bottom-right corners cut at 45°.
Shape {
    id: c

    property real cut: 14
    property color stroke: "#f3e600"
    property color fill: "transparent"
    property real strokeWidth: 1

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeColor: c.stroke
        strokeWidth: c.strokeWidth
        fillColor: c.fill
        joinStyle: ShapePath.MiterJoin
        startX: c.cut; startY: 0.5
        PathLine { x: c.width - 0.5; y: 0.5 }
        PathLine { x: c.width - 0.5; y: c.height - c.cut }
        PathLine { x: c.width - c.cut; y: c.height - 0.5 }
        PathLine { x: 0.5; y: c.height - 0.5 }
        PathLine { x: 0.5; y: c.cut }
        PathLine { x: c.cut; y: 0.5 }
    }
}
