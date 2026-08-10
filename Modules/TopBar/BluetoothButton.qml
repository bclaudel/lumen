pragma ComponentBehavior: Bound

import QtQuick

import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    anchors.verticalCenter: parent.verticalCenter
    color: Theme.widgetBackground
    height: Theme.topBarWidgetHeight
    radius: Theme.cornerRadius
    width: Theme.topBarWidgetHeight + Theme.spacingS

    MaterialIcon {
        anchors.centerIn: parent
        color: BluetoothService.enabled ? Theme.surfaceText : Theme.outlineButton
        name: BluetoothService.enabled ? "bluetooth" : "bluetooth_disabled"
        size: Theme.iconSize - 4
    }
}
