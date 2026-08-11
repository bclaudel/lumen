pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.Common
import qs.Widgets

Variants {
    id: root

    property bool bluetoothPopupOpen: false
    property var bluetoothPopupScreen: null
    property bool controlCenterOpen: false
    property var controlCenterScreen: null
    property bool osdActive: false
    property string osdIcon: ""
    property var osdScreen: null
    property bool wifiPopupOpen: false
    property var wifiPopupScreen: null
    property real backgroundTransparency: SettingsData.topBarTransparency

    signal bluetoothPopupRequested(var anchorItem, var screen)
    signal controlCenterRequested(var screen)
    signal trayMenuRequested(var trayItem, var anchorItem, var screen)
    signal trayOverflowRequested(var anchorItem, var screen)
    signal wifiPopupRequested(var anchorItem, var screen)

    function formatDate(dateTime) {
        return Qt.formatDateTime(dateTime, "ddd MMM d  h:mmAP");
    }

    model: Quickshell.screens

    PanelWindow {
        id: barWindow

        required property var modelData

        color: Theme.topBarBackground(root.backgroundTransparency)
        implicitHeight: Theme.barHeight - 4
        screen: modelData

        anchors {
            left: true
            right: true
            top: true
        }

        Item {
            id: barContent

            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8

            SystemClock {
                id: systemClock

                precision: SystemClock.Minutes
            }

            Row {
                id: leftSection

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                spacing: Theme.spacingXS

                Workspaces {
                    screen: barWindow.modelData
                }
            }

            Row {
                id: rightSection

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                spacing: Theme.spacingXS

                SystemTray {
                    screen: barWindow.modelData

                    onMenuRequested: (trayItem, anchorItem, screen) => {
                        root.trayMenuRequested(trayItem, anchorItem, screen);
                    }
                    onOverflowRequested: (anchorItem, screen) => {
                        root.trayOverflowRequested(anchorItem, screen);
                    }
                }

                WifiButton {
                    id: wifiButton

                    active: root.wifiPopupOpen && root.wifiPopupScreen === barWindow.modelData

                    onClicked: root.wifiPopupRequested(wifiButton, barWindow.modelData)
                }

                BluetoothButton {
                    id: bluetoothButton

                    active: root.bluetoothPopupOpen && root.bluetoothPopupScreen
                            === barWindow.modelData

                    onClicked: root.bluetoothPopupRequested(bluetoothButton, barWindow.modelData)
                }

                ControlCenterButton {
                    active: (root.controlCenterOpen && root.controlCenterScreen
                             === barWindow.modelData) || (root.osdActive && root.osdScreen
                                                          === barWindow.modelData)
                    iconName: root.osdActive && root.osdScreen === barWindow.modelData
                              ? root.osdIcon : "menu"
                    screen: barWindow.modelData

                    onClicked: {
                        root.controlCenterRequested(barWindow.modelData);
                    }
                }
            }

            Rectangle {
                anchors.centerIn: parent
                color: Theme.widgetBackground
                height: Theme.topBarWidgetHeight
                radius: Theme.cornerRadius
                width: dateLabel.implicitWidth + 2 * Theme.spacingM

                StyledText {
                    id: dateLabel

                    anchors.centerIn: parent
                    font.pixelSize: Theme.fontSizeMedium
                    // font.weight: Font.Bold
                    text: root.formatDate(systemClock.date)
                }

                StateLayer {
                    anchors.fill: parent
                    cornerRadius: parent.radius
                    stateColor: Theme.primary
                }
            }
        }
    }
}
