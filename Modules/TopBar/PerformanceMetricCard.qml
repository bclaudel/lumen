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
    property string extraDetail: ""
    property color accent: Theme.primary
    property string subtitle: ""
    property string leftDetail: ""
    property string rightDetail: ""
    property string temperatureText: ""
    readonly property color metricColor: available && usage >= 75 ? Theme.utilizationColor(usage) :
                                                                    accent

    Accessible.name: title
    Accessible.description: available ? Math.round(usage) + " percent" : "Unavailable"
    border.color: Theme.withAlpha(accent, 0.16)
    border.width: 1
    color: Theme.surfaceContainerHigh
    implicitHeight: 310
    radius: Theme.cornerRadius

    Item {
        anchors.fill: parent
        anchors.margins: Theme.spacingL

        RowLayout {
            id: heading

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 44
            spacing: Theme.spacingS

            MaterialIcon {
                color: root.accent
                name: root.iconName
                size: Theme.iconSize
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    color: root.accent
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.DemiBold
                    text: root.title
                    wrapMode: Text.NoWrap
                }

                StyledText {
                    Layout.fillWidth: true
                    color: Theme.surfaceTextMedium
                    font.pixelSize: Theme.fontSizeSmall
                    text: root.subtitle
                    visible: text !== ""
                    wrapMode: Text.NoWrap
                }
            }

            StyledText {
                color: Theme.surfaceTextMedium
                font.pixelSize: Theme.fontSizeSmall
                text: root.temperatureText
                visible: text !== ""
                wrapMode: Text.NoWrap
            }
        }

        UsageGauge {
            id: gauge

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: heading.bottom
            anchors.topMargin: Theme.spacingS
            width: 112
            height: 112
            accent: root.metricColor
            available: root.available
            caption: "Usage"
            value: root.usage
        }

        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: gauge.bottom
            anchors.topMargin: Theme.spacingS
            spacing: Theme.spacingXS

            StyledText {
                Layout.fillWidth: true
                font.pixelSize: Theme.fontSizeSmall
                text: root.leftDetail
                wrapMode: Text.NoWrap
            }

            StyledText {
                Layout.fillWidth: true
                color: Theme.surfaceTextMedium
                font.pixelSize: Theme.fontSizeSmall
                text: root.rightDetail
                wrapMode: Text.NoWrap
            }

            StyledText {
                Layout.fillWidth: true
                color: Theme.surfaceTextMedium
                font.pixelSize: Theme.fontSizeSmall
                text: root.extraDetail
                visible: text !== ""
                wrapMode: Text.NoWrap
            }
        }

        PerformanceHistoryGraph {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 32
            graphColor: root.accent
            values: root.history
            visible: root.available
        }
    }
}
