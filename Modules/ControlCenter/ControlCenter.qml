pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.Common
import qs.Services

PanelWindow {
    id: root

    property int audioDeviceExpansionHeight: 0
    readonly property int audioDeviceSelectorMaximumHeight: 230
    property bool audioDeviceSelectorOpen: false
    readonly property int baseControlCenterHeight: 578
    readonly property int controlCenterHeight: baseControlCenterHeight + audioDeviceExpansionHeight
    property int controlCenterWidth: 420
    readonly property int maximumControlCenterHeight: baseControlCenterHeight + Theme.spacingM
                                                      + audioDeviceSelectorMaximumHeight
    readonly property int transitionDuration: 160
    property bool isOpen: false
    property bool selectingInput: false
    property var targetScreen: null

    function closeControlCenter() {
        isOpen = false;
    }

    function openControlCenter(requestedScreen) {
        const resolvedScreen = ScreenService.resolveScreen(requestedScreen);
        if (!resolvedScreen)
            return;

        const screenChanged = targetScreen !== resolvedScreen;
        if (screenChanged)
            isOpen = false;
        targetScreen = resolvedScreen;
        BrightnessService.setTargetScreen(resolvedScreen);
        NetworkService.refreshNetworkState();

        if (screenChanged) {
            Qt.callLater(() => {
                if (ScreenService.isConnected(root.targetScreen))
                    root.isOpen = true;
            });
        } else {
            isOpen = true;
        }
    }

    function toggleControlCenter(requestedScreen) {
        const resolvedScreen = ScreenService.resolveScreen(requestedScreen);
        if (!resolvedScreen)
            return;

        if (isOpen && targetScreen === resolvedScreen)
            closeControlCenter();
        else
            openControlCenter(resolvedScreen);
    }

    signal launcherRequested(var screen)
    signal sessionRequested(var screen)

    onIsOpenChanged: {
        BrightnessService.monitoring = isOpen;
        if (isOpen) {
            BrightnessService.refreshCurrentValue();
        } else {
            audioDeviceSelectorOpen = false;
        }
    }

    color: "transparent"
    exclusiveZone: 0
    implicitHeight: maximumControlCenterHeight
    implicitWidth: controlCenterWidth
    mask: Region {
        item: controlCenterLoader
    }
    screen: targetScreen
    visible: isOpen

    anchors {
        right: true
        top: true
    }

    WlrLayershell.margins.right: SettingsData.hyprlandGapsOut
    WlrLayershell.margins.top: Theme.barHeight - Theme.spacingL + SettingsData.hyprlandGapsOut

    HyprlandFocusGrab {
        id: grab

        active: root.isOpen
        windows: [root]

        onCleared: () => {
            root.closeControlCenter();
        }
    }

    Loader {
        id: controlCenterLoader

        active: true
        anchors.right: parent.right
        anchors.top: parent.top
        asynchronous: true
        clip: true
        focus: root.isOpen
        height: root.controlCenterHeight
        width: root.controlCenterWidth

        Behavior on height {
            NumberAnimation {
                duration: root.transitionDuration
                easing.type: Easing.OutCubic
            }
        }

        sourceComponent: Component {
            Rectangle {
                id: controlCenterBackground

                border.color: Theme.withAlpha(Theme.outline, 0.16)
                border.width: 1
                color: Theme.withAlpha(Theme.surfaceContainer, 0.9)
                radius: Theme.cornerRadius + 12

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    border.color: Theme.withAlpha(Theme.surfaceText, 0.05)
                    border.width: 1
                    color: "transparent"
                    radius: parent.radius - 1
                }

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingL
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacingL
                    anchors.top: parent.top
                    anchors.topMargin: Theme.spacingL
                    height: implicitHeight
                    spacing: Theme.spacingM

                    ControlCenterHeader {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 58
                        targetScreen: root.targetScreen

                        onSessionRequested: screen => root.sessionRequested(screen)
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 174
                        spacing: Theme.spacingM

                        ColumnLayout {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            spacing: Theme.spacingM

                            ControlCard {
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                active: NetworkService.wifiEnabled
                                iconName: NetworkService.wifiEnabled ? "wifi" : "wifi_off"
                                subtitle: {
                                    if (!NetworkService.wifiEnabled)
                                    return "Off";
                                    if (NetworkService.networkStatus === "wifi"
                                        && NetworkService.wifiSsid)
                                    return NetworkService.wifiSsid;
                                    return "On";
                                }
                                title: "Wi-Fi"

                                onOpenRequested: NetworkService.openWifiSettings()
                                onToggleRequested: NetworkService.setWifiEnabled(
                                                       !NetworkService.wifiEnabled)
                            }

                            ControlCard {
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                active: BluetoothService.enabled
                                available: BluetoothService.available
                                iconName: "bluetooth"
                                subtitle: BluetoothService.statusText
                                title: "Bluetooth"

                                onOpenRequested: BluetoothService.openSettings()
                                onToggleRequested: BluetoothService.setEnabled(
                                                       !BluetoothService.enabled)
                            }
                        }

                        MediaCard {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                        }
                    }

                    ControlSlider {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 92
                        available: BrightnessService.available
                        iconName: "brightness_6"
                        statusText: Math.round(BrightnessService.value * 100) + "%"
                        title: "Display"
                        unavailableText: BrightnessService.detecting ? "Detecting…" : "Unavailable"
                        value: BrightnessService.value

                        onValueEdited: value => BrightnessService.setBrightness(value)
                    }

                    ControlSlider {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 92
                        actionIconName: AudioService.muted ? "volume_off" : "volume_up"
                        actionVisible: true
                        available: AudioService.available
                        iconName: AudioService.muted ? "volume_off" : "volume_up"
                        statusText: AudioService.muted ? "Muted" : Math.round(AudioService.volume
                                                                              * 100) + "%"
                        title: "Sound"
                        value: AudioService.volume

                        onActionRequested: AudioService.toggleMuted()
                        onValueEdited: value => AudioService.setVolume(value)
                    }

                    AudioDeviceRow {
                        id: audioDeviceRow

                        Layout.fillWidth: true
                        Layout.preferredHeight: implicitHeight
                        expanded: root.audioDeviceSelectorOpen
                        maximumSelectorHeight: root.audioDeviceSelectorMaximumHeight
                        panelOpen: root.isOpen
                        selectingInput: root.selectingInput

                        onSelectionRequested: input => {
                            if (root.audioDeviceSelectorOpen && root.selectingInput === input) {
                                root.audioDeviceSelectorOpen = false;
                            } else {
                                root.selectingInput = input;
                                root.audioDeviceSelectorOpen = true;
                            }
                        }

                        onDeviceSelected: root.audioDeviceSelectorOpen = false
                        onExpansionHeightChanged: root.audioDeviceExpansionHeight = expansionHeight
                    }
                }
            }
        }

        Keys.onPressed: event => {
            if (event.key !== Qt.Key_Escape)
                return;

            if (root.audioDeviceSelectorOpen)
                root.audioDeviceSelectorOpen = false;
            else
                root.closeControlCenter();
            event.accepted = true;
        }
    }

    GlobalShortcut {
        description: "Open the control center"
        name: "controlCenterOpen"

        onPressed: {
            root.openControlCenter(ScreenService.focusedScreen);
        }
    }

    GlobalShortcut {
        description: "Close the control center"
        name: "controlCenterClose"

        onPressed: {
            root.closeControlCenter();
        }
    }

    GlobalShortcut {
        description: "Toggle the control center"
        name: "controlCenterToggle"

        onPressed: {
            root.toggleControlCenter(ScreenService.focusedScreen);
        }
    }

    Connections {
        function onScreensChanged() {
            if (root.isOpen && !ScreenService.isConnected(root.targetScreen))
                root.closeControlCenter();
        }

        target: Quickshell
    }
}
