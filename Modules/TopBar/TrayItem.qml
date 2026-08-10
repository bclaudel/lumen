pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets

import qs.Common
import qs.Widgets

Item {
    id: root

    required property var trayItem

    signal actionTriggered
    signal menuRequested(var trayItem, var anchorItem)

    function tooltipText() {
        const title = trayItem.tooltipTitle || trayItem.title || trayItem.id || "";
        const description = trayItem.tooltipDescription || "";
        return description ? `${title}\n${description}` : title;
    }

    implicitHeight: 24
    implicitWidth: 24

    Rectangle {
        anchors.fill: parent
        color: mouseArea.pressed ? Theme.primaryPressed : mouseArea.containsMouse
                                   ? Theme.primaryHoverLight : "transparent"
        radius: Theme.cornerRadius
    }

    IconImage {
        id: trayIcon

        anchors.centerIn: parent
        height: 18
        source: root.trayItem?.icon ?? ""
        visible: status === Image.Ready
        width: 18
    }

    StyledText {
        anchors.centerIn: parent
        font.pixelSize: Theme.fontSizeSmall
        text: {
            const label = root.trayItem?.title || root.trayItem?.id || "?";
            return label.charAt(0).toUpperCase();
        }
        visible: !trayIcon.visible
    }

    MouseArea {
        id: mouseArea

        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onClicked: mouse => {
            if (!root.trayItem)
                return;

            if (mouse.button === Qt.MiddleButton) {
                root.trayItem.secondaryActivate();
                root.actionTriggered();
            } else if (mouse.button === Qt.RightButton) {
                if (root.trayItem.hasMenu)
                    root.menuRequested(root.trayItem, root);
            } else if (root.trayItem.onlyMenu) {
                if (root.trayItem.hasMenu)
                    root.menuRequested(root.trayItem, root);
            } else {
                root.trayItem.activate();
                root.actionTriggered();
            }
        }

        onWheel: wheel => {
            if (!root.trayItem)
                return;

            const horizontal = Math.abs(wheel.angleDelta.x) > Math.abs(wheel.angleDelta.y);
            const delta = horizontal ? wheel.angleDelta.x : wheel.angleDelta.y;
            root.trayItem.scroll(delta, horizontal);
            wheel.accepted = true;
        }
    }

    StyledToolTip {
        text: root.tooltipText()
        visible: mouseArea.containsMouse && text !== ""
    }
}
