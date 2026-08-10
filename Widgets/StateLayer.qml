import QtQuick

import qs.Common

MouseArea {
    id: root

    property real cornerRadius: Theme.cornerRadius
    property color stateColor: Theme.surfaceText

    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    hoverEnabled: true

    Rectangle {
        id: hoverLayer

        anchors.fill: parent
        color: Theme.withAlpha(root.stateColor, root.pressed ? 0.12 : root.containsMouse ? 0.08 : 0)
        radius: root.cornerRadius
    }
}
