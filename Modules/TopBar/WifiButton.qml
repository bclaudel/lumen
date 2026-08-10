pragma ComponentBehavior: Bound

import QtQuick

import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    id: root

    function getSignalIcon(signalStrength) {
        switch (signalStrength) {
        case "excellent":
            return "wifi";
        case "good":
            return "wifi_2_bar";
        case "fair":
            return "wifi_1_bar";
        case "poor":
            return "signal_wifi_0_bar";
        default:
            return "wifi";
        }
    }

    anchors.verticalCenter: parent.verticalCenter
    color: Theme.widgetBackground
    height: Theme.topBarWidgetHeight
    radius: Theme.cornerRadius
    width: Theme.topBarWidgetHeight + Theme.spacingS

    MaterialIcon {
        anchors.centerIn: parent
        color: NetworkService.networkStatus !== "disconnected" ? Theme.surfaceText :
                                                                 Theme.outlineButton
        name: {
            if (NetworkService.networkStatus === "ethernet")
            return "lan";

            if (NetworkService.networkStatus === "wifi")
            return root.getSignalIcon(NetworkService.wifiSignalStrengthStr);
            return "wifi_off";
        }
        size: Theme.iconSize - 4
    }
}
