pragma ComponentBehavior: Bound

import QtQuick

import qs.Common
import qs.Services
import qs.Widgets

TopBarButton {
    id: root

    accessibleName: GamepadService.statusText
    buttonWidth: indicatorRow.implicitWidth + 2 * Theme.spacingM
    tooltipText: GamepadService.statusText
    visible: GamepadService.connected

    contentItem: Item {
        Row {
            id: indicatorRow

            anchors.centerIn: parent
            spacing: Theme.spacingS

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: "sports_esports"
                size: Theme.topBarIconSize
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.DemiBold
                text: GamepadService.batteryLevel + "%"
            }
        }
    }

    onClicked: GamepadService.refresh()
}
