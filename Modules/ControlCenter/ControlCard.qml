import QtQuick
import QtQuick.Layouts

import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property bool active: false
    property bool available: true
    property string iconName: ""
    property string subtitle: ""
    property string title: ""

    signal openRequested
    signal toggleRequested

    border.color: Theme.withAlpha(Theme.outline, active ? 0.22 : 0.1)
    border.width: 1
    color: active ? Theme.withAlpha(Theme.primary, 0.28) : Theme.withAlpha(Theme.surfaceVariant,
                                                                           0.38)
    implicitHeight: 82
    opacity: available ? 1 : Theme.opacityMedium
    radius: Theme.cornerRadius + 6

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingM

        MaterialButton {
            Layout.alignment: Qt.AlignVCenter
            backgroundColor: root.active ? Theme.primary : Theme.withAlpha(Theme.surfaceText, 0.12)
            buttonSize: 46
            enabled: root.available
            iconColor: root.active ? Theme.primaryText : Theme.surfaceText
            iconName: root.iconName
            iconSize: Theme.iconSize

            onClicked: root.toggleRequested()
        }

        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true

            Column {
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacingS
                anchors.right: chevron.left
                anchors.rightMargin: Theme.spacingXS
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                StyledText {
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.DemiBold
                    text: root.title
                    width: parent.width
                }

                StyledText {
                    color: Theme.surfaceTextMedium
                    font.pixelSize: Theme.fontSizeSmall
                    text: root.available ? root.subtitle : "Unavailable"
                    width: parent.width
                }
            }

            MaterialIcon {
                id: chevron

                anchors.right: parent.right
                anchors.rightMargin: Theme.spacingXS
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.surfaceTextMedium
                name: "chevron_right"
                size: Theme.iconSizeSmall
            }

            StateLayer {
                anchors.fill: parent
                cornerRadius: Theme.cornerRadius
                disabled: !root.available
                stateColor: Theme.surfaceText

                onClicked: root.openRequested()
            }
        }
    }
}
