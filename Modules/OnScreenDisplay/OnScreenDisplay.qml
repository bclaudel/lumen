pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import Quickshell.Wayland

import qs.Common
import qs.Services

Scope {
    id: root

    property bool suppressed: false
    property bool audioInitialized: false
    property bool brightnessInitialized: false
    property bool popupActive: false
    property bool popupShown: false
    property string indicator: "volume"
    property var targetScreen: null
    property int audioGeneration: 0
    property int brightnessGeneration: 0

    readonly property string indicatorIcon: indicator === "brightness"
                                            ? BrightnessService.brightnessIcon :
                                              AudioService.volumeIcon
    readonly property real indicatorValue: indicator === "brightness" ? BrightnessService.value :
                                                                        AudioService.volume
    readonly property string indicatorValueText: Math.round(indicatorValue * 100) + "%"

    function dismiss() {
        hideTimer.stop();
        popupShown = false;
        if (popupActive)
            closeAnimationTimer.restart();
    }

    function initializeAudio() {
        audioInitialized = false;
        const generation = ++audioGeneration;
        if (!AudioService.available)
            return;

        Qt.callLater(() => {
            if (generation === root.audioGeneration && AudioService.available)
                root.audioInitialized = true;
        });
    }

    function initializeBrightness() {
        brightnessInitialized = false;
        const generation = ++brightnessGeneration;
        if (!BrightnessService.available)
            return;

        Qt.callLater(() => {
            if (generation === root.brightnessGeneration && BrightnessService.available)
                root.brightnessInitialized = true;
        });
    }

    function showBrightness() {
        if (suppressed || !brightnessInitialized || !BrightnessService.available)
            return;

        showIndicator("brightness");
    }

    function showVolume() {
        if (suppressed || !audioInitialized || !AudioService.available)
            return;

        showIndicator("volume");
    }

    function showIndicator(requestedIndicator) {
        const resolvedScreen = ScreenService.resolveScreen(ScreenService.focusedScreen);
        if (!resolvedScreen)
            return;

        indicator = requestedIndicator;
        closeAnimationTimer.stop();
        hideTimer.restart();

        if (targetScreen !== resolvedScreen) {
            popupShown = false;
            popupActive = false;
            targetScreen = resolvedScreen;
            Qt.callLater(() => {
                if (!root.suppressed && ScreenService.isConnected(root.targetScreen)) {
                    root.popupActive = true;
                    Qt.callLater(() => root.popupShown = true);
                }
            });
            return;
        }

        popupActive = true;
        popupShown = true;
    }

    Component.onCompleted: {
        initializeAudio();
        initializeBrightness();
    }

    onSuppressedChanged: {
        if (suppressed)
        dismiss();
    }

    Connections {
        target: AudioService

        function onAvailableChanged() {
            root.initializeAudio();
        }

        function onMutedChanged() {
            root.showVolume();
        }

        function onVolumeChanged() {
            root.showVolume();
        }
    }

    Connections {
        target: BrightnessService

        function onAvailableChanged() {
            root.initializeBrightness();
        }

        function onValueChanged() {
            root.showBrightness();
        }
    }

    Connections {
        target: Quickshell

        function onScreensChanged() {
            if (root.popupActive && !ScreenService.isConnected(root.targetScreen))
                root.dismiss();
        }
    }

    Timer {
        id: hideTimer

        interval: 1000
        repeat: false

        onTriggered: {
            root.popupShown = false;
            closeAnimationTimer.restart();
        }
    }

    Timer {
        id: closeAnimationTimer

        interval: 140
        repeat: false

        onTriggered: root.popupActive = false
    }

    PanelWindow {
        id: popupWindow

        anchors {
            right: true
            top: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Normal
        implicitHeight: 66
        implicitWidth: 280
        screen: root.targetScreen
        visible: root.popupActive

        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.margins.right: SettingsData.hyprlandGapsOut
        WlrLayershell.margins.top: Theme.topBarSurfaceOffset + SettingsData.hyprlandGapsOut
        WlrLayershell.namespace: "quickshell:value-osd"

        mask: Region {}

        ValueOsd {
            anchors.horizontalCenter: parent.horizontalCenter
            iconName: root.indicatorIcon
            opacity: root.popupShown ? Theme.opacityFull : 0
            value: root.indicatorValue
            valueText: root.indicatorValueText
            y: root.popupShown ? 0 : -Theme.spacingS

            Behavior on opacity {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on y {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
