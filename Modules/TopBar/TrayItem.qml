pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets

import qs.Common
import qs.Widgets

Item {
    id: root

    required property var trayItem
    property bool tooltipDismissed: false

    signal actionTriggered
    signal menuRequested(var trayItem, var anchorItem)

    function tooltipText() {
        const title = cleanTooltipText(trayItem?.tooltipTitle || trayItem?.title || trayItem?.id
                                       || "");
        const description = cleanTooltipText(trayItem?.tooltipDescription || "");
        return description && description !== title ? [title, description].filter(Boolean).join(
                                                          "\n") : title;
    }

    function cleanTooltipText(text) {
        return text.replace(/<br\s*\/?\s*>|<\/p>/gi, "\n").replace(/<[^>]*>/g, "").replace(/&lt;/g,
                                                                                           "<").replace(
                    /&gt;/g, ">").replace(/&quot;/g, '"').replace(/&#39;/g, "'").replace(/&nbsp;/g,
                                                                                         " ").replace(
                    /&amp;/g, "&").split("\n").map(line => line.trim().replace(/\s+/g, " ")).filter(
                    line => line !== "").join("\n");
    }

    implicitHeight: Theme.topBarWidgetHeight
    implicitWidth: Theme.topBarIconSize

    Rectangle {
        anchors.fill: parent
        color: mouseArea.pressed ? Theme.primaryPressed : mouseArea.containsMouse
                                   ? Theme.primaryHoverLight : "transparent"
        radius: Theme.cornerRadius
    }

    IconImage {
        id: trayIcon

        anchors.centerIn: parent
        height: Theme.topBarIconSize
        source: root.trayItem?.icon ?? ""
        visible: status === Image.Ready
        width: Theme.topBarIconSize
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

        onContainsMouseChanged: {
            if (!containsMouse)
                root.tooltipDismissed = false;
        }
        onPressed: root.tooltipDismissed = true

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

    TrayToolTip {
        target: root
        text: root.tooltipText()
        hovered: mouseArea.containsMouse && !root.tooltipDismissed
    }
}
