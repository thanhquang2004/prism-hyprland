import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import ".."

// Audio: output and input device selection, per-app volume.
Column {
    id: root

    spacing: 6

    function cls(n) { return n.properties ? n.properties["media.class"] : ""; }
    function label(n) { return n.description || n.nickname || n.name; }

    readonly property var nodes: Pipewire.nodes.values
    readonly property var outputs: nodes.filter(n => n.audio && cls(n) === "Audio/Sink")
    readonly property var inputs: nodes.filter(n => n.audio && cls(n) === "Audio/Source")
    readonly property var apps: nodes.filter(n => n.audio && cls(n) === "Stream/Output/Audio")

    PwObjectTracker { objects: root.apps }

    component Section: Text {
        topPadding: 8
        color: Theme.textDim
        font { family: Theme.font; pixelSize: 12; weight: Font.DemiBold }
    }

    PageHeader { width: parent.width; title: "Sound" }

    Section { text: "Output" }
    Repeater {
        model: root.outputs
        ListRow {
            required property var modelData
            width: root.width
            icon: (modelData.name || "").includes("bluez") ? Icons.headphones : Icons.speaker
            title: root.label(modelData)
            selected: modelData === Pipewire.defaultAudioSink
            onClicked: Pipewire.preferredDefaultAudioSink = modelData
        }
    }

    Section { text: "Input" }
    Repeater {
        model: root.inputs
        ListRow {
            required property var modelData
            width: root.width
            icon: Icons.mic
            title: root.label(modelData)
            selected: modelData === Pipewire.defaultAudioSource
            onClicked: Pipewire.preferredDefaultAudioSource = modelData
        }
    }

    Section { text: "Apps"; visible: root.apps.length > 0 }
    Repeater {
        model: root.apps
        Column {
            required property var modelData
            width: root.width
            Text {
                leftPadding: 4
                text: modelData.properties["application.name"] || root.label(modelData)
                color: Theme.text
                font { family: Theme.font; pixelSize: 12 }
            }
            Slider {
                width: parent.width
                icon: modelData.audio.muted ? Icons.volMute : Icons.volHigh
                value: modelData.audio.volume
                muted: modelData.audio.muted
                onMoved: v => modelData.audio.volume = v
                onIconClicked: modelData.audio.muted = !modelData.audio.muted
            }
        }
    }
}
