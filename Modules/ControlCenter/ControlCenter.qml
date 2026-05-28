import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Hyprland

import qs.Common
import qs.Widgets

PanelWindow {
    id: root

    property int controlCenterWidth: 460

    function closeControlCenter() {
        SessionData.isControlCenterOpen = false;
    }

    function openControlCenter() {
        SessionData.isControlCenterOpen = true;
    }

    function toggleControlCenter() {
        SessionData.isControlCenterOpen = !SessionData.isControlCenterOpen;
    }

    color: "transparent"
    exclusiveZone: 0
    implicitWidth: controlCenterWidth
    visible: SessionData.isControlCenterOpen

    anchors {
        bottom: true
        right: true
        top: true
    }

    HyprlandFocusGrab {
        id: grab

        active: SessionData.isControlCenterOpen
        windows: [root]

        onCleared: () => {
                       closeControlCenter();
                   }
    }

    Loader {
        id: controlCenterLoader

        active: SessionData.isControlCenterOpen
        asynchronous: true
        focus: SessionData.isControlCenterOpen

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

                    Column {
                        spacing: Theme.spacingM
                        width: parent.width

                        Rectangle {
                            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b,
                                                  0.08)
                            border.width: 1
                            color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g,
                                           Theme.surfaceVariant.b, Theme.getContentBackgroundAlpha(
                                               ) * 0.4)
                            height: 90
                            radius: Theme.cornerRadius
                            width: parent.width

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
                                        Hyprland.dispatch('hl.dsp.global("quickshell:openLauncherModal")');
                                    }
                                }

                                MaterialButton {
                                    buttonSize: 40
                                    iconColor: Theme.surfaceText
                                    iconName: "power_settings_new"
                                    iconSize: Theme.iconSize

                                    onClicked: {
                                        Hyprland.dispatch('hl.dsp.global("quickshell:sessionScreenOpen")');
                                    }
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
            root.openControlCenter();
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
            root.toggleControlCenter();
        }
    }
}
