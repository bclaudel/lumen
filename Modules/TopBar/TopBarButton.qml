pragma ComponentBehavior: Bound

import qs.Common
import qs.Widgets

IconButton {
    id: root

    property bool active: false

    anchors.verticalCenter: parent.verticalCenter
    backgroundColor: hovered || active ? Theme.widgetActiveBackground : Theme.widgetBackground
    buttonHeight: Theme.topBarWidgetHeight
    buttonWidth: iconSize + 2 * Theme.spacingM
    circular: false
    iconSize: Theme.topBarIconSize
    stateLayerEnabled: false
}
