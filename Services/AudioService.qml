pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property bool available: sink !== null && sink.ready && sink.audio !== null
    readonly property bool muted: available ? sink.audio.muted : false
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: available ? Math.min(1, Math.max(0, sink.audio.volume)) : 0

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

    PwObjectTracker {
        objects: [root.sink]
    }
}
