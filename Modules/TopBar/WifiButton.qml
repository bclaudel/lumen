pragma ComponentBehavior: Bound

import QtQuick

import qs.Common
import qs.Services

TopBarButton {
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

    iconColor: NetworkService.networkStatus !== "disconnected" ? Theme.surfaceText :
                                                                 Theme.outlineButton
    iconName: {
        if (NetworkService.networkStatus === "ethernet")
        return "lan";

        if (NetworkService.networkStatus === "wifi")
        return root.getSignalIcon(NetworkService.wifiSignalStrengthStr);
        return "wifi_off";
    }
}
