pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import qs.Common
import qs.Services
import qs.Widgets

Controls.AbstractButton {
    id: root

    required property var network
    property bool busy: false
    property string errorText: ""

    signal activated(var network)

    Accessible.description: network.enterprise ? "Unsupported network security" : network.security
    Accessible.name: network.ssid
    enabled: !network.enterprise && !busy
    hoverEnabled: enabled
    implicitHeight: rowContent.implicitHeight

    background: Rectangle {
        border.color: root.network.active ? Theme.primary : "transparent"
        border.width: root.network.active ? 1 : 0
        color: root.network.active ? Theme.primarySelected : root.down ? Theme.surfacePressed :
                                                                         root.hovered
                                                                         || root.visualFocus
                                                                         ? Theme.surfaceHover :
                                                                           "transparent"
        radius: Theme.cornerRadius
    }

    contentItem: ColumnLayout {
        id: rowContent

        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            spacing: Theme.spacingM

            MaterialIcon {
                Layout.leftMargin: Theme.spacingM
                color: root.network.active ? Theme.primary : Theme.surfaceText
                name: NetworkService.signalIcon(root.network.signal)
                size: Theme.iconSize
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                StyledText {
                    Layout.fillWidth: true
                    color: Theme.surfaceText
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: root.network.active ? Font.DemiBold : Font.Normal
                    text: root.network.ssid
                }

                StyledText {
                    Layout.fillWidth: true
                    color: root.network.enterprise ? Theme.warning : Theme.surfaceTextMedium
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fontSizeSmall
                    text: root.network.enterprise ? "Enterprise network — unsupported" :
                                                    root.network.active ? "Connected" :
                                                                          root.network.security
                    visible: text !== ""
                }
            }

            Item {
                Layout.rightMargin: Theme.spacingM
                Layout.preferredHeight: Theme.iconSizeSmall
                Layout.preferredWidth: Theme.iconSizeSmall

                MaterialIcon {
                    anchors.centerIn: parent
                    color: root.network.active ? Theme.primary : Theme.surfaceTextMedium
                    name: root.network.active ? "check" : root.network.secured ? "lock" : ""
                    size: Theme.iconSizeSmall
                    visible: !root.busy && name !== ""
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    name: "progress_activity"
                    rotation: 0
                    size: Theme.iconSizeSmall
                    visible: root.busy

                    RotationAnimation on rotation {
                        duration: 900
                        from: 0
                        loops: Animation.Infinite
                        running: root.busy
                        to: 360
                    }
                }
            }
        }

        StyledText {
            Layout.bottomMargin: Theme.spacingS
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spacingM + Theme.iconSize + Theme.spacingM
            Layout.rightMargin: Theme.spacingM
            color: Theme.error
            font.pixelSize: Theme.fontSizeSmall
            text: root.errorText
            visible: text !== ""
            wrapMode: Text.Wrap
        }
    }

    onClicked: root.activated(network)
}
