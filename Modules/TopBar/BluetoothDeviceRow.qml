pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import qs.Common
import qs.Services
import qs.Widgets

Controls.AbstractButton {
    id: root

    required property var device
    readonly property bool connected: device?.connected ?? false
    readonly property bool transitioning: BluetoothService.isDeviceTransitioning(device)

    Accessible.description: BluetoothService.deviceStatus(device)
    Accessible.name: BluetoothService.deviceName(device)
    enabled: BluetoothService.enabled && !transitioning
    hoverEnabled: enabled
    implicitHeight: 50

    background: Rectangle {
        border.color: root.connected ? Theme.primary : "transparent"
        border.width: root.connected ? 1 : 0
        color: root.connected ? Theme.primarySelected : root.down ? Theme.surfacePressed : root.hovered
                                                                    || root.visualFocus
                                                                    ? Theme.surfaceHover :
                                                                      "transparent"
        radius: Theme.cornerRadius
    }

    contentItem: RowLayout {
        spacing: Theme.spacingM

        MaterialIcon {
            Layout.leftMargin: Theme.spacingM
            color: root.connected ? Theme.primary : Theme.surfaceText
            name: BluetoothService.deviceIcon(root.device)
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
                font.weight: root.connected ? Font.DemiBold : Font.Normal
                text: BluetoothService.deviceName(root.device)
            }

            StyledText {
                Layout.fillWidth: true
                color: Theme.surfaceTextMedium
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSizeSmall
                text: BluetoothService.deviceStatus(root.device)
            }
        }

        Item {
            Layout.rightMargin: Theme.spacingM
            Layout.preferredHeight: Theme.iconSizeSmall
            Layout.preferredWidth: Theme.iconSizeSmall

            MaterialIcon {
                anchors.centerIn: parent
                name: "progress_activity"
                rotation: 0
                size: Theme.iconSizeSmall
                visible: root.transitioning

                RotationAnimation on rotation {
                    duration: 900
                    from: 0
                    loops: Animation.Infinite
                    running: root.transitioning
                    to: 360
                }
            }
        }
    }

    onClicked: BluetoothService.toggleDeviceConnection(device)
}
