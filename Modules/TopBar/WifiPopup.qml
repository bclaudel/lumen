pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import Quickshell

import qs.Common
import qs.Services
import qs.Widgets

TopBarPopup {
    id: root

    property bool otherNetworksExpanded: false
    property string selectedSsid: ""

    function cancelPasswordEntry() {
        const canceledSsid = selectedSsid;
        selectedSsid = "";
        NetworkService.networkSelectionActive = false;
        if (canceledSsid !== "" && NetworkService.lastOperationSsid === canceledSsid)
            NetworkService.connectionError = "";
    }

    function connectionErrorFor(ssid) {
        return NetworkService.lastOperationSsid === ssid ? NetworkService.connectionError : "";
    }

    function handleNetwork(network) {
        NetworkService.connectionError = "";
        if (network.active) {
            cancelPasswordEntry();
            NetworkService.disconnectActiveNetwork();
        } else if (network.known) {
            cancelPasswordEntry();
            NetworkService.connectKnownNetwork(network);
        } else if (!network.secured) {
            cancelPasswordEntry();
            NetworkService.connectNetwork(network, "");
        } else if (!network.enterprise) {
            selectedSsid = network.ssid;
            NetworkService.networkSelectionActive = true;
        }
    }

    onVisibleChanged: {
        NetworkService.wifiPopupOpen = visible;
        if (visible) {
            otherNetworksExpanded = false;
            cancelPasswordEntry();
        } else if (!relocating) {
            otherNetworksExpanded = false;
            cancelPasswordEntry();
            NetworkService.connectionError = "";
        }
    }

    Connections {
        function onConnectionFinished(ssid, success, error) {
            if (success)
                root.cancelPasswordEntry();
        }

        target: NetworkService
    }

    content: Component {
        ColumnLayout {
            id: popupColumn

            spacing: Theme.spacingXS
            width: parent.width

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.spacingS
                Layout.preferredHeight: 44
                Layout.rightMargin: Theme.spacingS

                StyledText {
                    Layout.fillWidth: true
                    color: Theme.surfaceText
                    font.family: SettingsData.displayFontFamily
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.DemiBold
                    text: "Wi-Fi"
                }

                Switch {
                    Accessible.name: "Wi-Fi"
                    checked: NetworkService.wifiEnabled

                    onClicked: NetworkService.setWifiEnabled(checked)
                }
            }

            HorizontalSeparator {}

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: Theme.spacingL
                Layout.topMargin: Theme.spacingL
                color: Theme.surfaceTextMedium
                font.pixelSize: Theme.fontSizeMedium
                text: "Wi-Fi is off"
                visible: !NetworkService.wifiEnabled
            }

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.spacingM
                Layout.preferredHeight: 30
                color: Theme.surfaceTextMedium
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.DemiBold
                text: "KNOWN NETWORKS"
                verticalAlignment: Text.AlignVCenter
                visible: NetworkService.wifiEnabled
            }

            Repeater {
                model: ScriptModel {
                    values: NetworkService.knownNetworks
                }

                delegate: WifiNetworkRow {
                    required property var modelData

                    Layout.fillWidth: true
                    busy: NetworkService.connectingSsid === modelData.ssid
                    errorText: root.connectionErrorFor(modelData.ssid)
                    network: modelData

                    onActivated: network => root.handleNetwork(network)
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.spacingM
                Layout.preferredHeight: 38
                color: Theme.surfaceTextMedium
                font.pixelSize: Theme.fontSizeSmall
                text: NetworkService.scanning ? "Looking for networks…" : "No known networks nearby"
                verticalAlignment: Text.AlignVCenter
                visible: NetworkService.wifiEnabled && NetworkService.knownNetworks.length === 0
            }

            HorizontalSeparator {
                visible: NetworkService.wifiEnabled
            }

            Controls.AbstractButton {
                id: otherNetworksButton

                Layout.fillWidth: true
                Layout.preferredHeight: 30
                enabled: NetworkService.wifiEnabled
                hoverEnabled: enabled

                background: Rectangle {
                    color: "transparent"
                    radius: Theme.cornerRadius

                    StateOverlay {
                        hovered: otherNetworksButton.hovered
                        pressed: otherNetworksButton.down
                        focused: otherNetworksButton.visualFocus
                    }
                }

                contentItem: RowLayout {
                    StyledText {
                        Layout.fillWidth: true
                        Layout.leftMargin: Theme.spacingM
                        color: Theme.surfaceTextMedium
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.DemiBold
                        text: "OTHER NETWORKS"
                    }

                    MaterialIcon {
                        Layout.rightMargin: Theme.spacingM
                        color: Theme.surfaceTextMedium
                        name: "expand_more"
                        rotation: root.otherNetworksExpanded ? 180 : 0
                        size: Theme.iconSizeSmall

                        Behavior on rotation {
                            NumberAnimation {
                                duration: 140
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                onClicked: {
                    root.otherNetworksExpanded = !root.otherNetworksExpanded;
                    if (root.otherNetworksExpanded)
                    NetworkService.refreshWifiNetworks(true);
                    else
                    root.cancelPasswordEntry();
                }
            }

            Repeater {
                model: ScriptModel {
                    values: root.otherNetworksExpanded ? NetworkService.otherNetworks : []
                }

                delegate: ColumnLayout {
                    id: otherNetworkDelegate

                    required property var modelData

                    Layout.fillWidth: true
                    spacing: Theme.spacingXS

                    WifiNetworkRow {
                        Layout.fillWidth: true
                        busy: NetworkService.connectingSsid === otherNetworkDelegate.modelData.ssid
                        errorText: root.connectionErrorFor(otherNetworkDelegate.modelData.ssid)
                        network: otherNetworkDelegate.modelData

                        onActivated: network => root.handleNetwork(network)
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: Theme.spacingM
                        Layout.rightMargin: Theme.spacingM
                        spacing: Theme.spacingS
                        visible: root.selectedSsid === otherNetworkDelegate.modelData.ssid

                        TextField {
                            id: passwordField

                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            bottomPadding: Theme.spacingS
                            echoMode: TextInput.Password
                            iconName: "key"
                            placeholderText: "Password"
                            topPadding: Theme.spacingS

                            onVisibleChanged: {
                                if (visible)
                                Qt.callLater(() => forceActiveFocus());
                            }
                            onAccepted: {
                                if (text !== "")
                                NetworkService.connectNetwork(otherNetworkDelegate.modelData, text);
                            }
                        }

                        IconButton {
                            accessibleName: "Cancel"
                            buttonSize: 36
                            iconName: "close"
                            iconSize: Theme.iconSizeSmall

                            onClicked: root.cancelPasswordEntry()
                        }

                        IconButton {
                            accessibleName: "Connect"
                            backgroundColor: Theme.primary
                            buttonSize: 36
                            enabled: passwordField.text !== ""
                            iconColor: Theme.primaryText
                            iconName: "arrow_forward"
                            iconSize: Theme.iconSizeSmall

                            onClicked: NetworkService.connectNetwork(otherNetworkDelegate.modelData,
                                                                     passwordField.text)
                        }
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.spacingM
                Layout.preferredHeight: 38
                color: Theme.surfaceTextMedium
                font.pixelSize: Theme.fontSizeSmall
                text: NetworkService.scanning ? "Looking for networks…" : NetworkService.scanError
                                                !== "" ? NetworkService.scanError :
                                                         "No other networks nearby"
                verticalAlignment: Text.AlignVCenter
                visible: root.otherNetworksExpanded && NetworkService.otherNetworks.length === 0
            }

            HorizontalSeparator {}

            Controls.AbstractButton {
                id: settingsButton

                Accessible.name: "Wi-Fi Settings"
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                hoverEnabled: true

                background: Rectangle {
                    color: "transparent"
                    radius: Theme.cornerRadius

                    StateOverlay {
                        hovered: settingsButton.hovered
                        pressed: settingsButton.down
                        focused: settingsButton.visualFocus
                    }
                }

                contentItem: RowLayout {
                    MaterialIcon {
                        Layout.leftMargin: Theme.spacingM
                        name: "settings"
                        size: Theme.iconSize
                    }

                    StyledText {
                        Layout.fillWidth: true
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeMedium
                        text: "Wi-Fi Settings…"
                    }

                    MaterialIcon {
                        Layout.rightMargin: Theme.spacingM
                        color: Theme.surfaceTextMedium
                        name: "chevron_right"
                        size: Theme.iconSizeSmall
                    }
                }
            }
        }
    }
}
