pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Common
import qs.Services
import qs.Widgets

TopBarButton {
    id: root

    function metricText(available, value, unit) {
        return available ? `${Math.round(value)}${unit}` : "--";
    }

    accessibleName: "System performance"
    buttonWidth: metricRow.implicitWidth + 2 * Theme.spacingM

    contentItem: Item {
        RowLayout {
            id: metricRow

            anchors.centerIn: parent
            spacing: Theme.spacingM

            Metric {
                available: SystemPerformanceService.cpuAvailable
                iconName: "memory"
                value: SystemPerformanceService.cpuUsage
            }

            Metric {
                available: SystemPerformanceService.gpuAvailable
                iconName: "developer_board"
                value: SystemPerformanceService.gpuUsage
            }

            Metric {
                available: SystemPerformanceService.memoryAvailable
                iconName: "memory_alt"
                value: SystemPerformanceService.memoryUsage
            }

            Metric {
                available: SystemPerformanceService.psuPowerAvailable
                iconName: "bolt"
                reservedDigits: 3
                unit: " W"
                value: SystemPerformanceService.psuPowerWatts
            }
        }
    }

    component Metric: RowLayout {
        id: metric

        required property bool available
        required property string iconName
        required property real value
        property int reservedDigits: 2
        property string unit: "%"
        readonly property real textWidth: Math.ceil(valueFontMetrics.advanceWidth("0".repeat(
                                                                                      reservedDigits)
                                                                                  + unit))
        readonly property color metricColor: unit === "%" ? Theme.utilizationColor(value,
                                                                                   available) :
                                                            available ? Theme.surfaceText :
                                                                        Theme.surfaceTextMedium

        spacing: 2

        FontMetrics {
            id: valueFontMetrics

            font: metricValue.font
        }

        TightMaterialIcon {
            Layout.preferredHeight: Theme.topBarIconSize
            color: parent.metricColor
            name: parent.iconName
            size: Theme.topBarIconSize
        }

        StyledText {
            id: metricValue

            Layout.minimumWidth: metric.textWidth
            Layout.preferredWidth: metric.textWidth
            Layout.maximumWidth: metric.textWidth
            color: parent.metricColor
            font.pixelSize: Theme.fontSizeSmall
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: Theme.fontSizeSmall - 2
            horizontalAlignment: Text.AlignRight
            wrapMode: Text.NoWrap
            text: root.metricText(parent.available, parent.value, parent.unit)
        }
    }
}
