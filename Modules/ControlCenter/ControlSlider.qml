import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property bool actionEnabled: available
    property string actionIconName: iconName
    property bool actionVisible: false
    property bool available: true
    property string iconName: ""
    property string statusText: ""
    property string title: ""
    property string unavailableText: "Unavailable"
    property real value: 0

    signal actionRequested
    signal valueEdited(real value)

    border.color: Theme.withAlpha(Theme.outline, 0.1)
    border.width: 1
    color: Theme.withAlpha(Theme.surfaceVariant, 0.38)
    implicitHeight: 92
    opacity: available ? 1 : Theme.opacityMedium
    radius: Theme.cornerRadius + 6

    ColumnLayout {
        anchors.fill: parent
        anchors.bottomMargin: Theme.spacingM
        anchors.leftMargin: Theme.spacingM
        anchors.rightMargin: Theme.spacingM
        anchors.topMargin: Theme.spacingS
        spacing: Theme.spacingXS

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingS

            StyledText {
                Layout.fillWidth: true
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.DemiBold
                text: root.title
            }

            StyledText {
                color: Theme.surfaceTextMedium
                font.pixelSize: Theme.fontSizeSmall
                text: root.available ? root.statusText : root.unavailableText
                visible: text !== ""
            }

            MaterialButton {
                Layout.preferredHeight: 26
                Layout.preferredWidth: 26
                buttonSize: 26
                enabled: root.actionEnabled
                iconColor: Theme.surfaceText
                iconName: root.actionIconName
                iconSize: Theme.iconSizeSmall
                visible: root.actionVisible

                onClicked: root.actionRequested()
            }
        }

        Controls.Slider {
            id: slider

            Layout.fillWidth: true
            Layout.preferredHeight: 34
            enabled: root.available
            from: 0
            live: true
            to: 1
            value: root.value

            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + (slider.availableHeight - height) / 2
                implicitHeight: 34
                implicitWidth: 200
                width: slider.availableWidth
                height: implicitHeight
                color: Theme.withAlpha(Theme.surfaceText, 0.11)
                radius: height / 2

                Rectangle {
                    height: parent.height
                    width: slider.visualPosition * parent.width
                    color: Theme.primary
                    radius: parent.radius
                }

                MaterialIcon {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingS
                    anchors.verticalCenter: parent.verticalCenter
                    color: slider.visualPosition > 0.1 ? Theme.primaryText : Theme.surfaceText
                    name: root.iconName
                    size: Theme.iconSizeSmall
                }
            }

            handle: Rectangle {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + (slider.availableHeight - height) / 2
                implicitHeight: 26
                implicitWidth: 3
                color: Theme.primaryText
                opacity: slider.pressed ? 0.9 : 0
                radius: width / 2
            }

            onMoved: root.valueEdited(value)
        }
    }
}
