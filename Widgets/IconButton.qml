import QtQuick
import QtQuick.Controls as Controls

import qs.Common
import qs.Widgets

Controls.AbstractButton {
    id: root

    property string accessibleName: iconName
    property color backgroundColor: "transparent"
    property real buttonHeight: buttonSize
    property real buttonRadius: circular ? Math.min(buttonWidth, buttonHeight) / 2 :
                                           Theme.cornerRadius
    property real buttonSize: 32
    property real buttonWidth: buttonSize
    property bool circular: true
    property color iconColor: Theme.surfaceText
    property string iconName: ""
    property real iconSize: Theme.iconSize - 4
    property color stateColor: Theme.primary
    property bool stateLayerEnabled: true
    property string tooltipText: ""

    Accessible.name: accessibleName
    focusPolicy: Qt.StrongFocus
    hoverEnabled: enabled
    implicitHeight: buttonHeight
    implicitWidth: buttonWidth

    background: Rectangle {
        color: root.backgroundColor
        radius: root.buttonRadius

        Rectangle {
            anchors.fill: parent
            color: Theme.withAlpha(root.stateColor, !root.enabled || !root.stateLayerEnabled ? 0 :
                                                                                               root.down
                                                                                               ? 0.12 : root.hovered
                                                                                                 || root.visualFocus
                                                                                                 ? 0.08 : 0)
            radius: parent.radius
        }
    }

    contentItem: MaterialIcon {
        color: root.iconColor
        name: root.iconName
        size: root.iconSize
    }

    StyledToolTip {
        text: root.tooltipText
        visible: root.hovered && text !== ""
    }
}
