import QtQuick
import Quickshell
import Quickshell.Networking
import ".."

// Wi-Fi networks: connect, disconnect, or enter a password for new ones.
Column {
    id: root

    spacing: 6

    readonly property var dev: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var nets: dev && dev.networks
        ? dev.networks.values.filter(n => n.name).slice().sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))
        : []
    property var askingFor: null          // network waiting for a password

    // Scan only while this page is visible
    Component.onCompleted: if (dev) dev.scannerEnabled = true
    Component.onDestruction: if (dev) dev.scannerEnabled = false

    function strengthIcon(s) {
        if (s > 1) s /= 100;              // reported as 0..100
        return s > 0.75 ? "\u{F0928}" : s > 0.5 ? "\u{F0925}" : s > 0.25 ? "\u{F0922}" : "\u{F091F}";
    }

    function choose(n) {
        if (n.connected) n.disconnect();
        else if (n.known || n.security === WifiSecurityType.Open) n.connect();
        else { askingFor = n; pass.text = ""; pass.forceActiveFocus(); }
    }

    PageHeader {
        width: parent.width
        title: "Wi-Fi"
        hasSwitch: true
        switchOn: Networking.wifiEnabled
        onSwitched: Networking.wifiEnabled = !Networking.wifiEnabled
    }

    // Password prompt for a secured, unknown network
    Rectangle {
        visible: root.askingFor !== null
        width: parent.width
        height: 46
        radius: 14
        color: Theme.chip
        border.width: 1
        border.color: pass.activeFocus ? Theme.accent : "transparent"

        TextInput {
            id: pass
            anchors { left: parent.left; leftMargin: 14; right: go.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
            echoMode: TextInput.Password
            color: Theme.text
            font { family: Theme.font; pixelSize: 13 }
            clip: true
            onAccepted: go.submit()
            Keys.onEscapePressed: root.askingFor = null

            Text {
                visible: !pass.text
                text: root.askingFor ? "Password for " + root.askingFor.name : ""
                color: Theme.textFaint
                font: pass.font
            }
        }
        Text {
            id: go
            anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
            text: "Join"
            color: Theme.accent
            font { family: Theme.font; pixelSize: 13; weight: Font.DemiBold }
            function submit() {
                if (root.askingFor && pass.text) root.askingFor.connectWithPsk(pass.text);
                root.askingFor = null;
            }
            HoverHandler { cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: go.submit() }
        }
    }

    Text {
        visible: !Networking.wifiEnabled || root.nets.length === 0
        width: parent.width
        topPadding: 12
        bottomPadding: 12
        horizontalAlignment: Text.AlignHCenter
        text: !Networking.wifiEnabled ? "Wi-Fi is off" : "Searching…"
        color: Theme.textFaint
        font { family: Theme.font; pixelSize: 13 }
    }

    Repeater {
        model: Networking.wifiEnabled ? root.nets.slice(0, 12) : []

        ListRow {
            required property var modelData
            width: root.width
            icon: root.strengthIcon(modelData.signalStrength)
            title: modelData.name
            subtitle: modelData.connected ? "Connected" : modelData.known ? "Saved" : modelData.security === WifiSecurityType.Open ? "Open" : "Secured"
            trailing: modelData.security === WifiSecurityType.Open ? "" : Icons.wifiLock
            selected: modelData.connected
            busy: modelData.stateChanging
            onClicked: root.choose(modelData)
        }
    }
}
