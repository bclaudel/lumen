import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property bool active: false
    property string iconName: "menu"
    property var screen

    signal clicked

    anchors.verticalCenter: parent.verticalCenter
    color: controlCenterArea.containsMouse || root.active ? Theme.widgetActiveBackground :
                                                            Theme.widgetBackground
    height: Theme.topBarWidgetHeight
    radius: Theme.cornerRadius
    width: controlCenterIcon.width + 2 * Theme.spacingM

    MaterialIcon {
        id: controlCenterIcon

        anchors.centerIn: parent
        color: Theme.surfaceText
        name: root.iconName
        size: Theme.iconSize - 4
    }

    MouseArea {
        id: controlCenterArea

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onClicked: root.clicked()
    }
}
