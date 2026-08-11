import QtQuick
import QtQuick.Layouts

import qs.Common
import qs.Services

Item {
    id: root

    property bool expanded: false
    readonly property int fadeDuration: 120
    readonly property int expansionHeight: selectorVisible ? Theme.spacingM
                                                             + selector.implicitHeight : 0
    property int maximumSelectorHeight: 230
    property bool panelOpen: false
    property bool selectingInput: false
    property bool selectorVisible: false
    readonly property int transitionDuration: 140

    signal deviceSelected
    signal selectionRequested(bool input)

    implicitHeight: inputCard.implicitHeight + expansionHeight

    onExpandedChanged: {
        if (expanded) {
            collapseTimer.stop();
            selectorVisible = true;
        } else {
            collapseTimer.restart();
        }
    }

    Component.onCompleted: selectorVisible = expanded

    onPanelOpenChanged: {
        if (!panelOpen) {
            collapseTimer.stop();
            selectorVisible = false;
        }
    }

    Timer {
        id: collapseTimer

        interval: root.transitionDuration

        onTriggered: root.selectorVisible = false
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacingM

        RowLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredHeight: inputCard.implicitHeight
            spacing: Theme.spacingM

            AudioDeviceCard {
                id: inputCard

                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                active: root.expanded && root.selectingInput
                available: AudioService.inputDevices.length > 0
                iconName: AudioService.sourceMuted ? "mic_off" : "mic"
                subtitle: !AudioService.sourceAvailable ? "Select a device" :
                                                          AudioService.sourceMuted ? "Muted" :
                                                                                     AudioService.deviceDisplayName(
                                                                                         AudioService.source)
                title: "Input"

                onClicked: root.selectionRequested(true)
            }

            AudioDeviceCard {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                active: root.expanded && !root.selectingInput
                available: AudioService.outputDevices.length > 0
                iconName: AudioService.muted ? "volume_off" : "volume_up"
                subtitle: AudioService.available ? AudioService.deviceDisplayName(
                                                       AudioService.sink) : "Select a device"
                title: "Output"

                onClicked: root.selectionRequested(false)
            }
        }

        AudioDeviceSelector {
            id: selector

            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            enabled: root.expanded
            maximumHeight: root.maximumSelectorHeight
            opacity: root.expanded ? Theme.opacityFull : 0
            selectingInput: root.selectingInput
            visible: root.selectorVisible

            transform: Translate {
                y: root.expanded ? 0 : -Theme.spacingS

                Behavior on y {
                    NumberAnimation {
                        duration: root.transitionDuration
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: root.fadeDuration
                    easing.type: Easing.OutCubic
                }
            }

            onDeviceSelected: root.deviceSelected()
        }
    }
}
