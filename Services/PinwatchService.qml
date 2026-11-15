pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Common

Singleton {
    id: root

    property bool monitoring: false
    property var channels: []
    property string freshness: "unavailable"
    readonly property bool fresh: freshness === "fresh" && channels.length === 6

    function clear() {
        channels = [];
        freshness = "unavailable";
        heartbeatWatchdog.invalidate();
    }

    function parseFrame(line) {
        try {
            const frame = JSON.parse(line);
            if (frame.schema_version !== 1 || frame.kind !== "telemetry" || !Array.isArray(
                        frame.gpus))

                return;

            const gpu = frame.gpus.find(entry => entry.device?.sensor_supported);
            const reading = gpu?.reading;
            const nextChannels = reading?.channels;
            if (!Array.isArray(nextChannels) || nextChannels.length !== 6 || !nextChannels.every((
                                                                                                     channel, index)
                                                                                                 => channel.channel_id
                                                                                                    === index
                                                                                                    + 1 && Number.isFinite(
                                                                                                        channel.current_a)
                                                                                                    && channel.current_a
                                                                                                    >= 0)) {
                clear();
                return;
            }

            channels = nextChannels;
            freshness = gpu.freshness === "fresh" ? "fresh" : gpu.freshness === "stale" ? "stale" :
                                                                                          "unavailable";
            heartbeatWatchdog.markUpdated();
        } catch (error) {
            // Keep the previous frame until a valid one arrives or the watchdog expires.
        }
    }

    onMonitoringChanged: {
        if (!monitoring) {
            restartTimer.stop();
            stream.running = false;
            clear();
        } else {
            stream.running = true;
        }
    }

    ReadingWatchdog {
        id: heartbeatWatchdog

        timeout: 4000
        onExpired: root.clear()
    }

    Timer {
        id: restartTimer

        interval: 3000
        onTriggered: {
            if (root.monitoring)
                stream.running = true;
        }
    }

    Process {
        id: stream

        command: ["/usr/local/bin/pinwatch", "watch", "--json"]

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: line => root.parseFrame(line)
        }

        onExited: {
            root.clear();
            if (root.monitoring)
                restartTimer.restart();
        }
    }
}
