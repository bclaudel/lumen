pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Common
import qs.Services
import qs.Widgets

TopBarPopup {
    id: root

    popupWidth: Math.min(830, (targetScreen?.width ?? 862) - 2 * Theme.spacingL)
    configuredMaximumHeight: 620

    function formatGib(bytes) {
        return `${(bytes / 1073741824).toFixed(1)} GiB`;
    }

    function formatGpuMemory() {
        return "VRAM " + (SystemPerformanceService.gpuMemoryUsedMib / 1024).toFixed(1) + " / " + (
                    SystemPerformanceService.gpuMemoryTotalMib / 1024).toFixed(1) + " GiB";
    }

    function formatGpuPowerAndClock() {
        return Math.round(SystemPerformanceService.gpuPowerWatts) + " W · " + Math.round(
                    SystemPerformanceService.gpuClockMhz) + " MHz";
    }

    function formatMemoryUsage() {
        return formatGib(SystemPerformanceService.memoryUsedBytes) + " / " + formatGib(
                    SystemPerformanceService.memoryTotalBytes);
    }

    function formatTemperature(value) {
        return Math.round(value) + "°C";
    }

    content: Component {
        ColumnLayout {
            spacing: Theme.spacingM
            width: parent.width

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.spacingS
                Layout.preferredHeight: 44
                Layout.rightMargin: Theme.spacingS

                StyledText {
                    Layout.fillWidth: true
                    color: Theme.surfaceText
                    font.family: SettingsData.displayFontFamily
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.DemiBold
                    text: "System Performance"
                }

                StyledText {
                    color: Theme.surfaceTextMedium
                    font.pixelSize: Theme.fontSizeSmall
                    text: "Last 60 seconds"
                    wrapMode: Text.NoWrap
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 3
                columnSpacing: Theme.spacingM
                rowSpacing: Theme.spacingM
                PerformanceMetricCard {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    subtitle: SystemPerformanceService.cpuThreadCount + " logical processors"
                    available: SystemPerformanceService.cpuAvailable
                    history: SystemPerformanceService.cpuHistory
                    iconName: "memory"
                    leftDetail: `Load ${SystemPerformanceService.cpuLoadAverage.toFixed(2)}`
                    rightDetail: `${SystemPerformanceService.cpuThreadCount} threads`
                    temperatureText: SystemPerformanceService.cpuTemperatureAvailable
                                     ? root.formatTemperature(
                                           SystemPerformanceService.cpuTemperature) : ""
                    title: "CPU"
                    usage: SystemPerformanceService.cpuUsage
                }

                PerformanceMetricCard {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    subtitle: SystemPerformanceService.gpuName || "Graphics processor"
                    available: SystemPerformanceService.gpuAvailable
                    history: SystemPerformanceService.gpuHistory
                    iconName: "developer_board"
                    leftDetail: SystemPerformanceService.gpuAvailable ? root.formatGpuMemory() : ""
                    rightDetail: SystemPerformanceService.gpuAvailable ? root.formatGpuPowerAndClock(
                                                                             ) : ""
                    temperatureText: SystemPerformanceService.gpuAvailable ? root.formatTemperature(
                                                                                 SystemPerformanceService.gpuTemperature) :
                                                                             ""
                    title: "GPU"
                    usage: SystemPerformanceService.gpuUsage
                }
                PerformanceMetricCard {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    available: SystemPerformanceService.memoryAvailable
                    subtitle: "System memory"
                    history: SystemPerformanceService.memoryHistory
                    iconName: "memory_alt"
                    leftDetail: SystemPerformanceService.memoryAvailable ? root.formatMemoryUsage() :
                                                                           ""
                    rightDetail: SystemPerformanceService.memoryAvailable
                                 && SystemPerformanceService.swapTotalBytes > 0 ? `Swap ${Math.round(
                                                                                      100 * SystemPerformanceService.swapUsedBytes
                                                                                      / SystemPerformanceService.swapTotalBytes)
                                                                                  }%` : ""
                    title: "Memory"
                    usage: SystemPerformanceService.memoryUsage
                }
            }
        }
    }
}
