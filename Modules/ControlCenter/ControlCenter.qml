pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

import qs.Common
import qs.Services
import qs.Widgets

PanelWindow {
    id: root

    property int audioDeviceExpansionHeight: 0
    readonly property int audioDeviceSelectorMaximumHeight: 230
    property bool audioDeviceSelectorOpen: false
    readonly property int baseControlCenterHeight: 578 + 68 + Theme.spacingM
    readonly property int controlCenterHeight: baseControlCenterHeight + audioDeviceExpansionHeight
    property int controlCenterWidth: 420
    readonly property int maximumControlCenterHeight: baseControlCenterHeight + Theme.spacingM
                                                      + audioDeviceSelectorMaximumHeight
    readonly property int transitionDuration: 160
    property bool isOpen: false
    property int openGeneration: 0
    property bool selectingInput: false
    property var targetScreen: null

    function closeControlCenter() {
        openGeneration++;
        isOpen = false;
    }

    function openControlCenter(requestedScreen) {
        const resolvedScreen = ScreenService.resolveScreen(requestedScreen);
        if (!resolvedScreen)
            return;

        const generation = ++openGeneration;
        const screenChanged = targetScreen !== resolvedScreen;
        if (screenChanged)
            isOpen = false;
        targetScreen = resolvedScreen;
        BrightnessService.setTargetScreen(resolvedScreen);
        NetworkService.refreshNetworkState();
        BluetoothService.refreshConnectionState();
        SleepInhibitService.refresh();

        if (screenChanged) {
            Qt.callLater(() => {
                if (generation !== root.openGeneration)
                    return;
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
    WlrLayershell.margins.top: Theme.topBarSurfaceOffset + SettingsData.hyprlandGapsOut
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    HyprlandFocusGrab {
        id: grab

        active: root.isOpen
        windows: [root].concat(TopBarService.windows)

        onCleared: () => {
            root.closeControlCenter();
        }
    }

    Timer {
        id: screenshotDelay

        interval: root.transitionDuration
        onTriggered: screenshotCapture.running = true
    }

    Process {
        id: screenshotCapture

        // Slurp reads predefined regions from stdin before opening the selector.
        command: ["sh", "-c", `
            region=$(slurp -d </dev/null) || exit 0
            [ -n "$region" ] || exit 0

            pictures=$(xdg-user-dir PICTURES 2>/dev/null)
            [ -n "$pictures" ] || pictures="$HOME/Pictures"
            directory="$pictures/Screenshots"
            file="$directory/Screenshot-$(date +%Y-%m-%d_%H-%M-%S-%N).png"
            if ! mkdir -p "$directory" || ! grim -g "$region" "$file"; then
                notify-send -a Lumen "Screenshot failed" "Could not save the selected area."
                exit 1
            fi

            if wl-copy --type image/png < "$file"; then
                notify-send -a Lumen "Screenshot saved and copied" "$file"
            else
                notify-send -a Lumen "Screenshot saved" "$file"
            fi
        `]

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    console.warn("Screenshot capture:", text.trim());
            }
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
                radius: Theme.cornerRadius

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

                                onOpenRequested: {
                                    NetworkService.openWifiSettings();
                                    root.closeControlCenter();
                                }
                                onToggleRequested: {
                                    NetworkService.setWifiEnabled(!NetworkService.wifiEnabled);
                                    root.closeControlCenter();
                                }
                            }

                            ControlCard {
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                active: BluetoothService.enabled
                                available: BluetoothService.available
                                iconName: "bluetooth"
                                subtitle: BluetoothService.statusText
                                title: "Bluetooth"

                                onOpenRequested: {
                                    BluetoothService.openSettings();
                                    root.closeControlCenter();
                                }
                                onToggleRequested: {
                                    BluetoothService.setEnabled(!BluetoothService.enabled);
                                    root.closeControlCenter();
                                }
                            }
                        }

                        MediaCard {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingM

                        SleepInhibitCard {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                        }

                        IconButton {
                            id: screenshotButton

                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            accessibleName: "Take Screenshot"
                            backgroundColor: Theme.withAlpha(Theme.surfaceVariant, 0.38)
                            circular: false
                            enabled: !screenshotDelay.running && !screenshotCapture.running
                            iconName: "photo_camera"
                            stateColor: Theme.surfaceText

                            contentItem: RowLayout {
                                anchors.fill: parent
                                anchors.margins: Theme.spacingM
                                spacing: Theme.spacingM

                                Rectangle {
                                    Layout.preferredHeight: 42
                                    Layout.preferredWidth: 42
                                    color: Theme.withAlpha(Theme.surfaceText, 0.12)
                                    radius: height / 2

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        name: screenshotButton.iconName
                                        size: Theme.iconSize
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    StyledText {
                                        Layout.fillWidth: true
                                        font.pixelSize: Theme.fontSizeMedium
                                        font.weight: Font.DemiBold
                                        text: "Screenshot"
                                        wrapMode: Text.NoWrap
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        color: Theme.surfaceTextMedium
                                        font.pixelSize: Theme.fontSizeSmall
                                        text: "Select an area"
                                        wrapMode: Text.NoWrap
                                    }
                                }
                            }

                            onClicked: {
                                root.closeControlCenter();
                                screenshotDelay.restart();
                            }
                        }
                    }

                    ControlSlider {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 92
                        actionEnabled: false
                        actionIconName: BrightnessService.brightnessIcon
                        actionVisible: true
                        available: BrightnessService.available
                        iconName: BrightnessService.brightnessIcon
                        statusText: Math.round(BrightnessService.value * 100) + "%"
                        title: "Display"
                        unavailableText: BrightnessService.detecting ? "Detecting…" : "Unavailable"
                        value: BrightnessService.value

                        onValueEdited: value => BrightnessService.setBrightness(value)
                    }

                    ControlSlider {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 92
                        actionIconName: AudioService.volumeIcon
                        actionVisible: true
                        available: AudioService.available
                        iconName: AudioService.volumeIcon
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

        Shortcut {
            sequence: "Escape"
            context: Qt.WindowShortcut
            enabled: root.isOpen

            onActivated: {
                if (root.audioDeviceSelectorOpen)
                    root.audioDeviceSelectorOpen = false;
                else
                    root.closeControlCenter();
            }
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
