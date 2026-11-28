pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string unitName: "lumen-prevent-sleep.service"
    property bool active: false
    property bool available: false
    property bool busy: false
    property string errorText: ""
    property string pendingSleepMode: ""
    property bool refreshPending: false

    function refresh() {
        if (statusQuery.running) {
            refreshPending = true;
            return;
        }
        statusQuery.running = true;
    }

    function setEnabled(enabled) {
        if (!available || busy || enabled === active)
            return;

        busy = true;
        errorText = "";
        operation.targetEnabled = enabled;
        operation.capturedError = "";
        operation.command = enabled ? ["systemd-run", "--user", "--unit=" + unitName, "--collect", "--service-type=exec",
                                       "--property=PartOf=graphical-session.target",
                                       "--description=Lumen Prevent Sleep",
                                       "/usr/bin/systemd-inhibit", "--what=sleep", "--mode=block",
                                       "--who=Lumen", "--why=Prevent Sleep is enabled",
                                       "/usr/bin/sleep", "infinity"] : ["systemctl", "--user",
                                                                        "stop", unitName];
        operation.running = true;
    }

    function toggle() {
        setEnabled(!active);
    }

    function requestSleep(mode) {
        if ((mode !== "suspend" && mode !== "hibernate") || busy)
            return;

        if (!available) {
            pendingSleepMode = mode;
            refresh();
        } else if (active) {
            pendingSleepMode = mode;
            setEnabled(false);
        } else {
            Quickshell.execDetached(["systemctl", mode]);
        }
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 10000
        repeat: true
        running: true

        onTriggered: root.refresh()
    }

    Process {
        id: statusQuery

        property string state: ""

        command: ["systemctl", "--user", "show", "--property=ActiveState", "--value", root.unitName]
        onStarted: state = ""

        stdout: StdioCollector {
            onStreamFinished: statusQuery.state = text.trim()
        }

        // qmllint disable signal-handler-parameters
        onExited: exitCode => {
            if (exitCode === 0 && (state === "active" || state === "inactive" || state
                                   === "failed")) {
                root.active = state === "active";
                root.available = true;
                if (root.errorText === "Could not check sleep inhibition")
                    root.errorText = "";
            } else {
                root.available = false;
                root.errorText = "Could not check sleep inhibition";
            }

            if (root.refreshPending) {
                root.refreshPending = false;
                Qt.callLater(() => root.refresh());
            } else if (root.pendingSleepMode !== "" && !root.busy && root.available) {
                const mode = root.pendingSleepMode;
                root.pendingSleepMode = "";
                root.requestSleep(mode);
            } else if (root.pendingSleepMode !== "" && !root.busy && !root.available) {
                root.pendingSleepMode = "";
            }
        }
        // qmllint enable signal-handler-parameters
    }

    Process {
        id: operation

        property bool targetEnabled: false
        property string capturedError: ""

        running: false

        stderr: StdioCollector {
            onStreamFinished: operation.capturedError = text.trim()
        }

        // qmllint disable signal-handler-parameters
        onExited: exitCode => {
            root.busy = false;
            if (exitCode !== 0) {
                root.errorText = capturedError.split("\n")[0]
                        || "Could not change sleep inhibition";
                root.pendingSleepMode = "";
            } else if (!targetEnabled && root.pendingSleepMode !== "") {
                const mode = root.pendingSleepMode;
                root.pendingSleepMode = "";
                Quickshell.execDetached(["systemctl", mode]);
            }
            root.refresh();
        }
        // qmllint enable signal-handler-parameters
    }
}
