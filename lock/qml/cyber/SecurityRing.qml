import QtQuick
import QtQuick.Shapes

// "Security lock" core: rotating outer arcs, a tick ring, twelve tumblers
// that light up one per typed character, and a padlock in the middle.
Item {
    id: r

    property real draw: 1                // entrance 0..1
    property real spin: 0                // extra degrees (unlock whip)
    property bool busy: false            // PAM check: arcs race, cyan
    property int count: 0                // typed characters
    property real open: 0                // padlock shackle 0..1
    property color main: "#ff7b1c"
    property color second: "#2ee6ff"
    property color track: "#1e2a33"

    readonly property real cx: width / 2
    readonly property real cy: height / 2
    readonly property real rr: Math.min(width, height) / 2 - 4
    readonly property color arcColor: busy ? second : main

    // --- tick ring (cyan, slow)
    Item {
        anchors.fill: parent
        opacity: r.draw * 0.9
        QtObject { id: tickSpin; property real a: 0 }
        FrameAnimation { running: true; onTriggered: tickSpin.a += frameTime * 4 }
        rotation: tickSpin.a + r.spin * 0.4
        Repeater {
            model: 72
            Rectangle {
                required property int index
                x: r.cx - width / 2
                y: r.cy - r.rr
                width: index % 6 === 0 ? 2 : 1
                height: index % 6 === 0 ? 12 : 6
                color: index % 6 === 0 ? r.second : Qt.alpha(r.second, 0.35)
                transform: Rotation { origin.x: width / 2; origin.y: r.rr; angle: index * 5 }
            }
        }
    }

    // --- outer arcs (main colour, counter-rotating, race while busy)
    Item {
        anchors.fill: parent
        layer.enabled: true
        layer.effect: Glow { color: r.arcColor; strength: 0.8 }
        QtObject {
            id: arcSpin
            property real a: 0
            property real speed: r.busy ? -320 : -12
            Behavior on speed { NumberAnimation { duration: 350 } }
        }
        FrameAnimation { running: true; onTriggered: arcSpin.a += frameTime * arcSpin.speed }
        rotation: arcSpin.a - r.spin

        Shape {
            id: arcs
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            readonly property real rad: r.rr - 22
            component Arc: ShapePath {
                property real start
                property real sweep
                property real w: 6
                strokeColor: r.arcColor; strokeWidth: w; fillColor: "transparent"; capStyle: ShapePath.FlatCap
                PathAngleArc { centerX: r.cx; centerY: r.cy; radiusX: arcs.rad; radiusY: arcs.rad; startAngle: start; sweepAngle: sweep * r.draw }
            }
            Arc { start: -80; sweep: 70 }
            Arc { start: 0; sweep: 14; w: 3 }
            Arc { start: 30; sweep: 95 }
            Arc { start: 140; sweep: 22; w: 3 }
            Arc { start: 175; sweep: 80 }
            Arc { start: 268; sweep: 6; w: 3 }
        }
    }

    // --- thin circles
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        opacity: r.draw
        ShapePath {
            strokeColor: Qt.alpha(r.second, 0.5); strokeWidth: 1; fillColor: "transparent"
            PathAngleArc { centerX: r.cx; centerY: r.cy; radiusX: r.rr - 36; radiusY: r.rr - 36; startAngle: 0; sweepAngle: 360 }
        }
        ShapePath {
            strokeColor: Qt.alpha(r.second, 0.25); strokeWidth: 1; fillColor: "transparent"
            strokeStyle: ShapePath.DashLine; dashPattern: [2, 4]
            PathAngleArc { centerX: r.cx; centerY: r.cy; radiusX: r.rr * 0.42; radiusY: r.rr * 0.42; startAngle: 0; sweepAngle: 360 }
        }
    }

    // --- tumblers: 12 segments, one per typed character
    Item {
        anchors.fill: parent
        layer.enabled: true
        layer.effect: Glow { color: r.open > 0 ? r.main : r.second; strength: 0.7 }
        Shape {
            id: tumblers
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            readonly property real rad: r.rr - 52
            component Tumbler: ShapePath {
                property int i
                readonly property bool lit: r.open > 0 || i < r.count
                strokeColor: r.open > 0 ? r.main : (lit ? r.second : r.track)
                Behavior on strokeColor { ColorAnimation { duration: 120 } }
                strokeWidth: 8; fillColor: "transparent"; capStyle: ShapePath.FlatCap
                PathAngleArc { centerX: r.cx; centerY: r.cy; radiusX: tumblers.rad; radiusY: tumblers.rad; startAngle: -90 + i * 30 + 3; sweepAngle: 24 * r.draw }
            }
            Tumbler { i: 0 } Tumbler { i: 1 } Tumbler { i: 2 } Tumbler { i: 3 }
            Tumbler { i: 4 } Tumbler { i: 5 } Tumbler { i: 6 } Tumbler { i: 7 }
            Tumbler { i: 8 } Tumbler { i: 9 } Tumbler { i: 10 } Tumbler { i: 11 }
        }
    }

    // --- padlock
    Item {
        anchors.centerIn: parent
        width: r.rr * 0.42
        height: width * 1.2
        opacity: r.draw
        scale: 0.6 + 0.4 * r.draw
        layer.enabled: true
        layer.effect: Glow { color: r.busy ? r.second : r.main; strength: lockPulse.v }
        QtObject { id: lockPulse; property real v: 0.7 }
        SequentialAnimation {
            running: true; loops: Animation.Infinite
            NumberAnimation { target: lockPulse; property: "v"; to: 1; duration: 1300; easing.type: Easing.InOutSine }
            NumberAnimation { target: lockPulse; property: "v"; to: 0.5; duration: 1300; easing.type: Easing.InOutSine }
        }
        Padlock {
            anchors.fill: parent
            open: r.open
            color: r.busy ? r.second : r.main
        }
    }
}
