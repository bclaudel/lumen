pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int batteryLevel: 0
    property bool connected: false
    readonly property string statusText: connected ? `SCUF Envision Pro · ${batteryLevel}%` :
                                                     "SCUF Envision Pro disconnected"

    function refresh() {
        if (batteryQuery.running)
            return;

        batteryQuery.parsedLevel = -1;
        batteryQuery.running = true;
    }

    function setDisconnected() {
        connected = false;
        batteryLevel = 0;
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 5000
        repeat: true
        running: true

        onTriggered: root.refresh()
    }

    Process {
        id: batteryQuery

        property int parsedLevel: -1

        command: ["scuf-battery", "--json"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const response = JSON.parse(text.trim());
                    const level = Number(response.percentage);
                    if (Number.isFinite(level) && level >= 0 && level <= 100)
                    batteryQuery.parsedLevel = Math.round(level);
                } catch (error) {
                    batteryQuery.parsedLevel = -1;
                }
            }
        }

        // qmllint disable signal-handler-parameters
        onExited: exitCode => {
            if (exitCode === 0 && parsedLevel >= 0) {
                root.batteryLevel = parsedLevel;
                root.connected = true;
            } else {
                root.setDisconnected();
            }
        }
        // qmllint enable signal-handler-parameters
    }
}
