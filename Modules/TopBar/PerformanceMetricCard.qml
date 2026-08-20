pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Common
import qs.Widgets

Rectangle {
    id: root

    required property bool available
    required property var history
    required property string iconName
    required property string title
    required property real usage
    property string leftDetail: ""
    property string rightDetail: ""
    property string temperatureText: ""

    readonly property color metricColor: Theme.utilizationColor(usage, available)

    Accessible.description: available ? `${Math.round(usage)} percent` : "Unavailable"
    Accessible.name: title
    border.color: Theme.outlineStrong
    border.width: 1
    color: Theme.sectionBackground
    implicitHeight: 120
    radius: Theme.cornerRadius

    ColumnLayout {
        anchors.fill: parent
        anchors.bottomMargin: Theme.spacingS
        anchors.leftMargin: Theme.spacingM
        anchors.rightMargin: Theme.spacingM
        anchors.topMargin: Theme.spacingS
        spacing: Theme.spacingXS

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            spacing: Theme.spacingS

            MaterialIcon {
                color: root.metricColor
                name: root.iconName
                size: Theme.iconSize
            }

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
                text: root.temperatureText
                visible: text !== ""
            }

            StyledText {
                Layout.preferredWidth: 42
                color: root.metricColor
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignRight
                text: root.available ? `${Math.round(root.usage)}%` : "--"
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 48

            PerformanceHistoryGraph {
                anchors.fill: parent
                graphColor: root.metricColor
                values: root.history
                visible: root.available
            }

            StyledText {
                anchors.centerIn: parent
                color: Theme.surfaceTextMedium
                font.pixelSize: Theme.fontSizeSmall
                text: "Metrics unavailable"
                visible: !root.available
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 20

            StyledText {
                Layout.fillWidth: true
                color: Theme.surfaceTextMedium
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSizeSmall
                text: root.leftDetail
                wrapMode: Text.NoWrap
            }

            StyledText {
                color: Theme.surfaceTextMedium
                font.pixelSize: Theme.fontSizeSmall
                horizontalAlignment: Text.AlignRight
                text: root.rightDetail
                wrapMode: Text.NoWrap
            }
        }
    }
}
