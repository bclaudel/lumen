pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import Quickshell

import qs.Common
import qs.Services
import qs.Widgets

TopBarPopup {
    id: root

    content: Component {
        ColumnLayout {
            spacing: Theme.spacingXS
            width: parent.width

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.spacingS
                Layout.preferredHeight: 44
                Layout.rightMargin: Theme.spacingS

                StyledText {
                    Layout.fillWidth: true
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.DemiBold
                    text: "Bluetooth"
                }

                Switch {
                    Accessible.name: "Bluetooth"
                    checked: BluetoothService.enabled
                    enabled: BluetoothService.available && !BluetoothService.adapterTransitioning

                    onClicked: BluetoothService.setEnabled(checked)
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: Theme.spacingL
                Layout.topMargin: Theme.spacingL
                color: Theme.surfaceTextMedium
                font.pixelSize: Theme.fontSizeMedium
                text: BluetoothService.powerStatus()
                visible: !BluetoothService.available || !BluetoothService.enabled
                         || BluetoothService.adapterTransitioning
            }

            Repeater {
                model: ScriptModel {
                    values: BluetoothService.enabled ? BluetoothService.knownDevices : []
                }

                delegate: BluetoothDeviceRow {
                    required property var modelData

                    Layout.fillWidth: true
                    device: modelData
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.spacingM
                Layout.preferredHeight: 44
                color: Theme.surfaceTextMedium
                font.pixelSize: Theme.fontSizeSmall
                text: "No paired devices"
                verticalAlignment: Text.AlignVCenter
                visible: BluetoothService.enabled && BluetoothService.knownDevices.length === 0
            }

            Controls.AbstractButton {
                id: settingsButton

                Accessible.name: "Bluetooth Settings"
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                hoverEnabled: true

                background: Rectangle {
                    color: "transparent"
                    radius: Theme.cornerRadius

                    StateOverlay {
                        hovered: settingsButton.hovered
                        pressed: settingsButton.down
                        focused: settingsButton.visualFocus
                    }
                }

                contentItem: RowLayout {
                    MaterialIcon {
                        Layout.leftMargin: Theme.spacingM
                        name: "settings"
                        size: Theme.iconSize
                    }

                    StyledText {
                        Layout.fillWidth: true
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeMedium
                        text: "Bluetooth Settings…"
                    }

                    MaterialIcon {
                        Layout.rightMargin: Theme.spacingM
                        color: Theme.surfaceTextMedium
                        name: "chevron_right"
                        size: Theme.iconSizeSmall
                    }
                }
            }
        }
    }
}
