import QtQuick
import Quickshell

import qs.Common
import qs.Widgets

PanelWindow {
    id: root

    property real backgroundTransparency: SettingsData.topBarTransparency

    function formatDate(dateTime) {
        return Qt.formatDateTime(dateTime, "ddd MMM d  h:mmAP");
    }

    color: Theme.popupBackground()
    implicitHeight: Theme.barHeight - 4

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

            Workspaces {}
        }

        Row {
            id: rightSection

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            spacing: Theme.spacingXS

            ControlCenterButton {}
        }

        Rectangle {
            anchors.centerIn: parent
            color: Qt.rgba(Theme.secondaryHover.r, Theme.secondaryHover.g, Theme.secondaryHover.b,
                           Theme.secondaryHover.a * Theme.widgetTransparency)
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
