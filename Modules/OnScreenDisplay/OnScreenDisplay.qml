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
    property bool popupActive: false
    property bool popupShown: false
    property var targetScreen: null
    property int audioGeneration: 0

    readonly property string volumeIcon: {
        if (AudioService.muted)
        return "volume_off";
        if (AudioService.volume < 0.01)
        return "volume_mute";
        if (AudioService.volume < 0.5)
        return "volume_down";
        return "volume_up";
    }

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

    function showVolume() {
        if (suppressed || !audioInitialized || !AudioService.available)
            return;

        const resolvedScreen = ScreenService.resolveScreen(ScreenService.focusedScreen);
        if (!resolvedScreen)
            return;

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

    Component.onCompleted: initializeAudio()

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

        anchors.top: true
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        implicitHeight: 66
        implicitWidth: 280
        screen: root.targetScreen
        visible: root.popupActive

        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.margins.top: Theme.barHeight + SettingsData.hyprlandGapsOut
        WlrLayershell.namespace: "quickshell:volume-osd"

        mask: Region {}

        ValueOsd {
            anchors.horizontalCenter: parent.horizontalCenter
            iconName: root.volumeIcon
            opacity: root.popupShown ? 1 : 0
            value: AudioService.volume
            valueText: Math.round(AudioService.volume * 100) + "%"
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
