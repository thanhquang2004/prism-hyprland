import QtQuick
import QtQuick.Effects

// Neon bloom for a layer: a soft halo in `color` around whatever it wraps.
MultiEffect {
    property color color: "#ff7b1c"
    property real strength: 0.85

    shadowEnabled: true
    shadowColor: color
    shadowBlur: 0.75
    shadowOpacity: strength
    shadowHorizontalOffset: 0
    shadowVerticalOffset: 0
    autoPaddingEnabled: true
}
