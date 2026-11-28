pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import qs.Common
import qs.Widgets

Controls.AbstractButton {
    id: root

    property bool active: false
    property bool available: true
    property bool highlightIcon: available
    property string iconName: ""
    property string subtitle: ""
    property string title: ""

    Accessible.name: title + (subtitle ? ", " + subtitle : "")
    enabled: available
    hoverEnabled: enabled
    implicitHeight: 82
    leftPadding: Theme.spacingM
    opacity: available ? Theme.opacityFull : Theme.opacityUnavailable
    rightPadding: Theme.spacingM

    background: ControlCenterSurface {
        border.color: root.active ? Theme.withAlpha(Theme.primary, 0.5) : Theme.withAlpha(Theme.outline,
                                                                                          root.hovered
                                                                                          || root.visualFocus
                                                                                          ? 0.22 : 0.1)
        color: root.active ? Theme.withAlpha(Theme.primary, 0.2) : Theme.withAlpha(Theme.surfaceVariant,
                                                                                   0.38)

        StateOverlay {
            cornerRadius: Theme.cornerRadius
            hovered: root.hovered
            pressed: root.down
            focused: root.visualFocus
        }
    }

    contentItem: RowLayout {
        spacing: Theme.spacingM

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: Theme.controlCenterButtonSize
            Layout.preferredWidth: Theme.controlCenterButtonSize
            color: root.highlightIcon ? Theme.primary : Theme.withAlpha(Theme.surfaceText, 0.12)
            radius: width / 2

            MaterialIcon {
                anchors.centerIn: parent
                color: root.highlightIcon ? Theme.primaryText : Theme.surfaceText
                name: root.iconName
                size: Theme.iconSize
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.DemiBold
                text: root.title
            }

            StyledText {
                Layout.fillWidth: true
                color: Theme.surfaceTextMedium
                font.pixelSize: Theme.fontSizeSmall
                text: root.available ? root.subtitle : "Unavailable"
            }
        }
    }
}
