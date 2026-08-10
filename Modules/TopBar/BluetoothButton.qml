pragma ComponentBehavior: Bound

import QtQuick

import qs.Common
import qs.Services

TopBarButton {
    iconColor: BluetoothService.enabled ? Theme.surfaceText : Theme.outlineButton
    iconName: BluetoothService.enabled ? "bluetooth" : "bluetooth_disabled"
}
