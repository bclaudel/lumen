pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls

import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.Common
import qs.Services

PanelWindow {
    id: root

    property var anchorItem: null
    property point anchorPosition: Qt.point(0, 0)
    property alias content: contentLoader.sourceComponent
    readonly property int maximumPopupHeight: Math.max(240, Math.min(configuredMaximumHeight, (
                                                                         targetScreen?.height
                                                                         ?? 720) - popupTopMargin
                                                                     - Theme.spacingM))
    property int configuredMaximumHeight: 520
    readonly property int popupHeight: Math.min(maximumPopupHeight, contentLoader.implicitHeight
                                                + 2 * Theme.spacingL)
    readonly property int popupRightMargin: Math.max(Theme.spacingXS, Math.min((targetScreen?.width
                                                                                ?? popupWidth)
                                                                               - popupWidth
                                                                               - Theme.spacingXS, (
                                                                                   targetScreen
                                                                                   ?.width ?? 0)
                                                                               - anchorPosition.x - (
                                                                                   anchorItem
                                                                                   ?.width ?? 0)))
    readonly property int popupTopMargin: Theme.topBarSurfaceOffset + SettingsData.hyprlandGapsOut
    property int popupWidth: 340
    property bool relocating: false
    property var targetScreen: null

    function close() {
        relocating = false;
        visible = false;
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

    HyprlandFocusGrab {
        active: root.visible
        windows: [root].concat(TopBarService.windows)

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
        radius: Theme.cornerRadius
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
            contentHeight: contentLoader.implicitHeight
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

            Loader {
                id: contentLoader

                asynchronous: false
                width: popupFlickable.width - (popupFlickable.contentHeight > popupFlickable.height
                                               ? Theme.spacingS : 0)
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
