pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io

Singleton {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool adapterTransitioning: adapter?.state === BluetoothAdapterState.Disabling
    readonly property bool available: adapter !== null
    property var connectedAddresses: []
    property bool connectionStateLoaded: false
    property int connectionGeneration: 0
    readonly property bool enabled: adapter?.enabled === true || adapter?.state
                                    === BluetoothAdapterState.Enabled || adapter?.state
                                    === BluetoothAdapterState.Enabling
    readonly property var knownDevices: {
        const devices = adapter?.devices.values.filter(device => device.paired || device.bonded)
              ?? [];
        return devices.slice().sort((left, right) => {
            const leftConnected = root.isDeviceConnected(left);
            const rightConnected = root.isDeviceConnected(right);
            if (leftConnected !== rightConnected)
                return leftConnected ? -1 : 1;
            return root.deviceName(left).localeCompare(root.deviceName(right));
        });
    }
    readonly property string statusText: {
        if (!available)
            return "Unavailable";
        if (!enabled)
            return "Off";

        const connectedDevice = adapter.devices.values.find(device => root.isDeviceConnected(
                                                                          device));
        return connectedDevice?.name || "On";
    }

    function isDeviceConnected(device) {
        if (!enabled)
            return false;
        if (!connectionStateLoaded)
            return device?.connected ?? false;

        const address = (device?.address ?? "").toUpperCase();
        return address !== "" && connectedAddresses.includes(address);
    }

    function refreshConnectionState() {
        if (!enabled) {
            connectedAddresses = [];
            connectionStateLoaded = true;
            return;
        }

        if (connectedDevicesQuery.running) {
            connectedDevicesQuery.refreshPending = true;
            return;
        }

        connectedDevicesQuery.queryAdapterPath = adapter?.dbusPath ?? "";
        connectedDevicesQuery.queryGeneration = connectionGeneration;
        connectedDevicesQuery.parsedAddresses = null;
        connectedDevicesQuery.running = true;
    }

    function resetConnectionState() {
        connectionGeneration++;
        connectedAddresses = [];
        connectionStateLoaded = false;
        refreshConnectionState();
    }

    // Read typed BlueZ properties, not bluetoothctl's colorized display output.
    // null means an invalid snapshot; an empty array means no connected devices.
    function parseConnectedAddresses(text, adapterPath) {
        try {
            const response = JSON.parse(text);
            if (response.type !== "a{oa{sa{sv}}}" || !Array.isArray(response.data)
                    || response.data.length !== 1)
                return null;

            const objects = response.data[0];
            const adapterProperties = objects?.[adapterPath]?.["org.bluez.Adapter1"];
            if (typeof adapterProperties?.Powered?.data !== "boolean")
                return null;
            if (!adapterProperties.Powered.data)
                return [];

            const addresses = [];
            for (const interfaces of Object.values(objects)) {
                const device = interfaces["org.bluez.Device1"];
                if (!device || device.Adapter?.data !== adapterPath)
                    continue;
                if (typeof device.Connected?.data !== "boolean" || typeof device.Address?.data
                        !== "string")
                    return null;
                if (device.Connected.data)
                    addresses.push(device.Address.data.toUpperCase());
            }
            return addresses;
        } catch (error) {
            return null;
        }
    }

    function deviceIcon(device) {
        const description = ((device?.icon ?? "") + " " + (device?.deviceName ?? "") + " " + (device
                                                                                              ?.name ?? "")).toLowerCase(
                  );
        if (description.includes("keyboard"))
            return "keyboard";
        if (description.includes("mouse"))
            return "mouse";
        if (description.includes("headphone") || description.includes("headset")
                || description.includes("audio"))
            return "headphones";
        if (description.includes("game") || description.includes("joystick") || description.includes(
                    "controller"))
            return "sports_esports";
        if (description.includes("phone"))
            return "smartphone";
        if (description.includes("tablet"))
            return "tablet";
        if (description.includes("computer"))
            return "computer";
        if (description.includes("printer"))
            return "print";
        return "bluetooth";
    }

    function powerStatus() {
        if (!available)
            return "Bluetooth is unavailable";
        if (adapter?.state === BluetoothAdapterState.Disabling)
            return "Turning Bluetooth off…";
        return "Bluetooth is off";
    }

    function deviceName(device) {
        return device?.name || device?.deviceName || device?.address || "Unknown Device";
    }

    function deviceStatus(device) {
        const connected = root.isDeviceConnected(device);
        let status = connected ? "Connected" : "Disconnected";
        if (device?.state === BluetoothDeviceState.Connecting && !connected)
            status = "Connecting…";
        else if (device?.state === BluetoothDeviceState.Disconnecting && connected)
            status = "Disconnecting…";

        if (connected && device?.batteryAvailable)
            status += " · " + Math.round(device.battery * 100) + "%";
        return status;
    }

    function isDeviceTransitioning(device) {
        return device?.state === BluetoothDeviceState.Connecting || device?.state
                === BluetoothDeviceState.Disconnecting;
    }

    function openSettings() {
        Quickshell.execDetached(["blueman-manager"]);
    }

    function setEnabled(enabled) {
        if (adapter) {
            adapter.enabled = enabled;
            connectionRefreshTimer.restart();
        }
    }

    function toggleDeviceConnection(device) {
        if (!device || isDeviceTransitioning(device))
            return;
        if (root.isDeviceConnected(device))
            device.disconnect();
        else
            device.connect();
        connectionRefreshTimer.restart();
    }

    Component.onCompleted: refreshConnectionState()

    onAdapterChanged: resetConnectionState()
    onEnabledChanged: resetConnectionState()

    Timer {
        id: connectionRefreshTimer

        interval: 1000
        onTriggered: root.refreshConnectionState()
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.enabled

        onTriggered: root.refreshConnectionState()
    }

    Process {
        id: connectedDevicesQuery

        property var parsedAddresses: null
        property string queryAdapterPath: ""
        property int queryGeneration: 0
        property bool refreshPending: false

        command: ["busctl", "--system", "--timeout=3", "--json=short", "call", "org.bluez", "/",
            "org.freedesktop.DBus.ObjectManager", "GetManagedObjects"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                connectedDevicesQuery.parsedAddresses = root.parseConnectedAddresses(text,
                                                                                     connectedDevicesQuery.queryAdapterPath);
            }
        }

        // qmllint disable signal-handler-parameters
        onExited: exitCode => {
            if (exitCode === 0 && parsedAddresses !== null && root.enabled && queryGeneration
                    === root.connectionGeneration && queryAdapterPath === root.adapter?.dbusPath) {
                root.connectedAddresses = parsedAddresses;
                root.connectionStateLoaded = true;
            }

            if (refreshPending) {
                refreshPending = false;
                Qt.callLater(() => root.refreshConnectionState());
            }
        }
        // qmllint enable signal-handler-parameters
    }
}
