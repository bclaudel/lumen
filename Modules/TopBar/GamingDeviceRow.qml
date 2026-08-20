pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Common
import qs.Widgets

Rectangle {
    id: root

    required property var device

    Accessible.description: device.connected ? device.batteryAvailable ? "Connected, "
                                                                         + device.batteryLevel
                                                                         + "% battery" :
                                                                         "Connected" :
                                                                         "Disconnected"
    Accessible.name: device.name
    border.color: device.connected ? Theme.primary : "transparent"
    border.width: device.connected ? 1 : 0
    color: device.connected ? Theme.primarySelected : "transparent"
    implicitHeight: 50
    radius: Theme.cornerRadius

    RowLayout {
        anchors.fill: parent
        spacing: Theme.spacingM

        MaterialIcon {
            Layout.leftMargin: Theme.spacingM
            color: root.device.connected ? Theme.primary : Theme.surfaceText
            name: root.device.icon
            size: Theme.iconSize
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            StyledText {
                Layout.fillWidth: true
                color: Theme.surfaceText
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSizeMedium
                font.weight: root.device.connected ? Font.DemiBold : Font.Normal
                text: root.device.name
            }

            StyledText {
                Layout.fillWidth: true
                color: Theme.surfaceTextMedium
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSizeSmall
                text: root.device.connected ? root.device.batteryAvailable ? "Connected · "
                                                                             + root.device.batteryLevel
                                                                             + "%" : "Connected" :
                                                                             "Disconnected"
            }
        }

        Item {
            Layout.rightMargin: Theme.spacingM
            Layout.preferredWidth: Theme.iconSizeSmall
        }
    }
}
