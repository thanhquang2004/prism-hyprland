import QtQuick

// HUD panel: corner brackets that slide in, a title tab, a dim inner fill.
// Children go into the content area.
Item {
    id: p

    property string title: ""
    property string tag: ""              // small right-hand label in the title row
    property color accent: "#2ee6ff"
    property color dim: "#7f8a96"
    property real draw: 1                // 0..1 entrance
    property bool go: true
    property int delay: 0
    default property alias content: body.data

    readonly property string display: "Oswald"
    readonly property string mono: "JetBrains Mono"

    implicitWidth: 300
    implicitHeight: 160

    // Title row
    Row {
        id: head
        spacing: 8
        opacity: p.draw
        Rectangle { width: 4; height: 14; color: p.accent; anchors.verticalCenter: parent.verticalCenter }
        ScrambleText {
            go: p.go; delay: p.delay
            target: p.title
            color: p.accent
            font { family: p.display; pixelSize: 15; variableAxes: { "wght": 600 }; letterSpacing: 2 }
        }
    }
    Text {
        anchors { right: parent.right; verticalCenter: head.verticalCenter }
        opacity: p.draw
        text: p.tag
        color: p.dim
        font { family: p.mono; pixelSize: 10; letterSpacing: 2 }
    }

    // Frame
    Item {
        id: frame
        y: head.height + 8
        width: parent.width
        height: parent.height - y
        Rectangle { anchors.fill: parent; color: Qt.alpha(p.accent, 0.035); opacity: p.draw }
        Rectangle { width: parent.width; height: 1; color: Qt.alpha(p.accent, 0.22); opacity: p.draw }
        Rectangle { y: parent.height - 1; width: parent.width; height: 1; color: Qt.alpha(p.accent, 0.22); opacity: p.draw }
        Repeater {
            model: 4
            Item {
                required property int index
                readonly property bool isRight: index % 2 === 1
                readonly property bool isBottom: index > 1
                readonly property real fly: (1 - p.draw) * 30
                width: 14; height: 14
                x: isRight ? frame.width - width + fly : -fly
                y: isBottom ? frame.height - height + fly : -fly
                opacity: p.draw
                Rectangle { width: parent.width; height: 2; color: p.accent; y: parent.isBottom ? parent.height - 2 : 0 }
                Rectangle { width: 2; height: parent.height; color: p.accent; x: parent.isRight ? parent.width - 2 : 0 }
            }
        }
        Item {
            id: body
            anchors.fill: parent
            anchors.margins: 14
            opacity: p.draw
        }
    }
}
