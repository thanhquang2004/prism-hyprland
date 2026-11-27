import QtQuick
import Quickshell
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import ".."

// Right side of the bar: network, volume and battery.
Row {
    id: root

    property bool compact: false

    spacing: 12

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var battery: UPower.displayDevice
    readonly property var netDevice: Networking.devices.values.find(d => d.connected) ?? null
    readonly property var wifi: netDevice ? (netDevice.networks?.values.find(n => n.connected) ?? null) : null

    PwObjectTracker { objects: [root.sink] }

    component Item_: Row {
        property string icon
        property string label
        property color tint: Theme.text
        spacing: 5
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: parent.icon
            color: parent.tint
            font { family: Theme.iconFont; pixelSize: 15 }
        }
        Text {
            visible: parent.label !== "" && !root.compact
            anchors.verticalCenter: parent.verticalCenter
            text: parent.label
            color: Theme.textDim
            font { family: Theme.font; pixelSize: 12; weight: Font.Medium; features: { "tnum": 1 } }
        }
    }

    Item_ {
        anchors.verticalCenter: parent.verticalCenter
        icon: {
            if (!root.netDevice) return "󰤮";
            if (root.netDevice.type === DeviceType.Wifi) {
                let s = root.wifi ? root.wifi.signalStrength : 0;
                if (s > 1) s /= 100;          // reported as 0..100
                return s > 0.75 ? "󰤨" : s > 0.5 ? "󰤥" : s > 0.25 ? "󰤢" : "󰤟";
            }
            return "󰈀";
        }
        label: ""
        tint: root.netDevice ? Theme.text : Theme.textFaint
    }

    Item_ {
        anchors.verticalCenter: parent.verticalCenter
        readonly property real vol: root.sink?.audio?.volume ?? 0
        readonly property bool muted: root.sink?.audio?.muted ?? false
        icon: muted ? "󰝟" : vol > 0.66 ? "󰕾" : vol > 0.33 ? "󰖀" : "󰕿"
        label: muted ? "" : Math.round(vol * 100) + "%"
        tint: muted ? Theme.textFaint : Theme.text
    }

    Item_ {
        visible: root.battery && root.battery.isLaptopBattery
        anchors.verticalCenter: parent.verticalCenter
        readonly property real pct: root.battery ? root.battery.percentage : 0
        readonly property bool charging: root.battery && root.battery.state === UPowerDeviceState.Charging
        icon: charging ? "󰂄" : pct > 0.9 ? "󰁹" : pct > 0.7 ? "󰂀" : pct > 0.5 ? "󰁾" : pct > 0.3 ? "󰁼" : pct > 0.15 ? "󰁺" : "󰂎"
        label: Math.round(pct * 100) + "%"
        tint: (!charging && pct <= 0.15) ? Theme.warn : Theme.text
    }
}
