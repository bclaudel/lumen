pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
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
                                               + (screenshotOptionsOpen ? screenshotOptionsHeight
                                                                          + Theme.spacingM : 0)
    property int controlCenterWidth: 420
    readonly property int maximumControlCenterHeight: baseControlCenterHeight + Theme.spacingM
                                                      + audioDeviceSelectorMaximumHeight
    readonly property int transitionDuration: 160
    property bool isOpen: false
    property int openGeneration: 0
    readonly property var screenshotModes: [
        {
            mode: "screen",
            label: "Screen",
            icon: "desktop_windows"
        },
        {
            mode: "window",
            label: "Window",
            icon: "web_asset"
        },
        {
            mode: "area",
            label: "Area",
            icon: "crop_free"
        }
    ]
    readonly property int screenshotModeRowHeight: 36
    readonly property int screenshotOptionsHeight: 2 * Theme.spacingS + screenshotModes.length
                                                   * screenshotModeRowHeight + (
                                                       screenshotModes.length - 1) * Theme.spacingXS
    property bool screenshotOptionsOpen: false
    property string selectedScreenshotMode: "area"
    property bool selectingInput: false
    property var targetScreen: null

    function closeControlCenter() {
        openGeneration++;
        isOpen = false;
    }

    function takeScreenshot() {
        if (screenshotDelay.running || screenshotCapture.running)
            return;

        screenshotCapture.mode = selectedScreenshotMode;
        screenshotCapture.outputName = targetScreen?.name ?? "";
        closeControlCenter();
        screenshotDelay.restart();
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
            screenshotOptionsOpen = false;
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

        property string mode: ""
        property string outputName: ""

        command: ["sh", Quickshell.shellPath("Scripts/screenshot.sh"), mode, outputName]

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

                        ControlCard {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            actionAccessibleName: "Take screenshot (" + subtitle + ")"
                            actionButtonSize: 42
                            active: root.screenshotOptionsOpen
                            available: !screenshotDelay.running && !screenshotCapture.running
                            expanded: root.screenshotOptionsOpen
                            iconName: "photo_camera"
                            implicitHeight: 68
                            subtitle: root.screenshotModes.find(entry => entry.mode
                                                                         === root.selectedScreenshotMode).label
                            title: "Screenshot"

                            onOpenRequested: {
                                root.audioDeviceSelectorOpen = false;
                                root.screenshotOptionsOpen = !root.screenshotOptionsOpen;
                            }
                            onToggleRequested: root.takeScreenshot()
                        }
                    }

                    ControlCenterSurface {
                        Layout.fillWidth: true
                        implicitHeight: root.screenshotOptionsHeight
                        visible: root.screenshotOptionsOpen

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingS
                            spacing: Theme.spacingXS

                            Repeater {
                                model: root.screenshotModes

                                delegate: Controls.AbstractButton {
                                    id: modeButton

                                    required property var modelData
                                    readonly property bool selected: modelData.mode
                                                                     === root.selectedScreenshotMode

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: root.screenshotModeRowHeight
                                    Accessible.name: modelData.label
                                    Accessible.role: Accessible.RadioButton
                                    Accessible.checked: selected
                                    hoverEnabled: true
                                    leftPadding: Theme.spacingM
                                    rightPadding: Theme.spacingM

                                    background: ControlCenterSurface {
                                        border.color: modeButton.selected ? Theme.primary :
                                                                            "transparent"
                                        color: modeButton.selected ? Theme.primarySelected :
                                                                     "transparent"

                                        StateOverlay {
                                            hovered: modeButton.hovered
                                            pressed: modeButton.down
                                            focused: modeButton.visualFocus
                                        }
                                    }

                                    contentItem: RowLayout {
                                        spacing: Theme.spacingM

                                        MaterialIcon {
                                            name: modeButton.modelData.icon
                                            size: Theme.iconSizeSmall
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: modeButton.modelData.label
                                        }

                                        MaterialIcon {
                                            color: Theme.primary
                                            name: "check"
                                            size: Theme.iconSizeSmall
                                            visible: modeButton.selected
                                        }
                                    }

                                    onClicked: {
                                        root.selectedScreenshotMode = modelData.mode;
                                        root.screenshotOptionsOpen = false;
                                    }
                                }
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
                            root.screenshotOptionsOpen = false;
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
                else if (root.screenshotOptionsOpen)
                    root.screenshotOptionsOpen = false;
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
