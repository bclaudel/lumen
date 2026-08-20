pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import qs.Common
import qs.Widgets

Controls.AbstractButton {
    id: root

    required property bool active
    required property bool busy
    required property bool interactionBlocked
    required property string profileName

    signal activated(string profileName)

    Accessible.description: active ? "Active GPU profile" : "GPU profile"
    Accessible.name: profileName
    enabled: !interactionBlocked
    hoverEnabled: enabled
    implicitHeight: 46

    background: Rectangle {
        border.color: root.active ? Theme.primary : "transparent"
        border.width: root.active ? 1 : 0
        color: root.active ? Theme.primarySelected : "transparent"
        radius: Theme.cornerRadius

        StateOverlay {
            hovered: root.hovered
            pressed: root.down
            focused: root.visualFocus
        }
    }

    contentItem: RowLayout {
        spacing: Theme.spacingM

        MaterialIcon {
            Layout.leftMargin: Theme.spacingM
            color: root.active ? Theme.primary : Theme.surfaceText
            name: "speed"
            size: Theme.iconSize
        }

        StyledText {
            Layout.fillWidth: true
            color: Theme.surfaceText
            elide: Text.ElideRight
            font.pixelSize: Theme.fontSizeMedium
            font.weight: root.active ? Font.DemiBold : Font.Normal
            text: root.profileName
        }

        Item {
            Layout.rightMargin: Theme.spacingM
            Layout.preferredHeight: Theme.iconSizeSmall
            Layout.preferredWidth: Theme.iconSizeSmall

            MaterialIcon {
                anchors.centerIn: parent
                color: Theme.primary
                name: "check"
                size: Theme.iconSizeSmall
                visible: root.active && !root.busy
            }

            MaterialIcon {
                anchors.centerIn: parent
                name: "progress_activity"
                rotation: 0
                size: Theme.iconSizeSmall
                visible: root.busy

                RotationAnimation on rotation {
                    duration: 900
                    from: 0
                    loops: Animation.Infinite
                    running: root.busy
                    to: 360
                }
            }
        }
    }

    onClicked: root.activated(profileName)
}
