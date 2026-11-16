pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import qs.Common
import qs.Widgets

Rectangle {
    id: root

    required property var entry
    property bool toast: false

    signal dismissRequested(int id)
    signal actionRequested(int id, int index)
    signal hoverChanged(bool hovered)

    implicitHeight: cardContent.implicitHeight + 2 * Theme.spacingM
    border.color: Theme.outlineMedium
    border.width: 1
    color: Theme.popupBackground()
    radius: Theme.cornerRadius

    HoverHandler {
        enabled: root.toast
        onHoveredChanged: root.hoverChanged(hovered)
    }

    ColumnLayout {
        id: cardContent

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingXS

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingS

            Item {
                Layout.preferredWidth: Theme.iconSize
                Layout.preferredHeight: Theme.iconSize

                IconImage {
                    id: appIcon
                    anchors.fill: parent
                    source: root.entry.icon ? Quickshell.iconPath(root.entry.icon, true) : ""
                    visible: status === Image.Ready
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    name: "notifications"
                    size: Theme.iconSize
                    color: Theme.primary
                    visible: !appIcon.visible
                }
            }

            StyledText {
                Layout.fillWidth: true
                color: Theme.surfaceTextMedium
                font.pixelSize: Theme.fontSizeSmall
                text: root.entry.appName
                textFormat: Text.PlainText
                wrapMode: Text.NoWrap
            }

            IconButton {
                accessibleName: "Dismiss notification"
                buttonSize: 24
                iconName: "close"
                iconSize: Theme.iconSizeSmall
                onClicked: root.dismissRequested(root.entry.id)
            }
        }

        StyledText {
            Layout.fillWidth: true
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.DemiBold
            text: root.entry.summary
            textFormat: Text.PlainText
            maximumLineCount: 2
        }

        StyledText {
            Layout.fillWidth: true
            color: Theme.surfaceTextMedium
            font.pixelSize: Theme.fontSizeSmall
            text: root.entry.body
            textFormat: Text.PlainText
            maximumLineCount: root.toast ? 3 : 5
            visible: text !== ""
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.entry.active?.actions.length > 0

            Repeater {
                model: root.entry.active?.actions.slice(0, 2) ?? []

                delegate: Controls.AbstractButton {
                    id: actionButton

                    required property int index
                    required property var modelData

                    Layout.preferredHeight: 28
                    Layout.fillWidth: true
                    hoverEnabled: true

                    background: Rectangle {
                        color: Theme.primaryHover
                        radius: Theme.cornerRadius
                    }
                    contentItem: StyledText {
                        horizontalAlignment: Text.AlignHCenter
                        color: Theme.primary
                        font.pixelSize: Theme.fontSizeSmall
                        text: actionButton.modelData.text
                        textFormat: Text.PlainText
                        wrapMode: Text.NoWrap
                    }
                    onClicked: root.actionRequested(root.entry.id, index)
                }
            }
        }
    }
}
