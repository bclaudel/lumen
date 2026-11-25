pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    id: root

    function formatBytes(bytes, suffix) {
        const units = ["B", "KiB", "MiB", "GiB", "TiB"];
        let value = bytes;
        let unit = 0;
        while (value >= 1024 && unit < units.length - 1) {
            value /= 1024;
            unit++;
        }
        const digits = unit === 0 ? 0 : value < 10 ? 1 : 0;
        return value.toFixed(digits) + " " + units[unit] + suffix;
    }

    Accessible.name: "Network"
    Accessible.description: SystemPerformanceService.networkAvailable ? "Download " + formatBytes(
                                                                            SystemPerformanceService.downloadBytesPerSecond,
                                                                            "/s") + ", upload "
                                                                        + formatBytes(
                                                                            SystemPerformanceService.uploadBytesPerSecond,
                                                                            "/s") : "Unavailable"
    border.color: Theme.withAlpha(Theme.primary, 0.16)
    border.width: 1
    color: Theme.surfaceContainerHigh
    implicitHeight: 310
    radius: Theme.cornerRadius

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingL
        spacing: Theme.spacingS

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            spacing: Theme.spacingS

            MaterialIcon {
                color: Theme.primary
                name: "network_check"
                size: Theme.iconSize
            }

            StyledText {
                color: Theme.primary
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.DemiBold
                text: "Network"
            }

            StyledText {
                Layout.fillWidth: true
                color: Theme.surfaceTextMedium
                font.pixelSize: Theme.fontSizeSmall
                horizontalAlignment: Text.AlignRight
                text: SystemPerformanceService.networkDevice || "No active connection"
            }
        }

        ThroughputColumn {
            Layout.fillWidth: true
            Layout.fillHeight: true
            direction: "Download"
            iconName: "download"
            rate: SystemPerformanceService.downloadBytesPerSecond
            total: SystemPerformanceService.receivedBytes
            history: SystemPerformanceService.downloadHistory
        }

        Rectangle {
            Layout.fillWidth: true
            color: Theme.outlineMedium
            implicitHeight: 1
        }

        ThroughputColumn {
            Layout.fillWidth: true
            Layout.fillHeight: true
            direction: "Upload"
            iconName: "upload"
            rate: SystemPerformanceService.uploadBytesPerSecond
            total: SystemPerformanceService.transmittedBytes
            history: SystemPerformanceService.uploadHistory
        }
    }

    component ThroughputColumn: ColumnLayout {
        id: throughputColumn

        required property string direction
        required property string iconName
        required property real rate
        required property real total
        required property var history

        spacing: 2

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingXS

            MaterialIcon {
                color: Theme.primary
                name: throughputColumn.iconName
                size: Theme.iconSizeSmall
            }

            StyledText {
                color: Theme.surfaceTextMedium
                font.pixelSize: Theme.fontSizeSmall
                text: throughputColumn.direction
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.DemiBold
                text: SystemPerformanceService.networkAvailable ? root.formatBytes(
                                                                      throughputColumn.rate, "/s") :
                                                                  "—"
            }
        }

        StyledText {
            Layout.fillWidth: true
            color: Theme.surfaceTextMedium
            font.pixelSize: Theme.fontSizeSmall
            text: SystemPerformanceService.networkDevice ? "Total " + root.formatBytes(
                                                               throughputColumn.total, "") : ""
        }

        PerformanceHistoryGraph {
            Layout.fillWidth: true
            Layout.fillHeight: true
            graphColor: Theme.primary
            values: throughputColumn.history
            valueMaximum: throughputColumn.history.reduce((maximum, value) => Math.max(maximum,
                                                                                       value), 1024)
        }
    }
}
