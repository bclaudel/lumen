pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import Quickshell.Wayland

import qs.Common

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: backgroundWindow

        required property var modelData

        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "quickshell:background"
        color: "black"
        exclusionMode: ExclusionMode.Ignore
        screen: modelData

        anchors {
            bottom: true
            left: true
            right: true
            top: true
        }

        Image {
            anchors.fill: parent
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            source: SettingsData.wallpaperPath
        }
    }
}
