import QtQuick

// One clock digit that rolls like an odometer when it changes.
Item {
    id: d

    property int value: 0
    property real size: 100
    property string style: "Regular"     // Inter only honours styleName here, not weight
    property color color: "white"
    property string family: "Inter"

    clip: true
    implicitWidth: metrics.advanceWidth
    implicitHeight: metrics.height

    TextMetrics {
        id: metrics
        text: "0"
        font { family: d.family; pixelSize: d.size; styleName: d.style; features: { "tnum": 1 } }
    }

    component Glyph: Text {
        width: d.width
        horizontalAlignment: Text.AlignHCenter
        color: d.color
        font { family: d.family; pixelSize: d.size; styleName: d.style; features: { "tnum": 1 } }
    }

    Glyph { id: cur; text: d.value }
    Glyph { id: old; opacity: 0 }

    onValueChanged: {
        roll.stop();
        old.text = cur.text;
        cur.text = value;
        roll.start();
    }

    ParallelAnimation {
        id: roll
        NumberAnimation { target: old; property: "y"; from: 0; to: -d.height * 0.55; duration: 460; easing.type: Easing.OutCubic }
        NumberAnimation { target: old; property: "opacity"; from: 1; to: 0; duration: 300 }
        NumberAnimation { target: cur; property: "y"; from: d.height * 0.55; to: 0; duration: 520; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
        NumberAnimation { target: cur; property: "opacity"; from: 0; to: 1; duration: 360 }
    }
}
