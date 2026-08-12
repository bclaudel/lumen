pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property string backend: ""
    readonly property string brightnessIcon: {
        if (value < 0.34)
        return "brightness_low";
        if (value < 0.67)
        return "brightness_medium";
        return "brightness_high";
    }
    property string ddcBus: ""
    property bool detecting: false
    property bool monitoring: false
    property string targetConnector: ""
    property real value: 0
    property bool writePending: false

    function decrease() {
        setBrightness(Math.round((value - 0.1) * 100) / 100);
    }

    function increase() {
        setBrightness(Math.round((value + 0.1) * 100) / 100);
    }

    function refresh() {
        if (writePending || applyTimer.running || brightnessQuery.running
                || brightnessWriter.running || ddcDetect.running || ddcQuery.running)
            return;

        detecting = true;
        brightnessQuery.parsed = false;
        brightnessQuery.running = true;
    }

    function refreshCurrentValue() {
        if (writePending || brightnessQuery.running || brightnessWriter.running
                || ddcDetect.running || ddcQuery.running)
            return;

        if (backend === "ddcutil" && ddcBus !== "") {
            ddcQuery.command = ["ddcutil", "-b", ddcBus, "getvcp", "10", "--brief"];
            ddcQuery.running = true;
        } else if (backend === "brightnessctl") {
            brightnessQuery.parsed = false;
            brightnessQuery.running = true;
        } else {
            refresh();
        }
    }

    function setUnavailable() {
        available = false;
        backend = "";
        ddcBus = "";
        detecting = false;
    }

    function setBrightness(newValue) {
        if (!available)
            return;

        confirmTimer.stop();
        writePending = true;
        value = Math.min(1, Math.max(0, newValue));
        applyTimer.restart();
    }

    function setTargetScreen(screen) {
        const connector = screen?.name || "";
        if (targetConnector === connector)
            return;

        targetConnector = connector;
        if (backend === "ddcutil" || !available)
            refresh();
    }

    Component.onCompleted: refresh()

    IpcHandler {
        target: "brightness"

        function decrement(): void {
            root.decrease();
        }

        function increment(): void {
            root.increase();
        }
    }

    GlobalShortcut {
        description: "Increase display brightness"
        name: "brightnessIncrease"

        onPressed: root.increase()
    }

    GlobalShortcut {
        description: "Decrease display brightness"
        name: "brightnessDecrease"

        onPressed: root.decrease()
    }

    Timer {
        id: applyTimer

        interval: 90

        onTriggered: {
            if (brightnessQuery.running || brightnessWriter.running || ddcDetect.running
                || ddcQuery.running) {
                restart();
                return;
            }

            const percent = Math.round(root.value * 100);
            if (root.backend === "brightnessctl") {
                brightnessWriter.exec(["brightnessctl", "-q", "-c", "backlight", "set", percent
                                       + "%"]);
            } else if (root.backend === "ddcutil" && root.ddcBus !== "") {
                brightnessWriter.exec(["ddcutil", "--noverify", "-b", root.ddcBus, "setvcp", "10",
                                       Math.max(1, percent).toString()]);
            }
        }
    }

    Timer {
        id: confirmTimer

        interval: 400
        onTriggered: {
            root.writePending = false;
            root.refreshCurrentValue();
        }
    }

    Timer {
        interval: 750
        repeat: true
        running: root.monitoring

        onTriggered: root.refreshCurrentValue()
    }

    Process {
        id: brightnessWriter

        property bool startedOnce: false

        onRunningChanged: {
            if (!running && startedOnce) {
                startedOnce = false;
                if (!applyTimer.running)
                confirmTimer.restart();
            }
        }
        onStarted: startedOnce = true
    }

    Process {
        id: brightnessQuery

        property bool parsed: false
        property bool startedOnce: false

        command: ["brightnessctl", "-m", "-c", "backlight", "info"]

        onRunningChanged: {
            if (!running && startedOnce) {
                startedOnce = false;
                Qt.callLater(() => {
                    if (!brightnessQuery.parsed && !ddcDetect.running)
                        ddcDetect.running = true;
                });
            }
        }
        onStarted: startedOnce = true

        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim().split("\n")[0] || "";
                const fields = line.split(",");
                const percent = parseInt(fields[3] || "");

                if (!isNaN(percent)) {
                    brightnessQuery.parsed = true;
                    if (root.writePending)
                    return;

                    root.backend = "brightnessctl";
                    root.available = true;
                    root.detecting = false;
                    root.value = Math.min(1, Math.max(0, percent / 100));
                }
            }
        }
    }

    Process {
        id: ddcDetect

        property bool startedOnce: false

        command: ["ddcutil", "detect", "--brief"]

        onRunningChanged: {
            if (!running && startedOnce) {
                startedOnce = false;
                Qt.callLater(() => {
                    if (root.detecting && !ddcQuery.running)
                        root.setUnavailable();
                });
            }
        }
        onStarted: startedOnce = true

        stdout: StdioCollector {
            onStreamFinished: {
                const displays = [];
                const blocks = text.split(/(?=Display\s+\d+)/);
                for (const block of blocks) {
                    const busMatch = block.match(/I2C bus:\s*\/dev\/i2c-(\d+)/);
                    if (!busMatch)
                    continue;
                    const connectorMatch = block.match(/DRM connector:\s*(\S+)/);
                    displays.push({
                                      "bus": busMatch[1],
                                      "connector": connectorMatch ? connectorMatch[1] : ""
                                  });
                }

                const matched = displays.find(display => display.connector.endsWith(
                                                             root.targetConnector));
                const selected = matched || displays[0];
                if (!selected) {
                    root.setUnavailable();
                    return;
                }

                root.ddcBus = selected.bus;
                ddcQuery.command = ["ddcutil", "-b", root.ddcBus, "getvcp", "10", "--brief"];
                ddcQuery.running = true;
            }
        }
    }

    Process {
        id: ddcQuery

        property bool parsed: false
        property bool startedOnce: false

        onRunningChanged: {
            if (!running && startedOnce) {
                startedOnce = false;
                Qt.callLater(() => {
                    if (!root.writePending && !ddcQuery.parsed)
                        root.setUnavailable();
                });
            }
        }
        onStarted: {
            parsed = false;
            startedOnce = true;
        }

        stdout: StdioCollector {
            onStreamFinished: {
                let current = -1;
                let maximum = -1;
                let match = text.match(/current value\s*=\s*(\d+).*max value\s*=\s*(\d+)/i);
                if (!match)
                match = text.match(/VCP\s+10\s+C\s+(\d+)\s+(\d+)/i);

                if (match) {
                    current = parseInt(match[1]);
                    maximum = parseInt(match[2]);
                }

                if (current >= 0 && maximum > 0) {
                    ddcQuery.parsed = true;
                    if (root.writePending)
                    return;

                    root.backend = "ddcutil";
                    root.available = true;
                    root.detecting = false;
                    root.value = Math.min(1, Math.max(0, current / maximum));
                }
            }
        }
    }
}
