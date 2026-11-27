import QtQuick
import QtQuick.Shapes

// Ring gauge: segmented track, a glowing value arc, the number in the
// middle. The arc sweeps in from zero and eases between values.
Item {
    id: g

    property real value: 0               // 0..1
    property string text: ""
    property string unit: ""
    property string caption: ""
    property color accent: "#ff7b1c"
    property color track: "#22303a"
    property real draw: 1

    implicitWidth: 150
    implicitHeight: 150

    property real shown: value * draw
    Behavior on shown { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }

    readonly property real r: Math.min(width, height) / 2 - 8

    // Segmented track: 40 short ticks
    Repeater {
        model: 40
        Rectangle {
            required property int index
            x: g.width / 2 - 1
            y: g.height / 2 - g.r - 6
            width: 2; height: 5
            color: index / 40 < g.shown ? g.accent : g.track
            opacity: g.draw
            transform: Rotation { origin.x: 1; origin.y: g.r + 6; angle: -135 + index * 270 / 39 }
        }
    }

    Item {
        anchors.fill: parent
        layer.enabled: true
        layer.effect: Glow { color: g.accent; strength: 0.7 }
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: g.track; strokeWidth: 3; fillColor: "transparent"
                PathAngleArc { centerX: g.width / 2; centerY: g.height / 2; radiusX: g.r - 10; radiusY: g.r - 10; startAngle: 135; sweepAngle: 270 * g.draw }
            }
            ShapePath {
                strokeColor: g.accent; strokeWidth: 3; fillColor: "transparent"; capStyle: ShapePath.FlatCap
                PathAngleArc { centerX: g.width / 2; centerY: g.height / 2; radiusX: g.r - 10; radiusY: g.r - 10; startAngle: 135; sweepAngle: 270 * g.shown }
            }
        }
    }

    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 4
        opacity: g.draw
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            Text {
                id: num
                text: g.text
                color: "#f2f4f5"
                font { family: "Oswald"; pixelSize: g.r * 0.62; variableAxes: { "wght": 600 } }
            }
            Text {
                anchors.baseline: num.baseline
                text: g.unit
                color: g.accent
                font { family: "Oswald"; pixelSize: g.r * 0.26; variableAxes: { "wght": 500 } }
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: g.caption
            color: "#7f8a96"
            font { family: "JetBrains Mono"; pixelSize: 9; letterSpacing: 2 }
        }
    }
}
