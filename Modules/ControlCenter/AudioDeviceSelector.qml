pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import Quickshell

import qs.Common
import qs.Services
import qs.Widgets

ControlCenterSurface {
    id: root

    readonly property int delegateHeight: 52
    readonly property int headerHeight: 36
    property int maximumHeight: 230
    property bool selectingInput: false
    readonly property var selectedDevice: selectingInput ? AudioService.source : AudioService.sink
    readonly property var selectedDevices: selectingInput ? AudioService.inputDevices :
                                                            AudioService.outputDevices

    signal deviceSelected

    implicitHeight: Math.min(maximumHeight, Theme.spacingS * 2 + headerHeight + Theme.spacingXS
                             + selectedDevices.length * delegateHeight + Math.max(0,
                                                                                  selectedDevices.length
                                                                                  - 1) * Theme.spacingXS)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingS
        spacing: Theme.spacingXS

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spacingS
            Layout.preferredHeight: root.headerHeight
            color: Theme.surfaceText
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.DemiBold
            text: root.selectingInput ? "Input devices" : "Output devices"
        }

        ListView {
            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true
            model: ScriptModel {
                values: root.selectedDevices
            }
            spacing: Theme.spacingXS

            delegate: Controls.AbstractButton {
                id: deviceDelegate

                required property var modelData

                Accessible.name: AudioService.deviceDisplayName(modelData)
                height: root.delegateHeight
                hoverEnabled: true
                width: ListView.view.width

                background: Rectangle {
                    border.color: deviceDelegate.modelData === root.selectedDevice ? Theme.primary :
                                                                                     "transparent"
                    border.width: deviceDelegate.modelData === root.selectedDevice ? 1 : 0
                    color: deviceDelegate.modelData === root.selectedDevice ? Theme.primarySelected :
                                                                              deviceDelegate.down
                                                                              ? Theme.surfacePressed :
                                                                                deviceDelegate.hovered
                                                                                || deviceDelegate.visualFocus
                                                                                ? Theme.surfaceHover :
                                                                                  "transparent"
                    radius: Theme.cornerRadius
                }

                contentItem: RowLayout {
                    spacing: Theme.spacingM

                    Rectangle {
                        Layout.leftMargin: Theme.spacingS
                        Layout.preferredHeight: 36
                        Layout.preferredWidth: 36
                        color: deviceDelegate.modelData === root.selectedDevice ? Theme.primary :
                                                                                  Theme.withAlpha(
                                                                                      Theme.surfaceText,
                                                                                      0.12)
                        radius: width / 2

                        MaterialIcon {
                            anchors.centerIn: parent
                            color: deviceDelegate.modelData === root.selectedDevice
                                   ? Theme.primaryText : Theme.surfaceText
                            name: root.selectingInput ? "mic" : "speaker"
                            size: Theme.iconSize - 4
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeMedium
                        text: AudioService.deviceDisplayName(deviceDelegate.modelData)
                    }

                    MaterialIcon {
                        Layout.rightMargin: Theme.spacingM
                        color: Theme.primary
                        name: "check"
                        size: Theme.iconSizeSmall
                        visible: deviceDelegate.modelData === root.selectedDevice
                    }
                }

                onClicked: {
                    if (root.selectingInput)
                    AudioService.setSource(modelData);
                    else
                    AudioService.setSink(modelData);
                    root.deviceSelected();
                }
            }
        }
    }
}
