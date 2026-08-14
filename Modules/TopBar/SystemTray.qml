pragma ComponentBehavior: Bound

import QtQuick

import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    id: root

    property var screen

    signal menuRequested(var trayItem, var anchorItem, var screen)
    signal overflowRequested(var anchorItem, var screen)

    anchors.verticalCenter: parent.verticalCenter
    color: Theme.widgetBackground
    height: Theme.topBarWidgetHeight
    radius: Theme.cornerRadius
    visible: SystemTrayService.visibleItems.length > 0
    width: visible ? trayRow.width + 2 * Theme.spacingM : 0

    Row {
        id: trayRow

        anchors.centerIn: parent
        spacing: Theme.topBarTrayItemSpacing

        Repeater {
            model: SystemTrayService.inlineItems

            TrayItem {
                required property var modelData

                trayItem: modelData

                onMenuRequested: (trayItem, anchorItem) => {
                    root.menuRequested(trayItem, anchorItem, root.screen);
                }
            }
        }

        Item {
            id: overflowButton

            height: Theme.topBarWidgetHeight
            visible: SystemTrayService.overflowItems.length > 0
            width: visible ? Theme.topBarIconSize : 0

            MaterialIcon {
                anchors.centerIn: parent
                name: "expand_more"
                size: Theme.topBarIconSize
            }

            StateLayer {
                id: overflowArea

                cornerRadius: Theme.cornerRadius
                stateColor: Theme.primary

                onClicked: {
                    root.overflowRequested(root, root.screen);
                }
            }
        }
    }
}
