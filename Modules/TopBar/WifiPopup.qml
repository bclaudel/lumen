pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.Common
import qs.Services
import qs.Widgets

PanelWindow {
    id: root

    property var anchorItem: null
    property point anchorPosition: Qt.point(0, 0)
    readonly property int maximumPopupHeight: Math.max(240, Math.min(520, (targetScreen?.height
                                                                           ?? 720) - popupTopMargin
                                                                     - Theme.spacingM))
    readonly property int popupHeight: Math.min(maximumPopupHeight, popupColumn.implicitHeight + 2
                                                * Theme.spacingL)
    readonly property int popupRightMargin: Math.max(Theme.spacingXS, Math.min((targetScreen?.width
                                                                                ?? popupWidth)
                                                                               - popupWidth
                                                                               - Theme.spacingXS, (
                                                                                   targetScreen
                                                                                   ?.width ?? 0)
                                                                               - anchorPosition.x - (
                                                                                   anchorItem
                                                                                   ?.width ?? 0)))
    readonly property int popupTopMargin: Theme.barHeight - Theme.spacingL
                                          + SettingsData.hyprlandGapsOut
    readonly property int popupWidth: 340
    property bool otherNetworksExpanded: false
    property bool relocating: false
    property string selectedSsid: ""
    property var targetScreen: null

    function cancelPasswordEntry() {
        const canceledSsid = selectedSsid;
        selectedSsid = "";
        NetworkService.networkSelectionActive = false;
        if (canceledSsid !== "" && NetworkService.lastOperationSsid === canceledSsid)
            NetworkService.connectionError = "";
    }

    function close() {
        relocating = false;
        visible = false;
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

    function open(anchor, requestedScreen) {
        const resolvedScreen = ScreenService.resolveScreen(requestedScreen);
        if (!anchor || !resolvedScreen)
            return;

        const screenChanged = targetScreen !== resolvedScreen;
        relocating = screenChanged;
        if (screenChanged)
            visible = false;
        anchorItem = anchor;
        anchorPosition = anchor.mapToItem(null, 0, 0);
        targetScreen = resolvedScreen;

        if (screenChanged) {
            Qt.callLater(() => {
                if (root.anchorItem && ScreenService.isConnected(root.targetScreen)) {
                    root.visible = true;
                    popupFocus.forceActiveFocus();
                }
                root.relocating = false;
            });
        } else {
            visible = true;
            popupFocus.forceActiveFocus();
        }
    }

    function toggle(anchor, requestedScreen) {
        const resolvedScreen = ScreenService.resolveScreen(requestedScreen);
        if (visible && targetScreen === resolvedScreen)
            close();
        else
            open(anchor, resolvedScreen);
    }

    anchors.right: true
    anchors.top: true
    color: "transparent"
    exclusiveZone: 0
    implicitHeight: maximumPopupHeight
    implicitWidth: popupWidth
    mask: Region {
        item: popupSurface
    }
    screen: targetScreen
    visible: false

    WlrLayershell.margins.right: popupRightMargin
    WlrLayershell.margins.top: popupTopMargin

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

    HyprlandFocusGrab {
        active: root.visible
        windows: [root]

        onCleared: root.close()
    }

    Rectangle {
        id: popupSurface

        anchors.right: parent.right
        anchors.top: parent.top
        border.color: Theme.withAlpha(Theme.outline, 0.16)
        border.width: 1
        clip: true
        color: Theme.withAlpha(Theme.surfaceContainer, 0.9)
        height: root.popupHeight
        radius: Theme.cornerRadius + 12
        width: root.popupWidth

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            border.color: Theme.withAlpha(Theme.surfaceText, 0.05)
            border.width: 1
            color: "transparent"
            radius: parent.radius - 1
        }

        Flickable {
            id: popupFlickable

            anchors.fill: parent
            anchors.margins: Theme.spacingL
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            contentHeight: popupColumn.implicitHeight
            interactive: contentHeight > height

            Controls.ScrollBar.vertical: Controls.ScrollBar {
                minimumSize: height > 0 ? Math.min(1, 24 / height) : 1
                padding: 0
                policy: popupFlickable.contentHeight > popupFlickable.height
                        ? Controls.ScrollBar.AlwaysOn : Controls.ScrollBar.AlwaysOff
                width: 3

                background: Rectangle {
                    color: Theme.outlineStrong
                    implicitWidth: 3
                    radius: width / 2
                }

                contentItem: Rectangle {
                    color: Theme.surfaceTextMedium
                    implicitHeight: 24
                    implicitWidth: 3
                    radius: width / 2
                }
            }

            ColumnLayout {
                id: popupColumn

                spacing: Theme.spacingXS
                width: popupFlickable.width - (popupFlickable.contentHeight > popupFlickable.height
                                               ? Theme.spacingS : 0)

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.spacingS
                    Layout.preferredHeight: 44
                    Layout.rightMargin: Theme.spacingS

                    StyledText {
                        Layout.fillWidth: true
                        color: Theme.surfaceText
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
                    text: NetworkService.scanning ? "Looking for networks…" :
                                                    "No known networks nearby"
                    verticalAlignment: Text.AlignVCenter
                    visible: NetworkService.wifiEnabled && NetworkService.knownNetworks.length === 0
                }

                Controls.AbstractButton {
                    id: otherNetworksButton

                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    enabled: NetworkService.wifiEnabled
                    hoverEnabled: enabled

                    background: Rectangle {
                        color: otherNetworksButton.down ? Theme.surfacePressed :
                                                          otherNetworksButton.hovered
                                                          || otherNetworksButton.visualFocus
                                                          ? Theme.surfaceHover : "transparent"
                        radius: Theme.cornerRadius
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
                            busy: NetworkService.connectingSsid
                                  === otherNetworkDelegate.modelData.ssid
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
                                    NetworkService.connectNetwork(otherNetworkDelegate.modelData,
                                                                  text);
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

                                onClicked: NetworkService.connectNetwork(
                                               otherNetworkDelegate.modelData, passwordField.text)
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
                    text: NetworkService.scanning ? "Looking for networks…" :
                                                    NetworkService.scanError !== ""
                                                    ? NetworkService.scanError :
                                                      "No other networks nearby"
                    verticalAlignment: Text.AlignVCenter
                    visible: root.otherNetworksExpanded && NetworkService.otherNetworks.length === 0
                }

                Controls.AbstractButton {
                    id: settingsButton

                    Accessible.name: "Wi-Fi Settings"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    hoverEnabled: true

                    background: Rectangle {
                        color: settingsButton.down ? Theme.surfacePressed : settingsButton.hovered
                                                     || settingsButton.visualFocus
                                                     ? Theme.surfaceHover : "transparent"
                        radius: Theme.cornerRadius
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

    FocusScope {
        id: popupFocus

        anchors.fill: parent
        focus: root.visible

        Keys.onEscapePressed: root.close()
    }

    Connections {
        function onConnectionFinished(ssid, success, error) {
            if (success)
                root.cancelPasswordEntry();
        }

        target: NetworkService
    }

    Connections {
        function onDestroyed() {
            root.close();
        }

        ignoreUnknownSignals: true
        target: root.anchorItem
    }

    Connections {
        function onScreensChanged() {
            if (root.visible && !ScreenService.isConnected(root.targetScreen))
                root.close();
        }

        target: Quickshell
    }
}
