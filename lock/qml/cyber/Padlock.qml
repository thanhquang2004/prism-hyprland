import QtQuick
import QtQuick.Shapes

// Padlock drawn with rectangles so it can open (`open` 0..1): the shackle
// rises straight up, its right leg stays seated in the body, the left leg
// comes free and leaves a gap: the classic "unlocked" shape.
Item {
    id: l

    property real open: 0
    property color color: "#ff7b1c"
    property real stroke: width * 0.1

    implicitWidth: 80
    implicitHeight: 96

    readonly property real bodyTop: height * 0.46
    readonly property real lift: height * 0.2 * open

    // Shackle: one stroke, left leg -> arch -> right leg. The right end
    // stays in the body; the left end rises with the shackle.
    Shape {
        id: sh
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        readonly property real xl: l.width * 0.18 + l.stroke / 2
        readonly property real xr: l.width * 0.82 - l.stroke / 2
        readonly property real rad: (xr - xl) / 2
        readonly property real cy: l.height * 0.04 + l.stroke / 2 + rad - l.lift
        readonly property real seat: l.bodyTop + l.stroke
        ShapePath {
            strokeColor: l.color
            strokeWidth: l.stroke
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap
            joinStyle: ShapePath.RoundJoin
            startX: sh.xl; startY: sh.seat - l.lift
            PathLine { x: sh.xl; y: sh.cy }
            PathArc { x: sh.xr; y: sh.cy; radiusX: sh.rad; radiusY: sh.rad; direction: PathArc.Clockwise }
            PathLine { x: sh.xr; y: sh.seat }
        }
    }

    // Body
    Rectangle {
        y: l.bodyTop
        width: l.width
        height: l.height - l.bodyTop
        radius: l.width * 0.1
        color: Qt.alpha(l.color, 0.1 + 0.1 * l.open)
        border.width: l.stroke
        border.color: l.color

        // keyhole
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.28
            width: parent.width * 0.17; height: width; radius: width / 2
            color: l.color
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.38
            width: parent.width * 0.075; height: parent.height * 0.28
            radius: width / 2
            color: l.color
        }
    }
}
