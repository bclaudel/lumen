pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property string statusText: {
        if (!available)
        return "Unavailable";
        if (!enabled)
        return "Off";

        const connectedDevice = adapter.devices.values.find(device => device.connected);
        return connectedDevice?.name || "On";
    }

    function openSettings() {
        Quickshell.execDetached(["blueman-manager"]);
    }

    function setEnabled(enabled) {
        if (adapter)
            adapter.enabled = enabled;
    }
}
