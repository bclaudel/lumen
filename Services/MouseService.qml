pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool monitoring: false
    property var status: null
    readonly property bool busy: query.running
    readonly property var device: ({
                                       "name": "WLMouse Beast X Pro",
                                       "icon": "mouse",
                                       "connected": status?.connected === true,
                                       "batteryAvailable": status !== null,
                                       "batteryLevel": status?.battery ?? 0
                                   })
    readonly property string statusText: status ? "Connected · " + status.battery + "%" + (status.charging
                                                                                           ? " · Charging" :
                                                                                             "") + " · "
                                                  + details : "Disconnected"
    readonly property string details: status ? status.dpi_x + (status.dpi_x !== status.dpi_y
                                                               ? " × " + status.dpi_y : "")
                                               + " DPI · " + status.polling_rate_hz + " Hz" : ""

    function refresh() {
        if (!query.running)
            query.running = true;
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.monitoring

        onTriggered: root.refresh()
    }

    Process {
        id: query

        property var parsedStatus: null

        command: ["wlmouse-info", "--json"]
        onStarted: parsedStatus = null

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const response = JSON.parse(text);
                    if (response.connected === true && typeof response.battery === "number"
                            && Number.isFinite(response.battery) && response.battery >= 0
                            && response.battery <= 100)
                        query.parsedStatus = response;
                } catch (error) {
                    query.parsedStatus = null;
                }
            }
        }

        // qmllint disable signal-handler-parameters
        onExited: exitCode => root.status = exitCode === 0 ? parsedStatus : null
        // qmllint enable signal-handler-parameters
    }
}
