pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.Common
import qs.Services
import qs.Widgets

Scope {
    id: root

    property alias isOpen: sessionLoader.active
    property var targetScreen: null

    component DescriptionLabel: Rectangle {
        id: descriptionLabel

        property string text
        property color textColor: Theme.surfaceText

        color: Theme.descriptionBackground
        radius: Theme.cornerRadius
        implicitHeight: descriptionLabelText.implicitHeight + Theme.spacingXL
        implicitWidth: descriptionLabelText.implicitWidth + Theme.spacingXL

        StyledText {
            id: descriptionLabelText

            anchors.centerIn: parent
            color: descriptionLabel.textColor
            text: descriptionLabel.text
        }
    }

    function closeSessionScreen() {
        sessionLoader.active = false;
    }

    function openSessionScreen(requestedScreen) {
        const resolvedScreen = ScreenService.resolveScreen(requestedScreen);
        if (!resolvedScreen)
            return;

        const screenChanged = targetScreen !== resolvedScreen;
        if (screenChanged)
            sessionLoader.active = false;
        targetScreen = resolvedScreen;

        if (screenChanged) {
            Qt.callLater(() => {
                if (ScreenService.isConnected(root.targetScreen))
                    sessionLoader.active = true;
            });
        } else {
            sessionLoader.active = true;
        }
    }

    function toggleSessionScreen(requestedScreen) {
        const resolvedScreen = ScreenService.resolveScreen(requestedScreen);
        if (!resolvedScreen)
            return;

        if (sessionLoader.active && targetScreen === resolvedScreen)
            closeSessionScreen();
        else
            openSessionScreen(resolvedScreen);
    }

    Loader {
        id: sessionLoader

        active: false

        sourceComponent: PanelWindow {
            id: sessionRoot

            property string subtitle

            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:lockScreen"
            color: Theme.modalScrimBackground
            exclusionMode: ExclusionMode.Ignore
            implicitHeight: root.targetScreen?.height ?? 0
            implicitWidth: root.targetScreen?.width ?? 0
            screen: root.targetScreen
            visible: sessionLoader.active

            anchors {
                left: true
                right: true
                top: true
            }

            MouseArea {
                id: sessionMouseArea

                anchors.fill: parent

                onClicked: {
                    root.closeSessionScreen();
                }
            }

            ColumnLayout {
                id: sessionContent

                anchors.centerIn: parent
                spacing: Theme.spacingXL

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.closeSessionScreen();
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 0

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        color: Theme.surfaceText
                        font.family: SettingsData.displayFontFamily
                        font.pixelSize: Theme.fontSizeXXLarge
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        text: "Session"
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeLarge
                        horizontalAlignment: Text.AlignHCenter
                        text: "Arrow keys to navigate, Enter to select\nEsc or click anywhere to cancel"
                    }
                }

                GridLayout {
                    columnSpacing: Theme.spacingL + 4
                    columns: 4
                    rowSpacing: Theme.spacingL + 4

                    SessionButton {
                        id: sessionLock

                        buttonText: "Lock"
                        buttonIcon: "lock"
                        focus: sessionRoot.visible
                        onClicked: {
                            Quickshell.execDetached(["loginctl", "lock-session"]);
                            root.closeSessionScreen();
                        }
                        onFocusChanged: {
                            if (focus)
                            sessionRoot.subtitle = buttonText;
                        }

                        KeyNavigation.down: sessionHibernate
                        KeyNavigation.right: sessionSleep
                    }

                    SessionButton {
                        id: sessionSleep

                        buttonText: "Sleep"
                        buttonIcon: "dark_mode"
                        onClicked: {
                            Quickshell.execDetached(["systemctl", "suspend"]);
                            root.closeSessionScreen();
                        }
                        onFocusChanged: {
                            if (focus)
                            sessionRoot.subtitle = buttonText;
                        }

                        KeyNavigation.down: sessionShutdown
                        KeyNavigation.left: sessionLock
                        KeyNavigation.right: sessionLogout
                    }

                    SessionButton {
                        id: sessionLogout

                        buttonText: "Logout"
                        buttonIcon: "logout"
                        onClicked: {
                            Quickshell.execDetached(["hyprctl", "eval",
                                                     "return hl.dispatch(hl.dsp.exit())"]);
                            root.closeSessionScreen();
                        }
                        onFocusChanged: {
                            if (focus)
                            sessionRoot.subtitle = buttonText;
                        }

                        KeyNavigation.down: sessionReboot
                        KeyNavigation.left: sessionSleep
                        KeyNavigation.right: sessionTaskManager
                    }

                    SessionButton {
                        id: sessionTaskManager

                        buttonText: "Task Manager"
                        buttonIcon: "browse_activity"
                        onClicked: {
                            Quickshell.execDetached(["gnome-system-monitor"]);
                            root.closeSessionScreen();
                        }
                        onFocusChanged: {
                            if (focus)
                            sessionRoot.subtitle = buttonText;
                        }

                        KeyNavigation.down: sessionFirmwareReboot
                        KeyNavigation.left: sessionLogout
                    }

                    SessionButton {
                        id: sessionHibernate

                        buttonText: "Hibernate"
                        buttonIcon: "downloading"
                        onClicked: {
                            Quickshell.execDetached(["systemctl", "hibernate"]);
                            root.closeSessionScreen();
                        }
                        onFocusChanged: {
                            if (focus)
                            sessionRoot.subtitle = buttonText;
                        }

                        KeyNavigation.right: sessionShutdown
                        KeyNavigation.up: sessionLock
                    }

                    SessionButton {
                        id: sessionShutdown

                        buttonText: "Shutdown"
                        buttonIcon: "power_settings_new"
                        onClicked: {
                            Quickshell.execDetached(["systemctl", "poweroff"]);
                            root.closeSessionScreen();
                        }
                        onFocusChanged: {
                            if (focus)
                            sessionRoot.subtitle = buttonText;
                        }

                        KeyNavigation.left: sessionHibernate
                        KeyNavigation.right: sessionReboot
                        KeyNavigation.up: sessionSleep
                    }

                    SessionButton {
                        id: sessionReboot

                        buttonText: "Reboot"
                        buttonIcon: "restart_alt"
                        onClicked: {
                            Quickshell.execDetached(["systemctl", "reboot"]);
                            root.closeSessionScreen();
                        }
                        onFocusChanged: {
                            if (focus)
                            sessionRoot.subtitle = buttonText;
                        }

                        KeyNavigation.left: sessionShutdown
                        KeyNavigation.right: sessionFirmwareReboot
                        KeyNavigation.up: sessionLogout
                    }

                    SessionButton {
                        id: sessionFirmwareReboot

                        buttonText: "Reboot to firmware settings"
                        buttonIcon: "settings_applications"
                        onClicked: {
                            Quickshell.execDetached(["systemctl", "reboot", "--firmware-setup"]);
                            root.closeSessionScreen();
                        }
                        onFocusChanged: {
                            if (focus)
                            sessionRoot.subtitle = buttonText;
                        }

                        KeyNavigation.left: sessionReboot
                        KeyNavigation.up: sessionTaskManager
                    }
                }

                DescriptionLabel {
                    Layout.alignment: Qt.AlignHCenter
                    text: sessionRoot.subtitle
                }
            }
        }
    }

    IpcHandler {
        function close(): void {
            root.closeSessionScreen();
        }

        function open(): void {
            root.openSessionScreen(ScreenService.focusedScreen);
        }

        function toggle(): void {
            root.toggleSessionScreen(ScreenService.focusedScreen);
        }

        target: "session"
    }

    GlobalShortcut {
        description: "Open the session screen"
        name: "sessionScreenOpen"

        onPressed: {
            root.openSessionScreen(ScreenService.focusedScreen);
        }
    }

    GlobalShortcut {
        description: "Close the session screen"
        name: "sessionScreenClose"

        onPressed: {
            root.closeSessionScreen();
        }
    }

    GlobalShortcut {
        description: "Toggle the session screen"
        name: "sessionScreenToggle"

        onPressed: {
            root.toggleSessionScreen(ScreenService.focusedScreen);
        }
    }

    Connections {
        function onScreensChanged() {
            if (sessionLoader.active && !ScreenService.isConnected(root.targetScreen))
                root.closeSessionScreen();
        }

        target: Quickshell
    }
}
