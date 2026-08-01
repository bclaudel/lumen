pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Hyprland

import qs.Common
import qs.Services
import qs.Widgets

PanelWindow {
    id: root

    property int controlCenterWidth: 460
    property bool isOpen: false
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

    color: "transparent"
    exclusiveZone: 0
    implicitWidth: controlCenterWidth
    screen: targetScreen
    visible: isOpen

    anchors {
        bottom: true
        right: true
        top: true
    }

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

        active: root.isOpen
        asynchronous: true
        focus: root.isOpen

        sourceComponent: Component {
            Rectangle {
                id: controlCenterBackground

                anchors.fill: parent
                color: Theme.popupBackground()
                radius: Theme.cornerRadius

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 90

                        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b,
                                              0.08)

                        border.width: 1
                        color: Theme.sectionBackground
                        radius: Theme.cornerRadius

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingL
                            anchors.rightMargin: Theme.spacingL
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingL

                            Item {
                                id: avatarContainer

                                height: 64
                                width: 64

                                Rectangle {
                                    anchors.fill: parent
                                    border.color: Theme.primary
                                    border.width: 1
                                    color: "transparent"
                                    radius: width / 2
                                    visible: true
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.spacingXS

                                StyledText {
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeLarge
                                    font.weight: Font.Medium
                                    text: "Ekko"
                                }

                                StyledText {
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Normal
                                    text: "Unknown"
                                }
                            }
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.spacingL
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingS

                            MaterialButton {
                                buttonSize: 40
                                iconColor: Theme.surfaceText
                                iconName: "restart_alt"
                                iconSize: Theme.iconSize
                            }

                            MaterialButton {
                                buttonSize: 40
                                iconColor: Theme.surfaceText
                                iconName: "settings"
                                iconSize: Theme.iconSize

                                onClicked: {
                                    root.launcherRequested(root.targetScreen);
                                }
                            }

                            MaterialButton {
                                buttonSize: 40
                                iconColor: Theme.surfaceText
                                iconName: "power_settings_new"
                                iconSize: Theme.iconSize

                                onClicked: {
                                    root.sessionRequested(root.targetScreen);
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape)
                root.closeControlCenter();
        }

        anchors {
            bottom: parent.bottom
            bottomMargin: SettingsData.hyprlandGapsOut
            left: parent.left
            leftMargin: SettingsData.hyprlandGapsOut
            right: parent.right
            rightMargin: SettingsData.hyprlandGapsOut
            top: parent.top
            topMargin: SettingsData.hyprlandGapsOut
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
