pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Common
import qs.Services
import qs.Widgets

TopBarButton {
    id: root

    function metricText(available, value) {
        return available ? `${Math.round(value)}%` : "--";
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
        }
    }

    component Metric: RowLayout {
        required property bool available
        required property string iconName
        required property real value

        spacing: 2

        MaterialIcon {
            color: Theme.utilizationColor(parent.value, parent.available)
            name: parent.iconName
            size: Theme.topBarIconSize
        }

        StyledText {
            Layout.preferredWidth: 30
            color: Theme.utilizationColor(parent.value, parent.available)
            font.pixelSize: Theme.fontSizeSmall
            horizontalAlignment: Text.AlignRight
            text: root.metricText(parent.available, parent.value)
        }
    }
}
