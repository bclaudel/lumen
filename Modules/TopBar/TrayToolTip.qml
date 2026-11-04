pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.Common
import qs.Widgets

PopupWindow {
    id: root

    required property Item target
    property bool hovered: false
    property string text: ""
    property bool delayElapsed: false

    // Quickshell's tooling describes PopupWindow.anchor as opaque.
    // qmllint disable missing-property unresolved-type unqualified
    anchor.item: target
    anchor.rect.x: target.width / 2
    anchor.rect.y: target.height + Theme.spacingS
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    // qmllint enable missing-property unresolved-type unqualified
    color: "transparent"
    grabFocus: false
    implicitWidth: Math.ceil(Math.min(320, label.implicitWidth + 2 * Theme.spacingM))
    implicitHeight: Math.ceil(label.implicitHeight + 2 * Theme.spacingS)
    visible: hovered && delayElapsed && text !== ""

    // Tooltips must never consume a click intended for the tray or its menu.
    mask: Region {}

    onHoveredChanged: delayElapsed = false

    Timer {
        interval: 600
        running: root.hovered && !root.delayElapsed && root.text !== ""
        onTriggered: root.delayElapsed = true
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.popupBackground()
        border.color: Theme.outlineMedium
        border.width: 1
        radius: Theme.cornerRadius

        StyledText {
            id: label

            x: Theme.spacingM
            y: Theme.spacingS
            width: root.width - 2 * Theme.spacingM
            text: root.text
            textFormat: Text.PlainText
            font.pixelSize: Theme.fontSizeSmall
            maximumLineCount: 6
            wrapMode: Text.Wrap
        }
    }
}
