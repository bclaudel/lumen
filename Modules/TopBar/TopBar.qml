pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.Common
import qs.Widgets

Variants {
    id: root

    property bool controlCenterOpen: false
    property var controlCenterScreen: null
    property real backgroundTransparency: SettingsData.topBarTransparency

    signal controlCenterRequested(var screen)

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

                ControlCenterButton {
                    active: root.controlCenterOpen && root.controlCenterScreen
                            === barWindow.modelData
                    screen: barWindow.modelData

                    onClicked: {
                        root.controlCenterRequested(barWindow.modelData);
                    }
                }
            }

            Rectangle {
                anchors.centerIn: parent
                color: Theme.widgetBackground
                height: 30
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
