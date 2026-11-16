pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.Common
import qs.Services
import qs.Widgets

Variants {
    id: root

    property bool bluetoothPopupOpen: false
    property var bluetoothPopupScreen: null
    property bool calendarPopupOpen: false
    property var calendarPopupScreen: null
    property bool controlCenterOpen: false
    property var controlCenterScreen: null
    property bool gamingPopupOpen: false
    property var gamingPopupScreen: null
    property bool launcherOpen: false
    property var launcherScreen: null
    property bool notificationCenterOpen: false
    property var notificationCenterScreen: null
    property bool osdActive: false
    property string osdIcon: ""
    property var osdScreen: null
    property bool performancePopupOpen: false
    property var performancePopupScreen: null
    property bool wifiPopupOpen: false
    property var wifiPopupScreen: null
    property real backgroundTransparency: SettingsData.topBarTransparency

    signal bluetoothPopupRequested(var anchorItem, var screen)
    signal calendarPopupRequested(var anchorItem, var screen)
    signal controlCenterRequested(var screen)
    signal gamingPopupRequested(var anchorItem, var screen)
    signal launcherRequested(var screen)
    signal notificationCenterRequested(var anchorItem, var screen)
    signal performancePopupRequested(var anchorItem, var screen)
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

        Component.onCompleted: TopBarService.registerWindow(barWindow)
        Component.onDestruction: TopBarService.unregisterWindow(barWindow)

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

                LauncherButton {
                    active: root.launcherOpen && root.launcherScreen === barWindow.modelData

                    onClicked: root.launcherRequested(barWindow.modelData)
                }

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

                SystemPerformanceButton {
                    id: performanceButton

                    active: root.performancePopupOpen && root.performancePopupScreen
                            === barWindow.modelData

                    onClicked: root.performancePopupRequested(performanceButton,
                                                              barWindow.modelData)
                }

                GamingButton {
                    id: gamingButton

                    active: root.gamingPopupOpen && root.gamingPopupScreen === barWindow.modelData

                    onClicked: root.gamingPopupRequested(gamingButton, barWindow.modelData)
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

                TopBarButton {
                    id: notificationButton

                    accessibleName: "Notifications"
                    active: root.notificationCenterOpen && root.notificationCenterScreen
                            === barWindow.modelData

                    contentItem: Item {
                        MaterialIcon {
                            anchors.centerIn: parent
                            name: "notifications"
                            size: Theme.topBarIconSize
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            color: Theme.primary
                            height: 13
                            radius: height / 2
                            visible: NotificationService.unreadCount > 0
                            width: Math.max(13, countLabel.implicitWidth + 6)

                            StyledText {
                                id: countLabel
                                anchors.centerIn: parent
                                color: Theme.primaryText
                                font.pixelSize: 9
                                text: NotificationService.unreadCount > 99 ? "99+" :
                                                                             NotificationService.unreadCount
                            }
                        }
                    }

                    onClicked: root.notificationCenterRequested(notificationButton,
                                                                barWindow.modelData)
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

            TopBarButton {
                id: dateButton

                accessibleName: "Calendar"
                active: root.calendarPopupOpen && root.calendarPopupScreen === barWindow.modelData
                anchors.centerIn: parent
                buttonWidth: dateLabel.implicitWidth + 2 * Theme.spacingM

                contentItem: StyledText {
                    id: dateLabel

                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeMedium
                    text: root.formatDate(systemClock.date)
                    wrapMode: Text.NoWrap
                }

                onClicked: root.calendarPopupRequested(dateButton, barWindow.modelData)
            }
        }
    }
}
