import QtQuick
import QtQuick.Controls as Controls

import qs.Common

Controls.AbstractButton {
    id: root

    Accessible.name: "Switch"
    Accessible.role: Accessible.CheckBox
    checkable: true
    hoverEnabled: enabled
    implicitHeight: 24
    implicitWidth: 42

    background: Rectangle {
        border.color: root.checked ? Theme.primary : Theme.outlineButton
        border.width: 1
        color: root.checked ? Theme.primary : Theme.withAlpha(Theme.surfaceText, 0.16)
        radius: height / 2

        Rectangle {
            anchors.fill: parent
            color: Theme.withAlpha(Theme.surfaceText, root.down ? 0.12 : root.hovered
                                                                  || root.visualFocus ? 0.08 : 0)
            radius: parent.radius
        }
    }

    contentItem: Item {
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            color: root.checked ? Theme.primaryText : Theme.surfaceText
            height: 18
            radius: width / 2
            width: 18
            x: root.checked ? parent.width - width - 3 : 3

            Behavior on x {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
