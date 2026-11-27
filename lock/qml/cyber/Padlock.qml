import QtQuick

// Padlock drawn with rectangles so the shackle can lift (`open` 0..1).
Item {
    id: l

    property real open: 0
    property color color: "#ff7b1c"
    property real stroke: width * 0.09

    implicitWidth: 80
    implicitHeight: 96

    // Shackle: the top half of a rounded outline, lifted and tilted when open
    Item {
        id: shackle
        x: l.width * 0.2
        width: l.width * 0.6
        height: l.height * 0.42
        y: l.height * 0.08 - l.open * l.height * 0.3
        clip: true
        transform: Rotation { origin.x: shackle.width * 0.92; origin.y: shackle.height; angle: -28 * l.open }
        Rectangle {
            width: parent.width
            height: parent.height * 2
            radius: width / 2
            color: "transparent"
            border.width: l.stroke
            border.color: l.color
        }
    }
    // Shackle legs reaching into the body
    Rectangle { x: shackle.x; y: shackle.y + shackle.height - 1; width: l.stroke; height: l.height * 0.1 + l.open * l.height * 0.3; color: l.color; opacity: 1 - l.open }
    Rectangle { x: shackle.x + shackle.width - l.stroke; y: shackle.y + shackle.height - 1; width: l.stroke; height: l.height * 0.1 + l.open * l.height * 0.3; color: l.color }

    // Body
    Rectangle {
        id: body
        y: l.height * 0.48
        width: l.width
        height: l.height * 0.52
        radius: l.width * 0.08
        color: "transparent"
        border.width: l.stroke
        border.color: l.color
        // keyhole
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.26
            width: parent.width * 0.16; height: width; radius: width / 2
            color: l.color
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.36
            width: parent.width * 0.07; height: parent.height * 0.3
            color: l.color
        }
    }
}
