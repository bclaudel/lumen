pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.SystemTray as TrayService

import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property var screen
    readonly property var trayItems: TrayService.SystemTray.items.values
    readonly property var visibleTrayItems: trayItems.filter(item => item.status
                                                                     !== TrayService.Status.Passive)
    readonly property var inlineItems: visibleTrayItems.filter(item =>
    !SettingsData.isTrayOverflowOnly(item)).slice(0, SettingsData.trayMaxVisibleItems)
    readonly property var overflowItems: visibleTrayItems.filter(item
                                                                 => SettingsData.isTrayOverflowOnly(
                                                                        item) || inlineItems.indexOf(
                                                                        item) === -1)

    signal menuRequested(var trayItem, var anchorItem, var screen)
    signal overflowRequested(var anchorItem, var screen)

    anchors.verticalCenter: parent.verticalCenter
    color: Theme.widgetBackground
    height: Theme.topBarWidgetHeight
    radius: Theme.cornerRadius
    visible: visibleTrayItems.length > 0
    width: visible ? trayRow.width + 2 * Theme.spacingM : 0

    Row {
        id: trayRow

        anchors.centerIn: parent
        spacing: Theme.spacingXS

        Repeater {
            model: root.inlineItems

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
            visible: root.overflowItems.length > 0
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
