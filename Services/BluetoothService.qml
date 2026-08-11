pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool adapterTransitioning: adapter?.state === BluetoothAdapterState.Disabling
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter?.enabled === true || adapter?.state
                                    === BluetoothAdapterState.Enabled || adapter?.state
                                    === BluetoothAdapterState.Enabling
    readonly property var knownDevices: {
        const devices = adapter?.devices.values.filter(device => device.paired || device.bonded)
        ?? [];
        return devices.slice().sort((left, right) => {
            if (left.connected !== right.connected)
                return left.connected ? -1 : 1;
            return root.deviceName(left).localeCompare(root.deviceName(right));
        });
    }
    readonly property string statusText: {
        if (!available)
        return "Unavailable";
        if (!enabled)
        return "Off";

        const connectedDevice = adapter.devices.values.find(device => device.connected);
        return connectedDevice?.name || "On";
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
        let status = "Disconnected";
        if (device?.state === BluetoothDeviceState.Connected)
            status = "Connected";
        else if (device?.state === BluetoothDeviceState.Connecting)
            status = "Connecting…";
        else if (device?.state === BluetoothDeviceState.Disconnecting)
            status = "Disconnecting…";

        if (device?.connected && device?.batteryAvailable)
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
        if (adapter)
            adapter.enabled = enabled;
    }

    function toggleDeviceConnection(device) {
        if (!device || isDeviceTransitioning(device))
            return;
        if (device.connected)
            device.disconnect();
        else
            device.connect();
    }
}
