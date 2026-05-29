import QtQuick
import Quickshell.Hyprland
import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    id: root

    function getWifiSignalIcon(signalStrength) {
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
    color: {
        const baseColor = controlCenterArea.containsMouse || SessionData.isControlCenterOpen
              ? Theme.primaryPressed : Theme.secondaryHover;
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, baseColor.a
                       * Theme.widgetTransparency);

    }
    height: 30
    radius: Theme.cornerRadius
    width: controlCenterRow.width + 2 * Theme.spacingM

    Row {
        id: controlCenterRow

        anchors.centerIn: parent
        spacing: Theme.spacingM

        MaterialIcon {
            color: Theme.surfaceText
            name: "notifications"
            size: Theme.iconSize - 4
        }

        MaterialIcon {
            color: Theme.surfaceText
            name: "bluetooth"
            size: Theme.iconSize - 4
        }

        MaterialIcon {
            color: NetworkService.networkStatus !== "disconnected" ? Theme.surfaceText :
                                                                     Theme.outlineButton
            name: {
                if (NetworkService.networkStatus === "ethernet")
                    return "lan";

                if (NetworkService.networkStatus === "wifi")
                    return root.getWifiSignalIcon(NetworkService.wifiSignalStrengthStr);
                else
                    return "wifi_off";
            }
            size: Theme.iconSize - 4
        }
    }

    MouseArea {
        id: controlCenterArea

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onClicked: {
            Hyprland.dispatch('hl.dsp.global("quickshell:controlCenterToggle")');
        }
    }
}
