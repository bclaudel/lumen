import QtQuick

import qs.Common

Rectangle {
    property real cornerRadius: Theme.cornerRadius
    required property bool hovered
    required property bool pressed
    property bool focused: false
    property real hoverOpacity: 0.12
    property real pressedOpacity: 0.18
    property color stateColor: Theme.surfaceText

    anchors.fill: parent
    color: Theme.withAlpha(stateColor, pressed ? pressedOpacity : hovered || focused ? hoverOpacity :
                                                                                       0)
    radius: cornerRadius
}
