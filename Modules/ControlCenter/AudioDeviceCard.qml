import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import qs.Common
import qs.Widgets

Controls.AbstractButton {
    id: root

    property bool active: false
    property bool available: true
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

        Rectangle {
            anchors.fill: parent
            color: Theme.withAlpha(Theme.surfaceText, root.down ? 0.12 : root.hovered
                                                                  || root.visualFocus ? 0.08 : 0)
            radius: parent.radius
        }
    }

    contentItem: RowLayout {
        spacing: Theme.spacingM

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 46
            Layout.preferredWidth: 46
            color: root.available ? Theme.primary : Theme.withAlpha(Theme.surfaceText, 0.12)
            radius: width / 2

            MaterialIcon {
                anchors.centerIn: parent
                color: root.available ? Theme.primaryText : Theme.surfaceText
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
