pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property bool available: sink !== null && sink.ready && sink.audio !== null
    property var inputDevices: []
    readonly property bool muted: available ? sink.audio.muted : false
    property var outputDevices: []
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool sourceAvailable: source !== null && source.ready && source.audio !== null
    readonly property bool sourceMuted: sourceAvailable ? source.audio.muted : false
    readonly property real volume: available ? Math.min(1, Math.max(0, sink.audio.volume)) : 0
    readonly property string volumeIcon: {
        if (muted)
        return "volume_off";
        if (volume < 0.01)
        return "volume_mute";
        if (volume < 0.5)
        return "volume_down";
        return "volume_up";
    }

    function deviceDisplayName(node) {
        if (!node)
            return "Unavailable";

        const description = node.description?.trim();
        const nickname = node.nickname?.trim();
        const name = node.name?.trim();
        return description || nickname || name || "Unknown device";
    }

    function rebuildDeviceLists() {
        const inputs = [];
        const outputs = [];

        for (const node of Pipewire.nodes.values) {
            if (!node?.audio || node.isStream)
                continue;

            if (node.isSink)
                outputs.push(node);
            else
                inputs.push(node);
        }

        const compareNames = (first, second) => deviceDisplayName(first).localeCompare(
                                                    deviceDisplayName(second));
        inputs.sort(compareNames);
        outputs.sort(compareNames);
        inputDevices = inputs;
        outputDevices = outputs;
    }

    function setSink(node) {
        if (node)
            Pipewire.preferredDefaultAudioSink = node;
    }

    function setSource(node) {
        if (node)
            Pipewire.preferredDefaultAudioSource = node;
    }

    function setVolume(value) {
        if (!available)
            return;

        sink.audio.volume = Math.min(1, Math.max(0, value));
        if (sink.audio.muted && value > 0)
            sink.audio.muted = false;
    }

    function toggleMuted() {
        if (available)
            sink.audio.muted = !sink.audio.muted;
    }

    Component.onCompleted: rebuildDeviceLists()

    Connections {
        function onValuesChanged() {
            root.rebuildDeviceLists();
        }

        target: Pipewire.nodes
    }

    PwObjectTracker {
        objects: Pipewire.nodes.values.filter(node => node.audio && !node.isStream)
    }
}
