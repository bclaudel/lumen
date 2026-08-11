pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string activeConnectionUuid: ""
    property var accessPoints: []
    property string connectionError: ""
    property string connectingSsid: ""
    readonly property var knownNetworks: buildNetworkGroups().known
    property string lastOperationSsid: ""
    property bool networkSelectionActive: false
    property string networkStatus: "disconnected" // "ethernet", "wifi", "disconnected"
    readonly property var otherNetworks: buildNetworkGroups().other
    property string pendingPassword: ""
    property var pendingSavedProfiles: []
    property var profileCandidates: []
    property int profileQueryIndex: 0
    property bool profilesLoaded: false
    property bool profilesRefreshPending: false
    property bool profilesRefreshing: false
    property var savedProfiles: []
    property string scanError: ""
    readonly property bool scanning: wifiScanQuery.running || profilesRefreshing
    property string wifiDevice: ""
    property bool wifiEnabled: false
    property bool wifiPopupOpen: false
    property string wifiSignalStrengthStr: "excellent"
    property string wifiSsid: ""

    signal connectionFinished(string ssid, bool success, string error)

    function buildNetworkGroups() {
        const known = [];
        const other = [];

        for (const accessPoint of accessPoints) {
            const matchingProfiles = savedProfiles.filter(profile => profile.ssid
                                                                     === accessPoint.ssid);
            if (matchingProfiles.length > 0) {
                const activeProfile = matchingProfiles.find(profile => profile.uuid
                                                                       === activeConnectionUuid);
                known.push(Object.assign({}, accessPoint, {
                                             "known": true,
                                             "uuid": activeProfile?.uuid ?? matchingProfiles[0].uuid
                                         }));
            } else {
                other.push(Object.assign({}, accessPoint, {
                                             "known": false,
                                             "uuid": ""
                                         }));
            }
        }

        const byConnectionAndSignal = (left, right) => {
            if (left.active !== right.active)
                return left.active ? -1 : 1;
            return right.signal - left.signal;
        };
        known.sort(byConnectionAndSignal);
        other.sort(byConnectionAndSignal);
        return {
            "known": known,
            "other": other
        };
    }

    function connectKnownNetwork(network) {
        if (!network?.uuid || connectionProcess.running)
            return;

        startConnection(["nmcli", "connection", "up", "uuid", network.uuid], network.ssid, "");
    }

    function connectNetwork(network, password) {
        if (!network?.ssid || network.enterprise || connectionProcess.running)
            return;

        const command = network.secured ? ["nmcli", "--ask", "device", "wifi", "connect", network.ssid] :
                                          ["nmcli", "device", "wifi", "connect", network.ssid];
        startConnection(command, network.ssid, network.secured ? password : "");
    }

    function disconnectActiveNetwork() {
        if (connectionProcess.running || (!activeConnectionUuid && !wifiDevice))
            return;

        const command = activeConnectionUuid ? ["nmcli", "connection", "down", "uuid",
                                                activeConnectionUuid] : ["nmcli", "device",
                                                                         "disconnect", wifiDevice];
        startConnection(command, wifiSsid, "");
    }

    function formatError(message) {
        const firstLine = message.trim().split("\n")[0] ?? "";
        return firstLine.replace(/^Error:\s*/, "") || "The network operation failed";
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

    function openWifiSettings() {
        Quickshell.execDetached(["nm-connection-editor"]);
    }

    function parseNmcliLine(line) {
        const fields = [];
        let current = "";
        let escaped = false;

        for (let index = 0; index < line.length; index++) {
            const character = line[index];
            if (escaped) {
                current += character;
                escaped = false;
            } else if (character === "\\") {
                escaped = true;
            } else if (character === ":") {
                fields.push(current);
                current = "";
            } else {
                current += character;
            }
        }

        if (escaped)
            current += "\\";
        fields.push(current);
        return fields;
    }

    function queryNextProfileSsid() {
        if (profileQueryIndex >= profileCandidates.length) {
            savedProfiles = pendingSavedProfiles;
            profilesLoaded = true;
            profilesRefreshing = false;
            if (profilesRefreshPending) {
                profilesRefreshPending = false;
                Qt.callLater(() => root.refreshSavedProfiles());
            }
            return;
        }

        profileSsidQuery.capturedSsid = "";
        profileSsidQuery.command = ["nmcli", "-g", "802-11-wireless.ssid", "connection", "show",
                                    "uuid", profileCandidates[profileQueryIndex].uuid];
        profileSsidQuery.running = true;
    }

    function refreshNetworkState() {
        if (!networkStatusQuery.running)
            networkStatusQuery.running = true;
        if (!wifiRadioQuery.running)
            wifiRadioQuery.running = true;
        if (!activeConnectionQuery.running)
            activeConnectionQuery.running = true;
    }

    function refreshSavedProfiles() {
        if (savedProfilesQuery.running || profileSsidQuery.running) {
            profilesRefreshPending = true;
            return;
        }

        profilesRefreshing = true;
        profilesLoaded = false;
        savedProfilesQuery.running = true;
    }

    function refreshWifiNetworks(forceRescan, refreshProfiles) {
        if (!wifiEnabled || networkSelectionActive)
            return;

        if (refreshProfiles)
            refreshSavedProfiles();
        if (!wifiScanQuery.running) {
            scanError = "";
            wifiScanQuery.command = ["nmcli", "-t", "--escape", "yes", "-f",
                                     "IN-USE,SSID,BSSID,SIGNAL,SECURITY", "device", "wifi", "list",
                                     "--rescan", forceRescan ? "yes" : "auto"];
            wifiScanQuery.running = true;
        }
    }

    function setWifiEnabled(enabled) {
        Quickshell.execDetached(["nmcli", "radio", "wifi", enabled ? "on" : "off"]);
        wifiEnabled = enabled;
        if (!enabled) {
            accessPoints = [];
            wifiSsid = "";
            connectionError = "";
        }
        refreshTimer.restart();
    }

    function signalIcon(signalStrength) {
        switch (getSignalQuality(signalStrength)) {
        case "excellent":
            return "wifi";
        case "good":
            return "wifi_2_bar";
        case "fair":
            return "wifi_1_bar";
        default:
            return "signal_wifi_0_bar";
        }
    }

    function startConnection(command, ssid, password) {
        connectionError = "";
        connectionProcess.capturedError = "";
        connectingSsid = ssid;
        lastOperationSsid = ssid;
        pendingPassword = password;
        connectionProcess.command = command;
        connectionProcess.stdinEnabled = password !== "";
        connectionProcess.running = true;
    }

    Component.onCompleted: {
        nmStateMonitor.running = true;
        root.refreshSavedProfiles();
        root.refreshNetworkState();
    }

    onWifiPopupOpenChanged: {
        if (wifiPopupOpen) {
            refreshNetworkState();
            refreshWifiNetworks(true, true);
        }
    }

    Timer {
        id: refreshTimer

        interval: 250
        onTriggered: {
            root.refreshNetworkState();
            if (root.wifiPopupOpen && !root.networkSelectionActive)
            networkRefreshTimer.restart();
        }
    }

    Timer {
        id: networkRefreshTimer

        interval: 750
        onTriggered: root.refreshWifiNetworks(false, !root.profilesLoaded)
    }

    Timer {
        interval: 15000
        repeat: true
        running: root.wifiPopupOpen && root.wifiEnabled && !root.networkSelectionActive

        onTriggered: root.refreshWifiNetworks(false)
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
                        || line.includes("WirelessEnabled") || line.includes("ActiveConnection")
                        || line.includes("AccessPoint")) {
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

        command: ["nmcli", "-t", "--escape", "yes", "-f", "DEVICE,TYPE,STATE", "device", "status"]
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
                let wifiDevice = "";

                for (const line of text.trim().split("\n")) {
                    if (!line)
                    continue;

                    const parts = root.parseNmcliLine(line);
                    const device = parts[0] || "";
                    const type = parts[1] || "";
                    const state = parts[2] || "";

                    if (type === "wifi" && wifiDevice === "")
                    wifiDevice = device;
                    if (!state.startsWith("connected"))
                    continue;
                    if (type === "ethernet")
                    hasEthernet = true;
                    else if (type === "wifi")
                    hasWifi = true;
                }

                root.wifiDevice = wifiDevice;
                if (hasEthernet) {
                    root.networkStatus = "ethernet";
                    root.wifiSignalStrengthStr = "excellent";
                } else if (hasWifi) {
                    root.networkStatus = "wifi";
                } else {
                    root.networkStatus = "disconnected";
                    root.wifiSignalStrengthStr = "excellent";
                }
            }
        }
    }

    Process {
        id: activeConnectionQuery

        command: ["nmcli", "-t", "--escape", "yes", "-f", "UUID,TYPE,DEVICE", "connection", "show",
            "--active"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                let activeUuid = "";
                for (const line of text.trim().split("\n")) {
                    if (!line)
                    continue;
                    const parts = root.parseNmcliLine(line);
                    if (parts[1] === "802-11-wireless") {
                        activeUuid = parts[0] || "";
                        break;
                    }
                }
                root.activeConnectionUuid = activeUuid;
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
                const enabled = text.trim() === "enabled";
                root.wifiEnabled = enabled;
                if (!enabled) {
                    root.accessPoints = [];
                    root.wifiSsid = "";
                } else {
                    if (root.accessPoints.length === 0)
                    root.refreshWifiNetworks(false, false);
                    if (root.wifiPopupOpen)
                    networkRefreshTimer.restart();
                }
            }
        }
    }

    Process {
        id: savedProfilesQuery

        command: ["nmcli", "-t", "--escape", "yes", "-f", "UUID,TYPE,TIMESTAMP", "connection",
            "show"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const candidates = [];
                for (const line of text.trim().split("\n")) {
                    if (!line)
                    continue;
                    const parts = root.parseNmcliLine(line);
                    if (parts[1] === "802-11-wireless" && (parseInt(parts[2]) || 0) > 0)
                    candidates.push({
                                        "uuid": parts[0]
                                    });
                }
                root.profileCandidates = candidates;
                root.profileQueryIndex = 0;
                root.pendingSavedProfiles = [];
                Qt.callLater(() => root.queryNextProfileSsid());
            }
        }
    }

    Process {
        id: profileSsidQuery

        property string capturedSsid: ""
        property bool startedOnce: false

        running: false

        stdout: StdioCollector {
            onStreamFinished: profileSsidQuery.capturedSsid = text.trim()
        }

        onRunningChanged: {
            if (running) {
                startedOnce = true;
            } else if (startedOnce) {
                startedOnce = false;
                Qt.callLater(() => {
                    const candidate = root.profileCandidates[root.profileQueryIndex];
                    if (candidate && capturedSsid !== "") {
                        root.pendingSavedProfiles = root.pendingSavedProfiles.concat([
                                                                                         {
                                                                                             "ssid": root.parseNmcliLine(
                                                                                                         capturedSsid)[0],
                                                                                             "uuid": candidate.uuid
                                                                                         }
                                                                                     ]);
                    }
                    root.profileQueryIndex++;
                    root.queryNextProfileSsid();
                });
            }
        }
    }

    Process {
        id: wifiScanQuery

        running: false

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "")
                root.scanError = root.formatError(text);
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const bySsid = {};
                for (const line of text.trim().split("\n")) {
                    if (!line)
                    continue;

                    const parts = root.parseNmcliLine(line);
                    const ssid = parts[1] || "";
                    if (ssid === "")
                    continue;

                    const security = parts[4] || "";
                    const accessPoint = {
                        "active": parts[0] === "*",
                        "bssid": parts[2] || "",
                        "enterprise": security.includes("802.1X") || security.includes("EAP"),
                        "secured": security !== "" && security !== "--",
                        "security": security,
                        "signal": parseInt(parts[3]) || 0,
                        "ssid": ssid
                    };
                    const current = bySsid[ssid];
                    if (!current || accessPoint.active || (!current.active && accessPoint.signal
                                                           > current.signal))
                    bySsid[ssid] = accessPoint;
                }

                root.accessPoints = Object.values(bySsid);
                const activeNetwork = root.accessPoints.find(network => network.active);
                if (activeNetwork) {
                    root.wifiSsid = activeNetwork.ssid;
                    root.wifiSignalStrengthStr = root.getSignalQuality(activeNetwork.signal);
                } else {
                    root.wifiSsid = "";
                }
            }
        }
    }

    Process {
        id: connectionProcess

        property string capturedError: ""

        running: false

        stderr: StdioCollector {
            onStreamFinished: connectionProcess.capturedError = text
        }

        onStarted: {
            if (root.pendingPassword !== "") {
                write(root.pendingPassword + "\n");
                root.pendingPassword = "";
            }
        }

        // qmllint disable signal-handler-parameters
        onExited: exitCode => {
            const ssid = root.connectingSsid;
            const success = exitCode === 0;
            root.connectionError = success ? "" : root.formatError(capturedError);
            root.connectingSsid = "";
            root.connectionFinished(ssid, success, root.connectionError);
            if (success)
                root.refreshSavedProfiles();
            refreshTimer.restart();
        }
        // qmllint enable signal-handler-parameters
    }
}
