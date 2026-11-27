import QtQuick
import Quickshell
import Quickshell.Bluetooth
import ".."

// Bluetooth: paired devices (connect/disconnect) and, while scanning, new ones to pair.
Column {
    id: root

    spacing: 6

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var all: adapter ? adapter.devices.values : []
    readonly property var paired: all.filter(d => d.paired || d.connected).sort((a, b) => (b.connected - a.connected))
    readonly property var found: all.filter(d => !d.paired && !d.connected && d.name && d.name !== d.address)

    Component.onDestruction: if (adapter && adapter.discovering) adapter.discovering = false

    function choose(d) {
        if (d.connected) d.disconnect();
        else if (d.paired) d.connect();
        else { d.trusted = true; d.pair(); }
    }

    function iconFor(d) {
        const i = (d.icon || "").toLowerCase();
        if (i.includes("headset") || i.includes("headphone") || i.includes("audio")) return Icons.headphones;
        return d.connected ? Icons.bluetoothOn : Icons.bluetooth;
    }

    function subtitleFor(d) {
        if (d.state === BluetoothDeviceState.Connecting) return "Connecting…";
        if (d.pairing) return "Pairing…";
        if (d.connected) return d.batteryAvailable ? "Connected · " + Math.round(d.battery * 100) + "%" : "Connected";
        return d.paired ? "Paired" : "Tap to pair";
    }

    PageHeader {
        width: parent.width
        title: "Bluetooth"
        hasSwitch: true
        switchOn: root.adapter ? root.adapter.enabled : false
        onSwitched: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
    }

    Text {
        visible: !root.adapter || !root.adapter.enabled
        width: parent.width
        topPadding: 12
        bottomPadding: 12
        horizontalAlignment: Text.AlignHCenter
        text: root.adapter ? "Bluetooth is off" : "No Bluetooth adapter"
        color: Theme.textFaint
        font { family: Theme.font; pixelSize: 13 }
    }

    Repeater {
        model: root.adapter && root.adapter.enabled ? root.paired : []

        ListRow {
            required property var modelData
            width: root.width
            icon: root.iconFor(modelData)
            title: modelData.name || modelData.address
            subtitle: root.subtitleFor(modelData)
            selected: modelData.connected
            busy: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
            onClicked: root.choose(modelData)
        }
    }

    // Scan for new devices
    Rectangle {
        visible: root.adapter && root.adapter.enabled
        width: parent.width
        height: 38
        radius: 14
        color: scanHover.hovered ? Theme.chipHover : Theme.chip
        Text {
            anchors.centerIn: parent
            text: root.adapter && root.adapter.discovering ? "Stop scanning" : "Scan for devices"
            color: Theme.text
            font { family: Theme.font; pixelSize: 13; styleName: "Medium" }
        }
        HoverHandler { id: scanHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: root.adapter.discovering = !root.adapter.discovering }
    }

    Repeater {
        model: root.adapter && root.adapter.discovering ? root.found.slice(0, 8) : []

        ListRow {
            required property var modelData
            width: root.width
            icon: root.iconFor(modelData)
            title: modelData.name
            subtitle: root.subtitleFor(modelData)
            busy: modelData.pairing
            onClicked: root.choose(modelData)
        }
    }
}
