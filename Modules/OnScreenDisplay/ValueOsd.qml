pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Common
import qs.Widgets

Rectangle {
    id: root

    required property string iconName
    required property real value
    required property string valueText

    readonly property real boundedValue: Math.min(1, Math.max(0, value))

    border.color: Theme.withAlpha(Theme.outline, 0.16)
    border.width: 1
    color: Theme.withAlpha(Theme.surfaceContainer, 0.92)
    implicitHeight: 58
    implicitWidth: 280
    radius: Theme.cornerRadius + 6

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        border.color: Theme.withAlpha(Theme.surfaceText, 0.05)
        border.width: 1
        color: "transparent"
        radius: parent.radius - 1
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingM

        MaterialIcon {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: Theme.iconSize
            Layout.preferredWidth: Theme.iconSize
            color: Theme.surfaceText
            name: root.iconName
            size: Theme.iconSize
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 10
            color: Theme.withAlpha(Theme.surfaceText, 0.11)
            radius: height / 2

            Rectangle {
                color: Theme.primary
                height: parent.height
                radius: parent.radius
                width: root.boundedValue * parent.width
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 36
            color: Theme.surfaceText
            font.pixelSize: Theme.fontSizeSmall
            horizontalAlignment: Text.AlignRight
            text: root.valueText
        }
    }
}
