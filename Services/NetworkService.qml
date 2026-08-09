pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string networkStatus: "disconnected" // "ethernet", "wifi", "disconnected"
    property bool wifiEnabled: false
    property string wifiSsid: ""
    property string wifiSignalStrengthStr: "excellent"

    function openWifiSettings() {
        Quickshell.execDetached(["nm-connection-editor"]);
    }

    function setWifiEnabled(enabled) {
        Quickshell.execDetached(["nmcli", "radio", "wifi", enabled ? "on" : "off"]);
        wifiEnabled = enabled;
        refreshTimer.restart();
    }

    function getSignalQuality(strength) {
        if (strength >= 75)
            return "excellent";
        if (strength >= 50)
            return "good";
        if (strength >= 25)
            return "fair";
        return "poor";
    }

    function refreshNetworkState() {
        if (!networkStatusQuery.running)
            networkStatusQuery.running = true;
        if (!wifiRadioQuery.running)
            wifiRadioQuery.running = true;
    }

    Component.onCompleted: {
        nmStateMonitor.running = true;
        root.refreshNetworkState();
    }

    Timer {
        id: refreshTimer

        interval: 250
        onTriggered: root.refreshNetworkState()
    }

    Timer {
        id: pollTimer

        interval: 15000
        repeat: true
        running: true

        onTriggered: root.refreshNetworkState()
    }

    Timer {
        id: restartTimer

        interval: 5000

        onTriggered: nmStateMonitor.running = true
    }

    Process {
        id: nmStateMonitor

        property bool startedOnce: false

        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.NetworkManager"]
        running: false

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: line => {
                if (line.includes("StateChanged") || line.includes("PrimaryConnectionChanged")
                        || line.includes("WirelessEnabled") || line.includes("ActiveConnection")) {
                    refreshTimer.restart();
                }
            }
        }

        onRunningChanged: {
            if (running) {
                startedOnce = true;
            } else if (startedOnce && !restartTimer.running) {
                restartTimer.start();
            }
        }
    }

    Process {
        id: networkStatusQuery

        command: ["nmcli", "-t", "-f", "TYPE,STATE", "device", "status"]
        running: false

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") {
                    root.networkStatus = "disconnected";
                    root.wifiSignalStrengthStr = "excellent";
                }
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                let hasEthernet = false;
                let hasWifi = false;

                for (const line of text.trim().split("\n")) {
                    if (!line)
                    continue;

                    const parts = line.split(":");
                    const type = parts[0] || "";
                    const state = parts[1] || "";

                    if (!state.startsWith("connected"))
                    continue;

                    if (type === "ethernet") {
                        hasEthernet = true;
                    } else if (type === "wifi") {
                        hasWifi = true;
                    }
                }

                // The top bar renders a single network icon, so prefer ethernet when both are up.
                if (hasEthernet) {
                    root.networkStatus = "ethernet";
                    root.wifiSignalStrengthStr = "excellent";
                } else if (hasWifi) {
                    root.networkStatus = "wifi";
                    if (!wifiSignalQuery.running)
                    wifiSignalQuery.running = true;
                } else {
                    root.networkStatus = "disconnected";
                    root.wifiSignalStrengthStr = "excellent";
                }
            }
        }
    }

    Process {
        id: wifiRadioQuery

        command: ["nmcli", "-t", "-f", "WIFI", "radio"]
        running: false

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "")
                root.wifiEnabled = false;
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled";
            }
        }
    }

    Process {
        id: wifiSignalQuery

        command: ["nmcli", "-t", "--escape", "no", "-f", "ACTIVE,SIGNAL,SSID", "dev", "wifi"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                let activeSignal = -1;

                for (const line of text.trim().split("\n")) {
                    if (!line)
                    continue;

                    const firstSeparator = line.indexOf(":");
                    const secondSeparator = line.indexOf(":", firstSeparator + 1);
                    if (firstSeparator < 0 || secondSeparator < 0)
                    continue;

                    if (line.slice(0, firstSeparator) === "yes") {
                        activeSignal = parseInt(line.slice(firstSeparator + 1, secondSeparator))
                        || 0;
                        root.wifiSsid = line.slice(secondSeparator + 1);
                        break;
                    }
                }

                if (activeSignal >= 0) {
                    root.wifiSignalStrengthStr = root.getSignalQuality(activeSignal);
                } else {
                    root.wifiSsid = "";
                }
            }
        }
    }
}
