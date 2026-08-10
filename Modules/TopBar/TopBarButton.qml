pragma ComponentBehavior: Bound

import QtQuick

import qs.Common
import qs.Widgets

StyledRect {
    id: root

    property bool active: false
    property color iconColor: Theme.surfaceText
    property string iconName: ""

    signal clicked

    anchors.verticalCenter: parent.verticalCenter
    color: buttonArea.containsMouse || active ? Theme.widgetActiveBackground :
                                                Theme.widgetBackground
    height: Theme.topBarWidgetHeight
    width: buttonIcon.width + 2 * Theme.spacingM

    MaterialIcon {
        id: buttonIcon

        anchors.centerIn: parent
        color: root.iconColor
        name: root.iconName
        size: Theme.iconSize - 4
    }

    MouseArea {
        id: buttonArea

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onClicked: root.clicked()
    }
}
