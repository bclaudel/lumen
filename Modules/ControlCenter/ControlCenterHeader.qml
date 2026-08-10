pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import Quickshell
import Quickshell.Io
import Quickshell.Widgets

import qs.Common
import qs.Widgets

Rectangle {
    id: root

    required property var targetScreen

    property string uptimeText: "0m"
    property string userName: Quickshell.env("USER") || "User"

    signal sessionRequested(var screen)

    function formatUptime(contents) {
        const seconds = Number(contents.trim().split(/\s+/)[0]);
        if (!Number.isFinite(seconds))
            return "0m";

        const days = Math.floor(seconds / 86400);
        const hours = Math.floor((seconds % 86400) / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        const parts = [];

        if (days > 0)
            parts.push(`${days}d`);
        if (hours > 0)
            parts.push(`${hours}h`);
        if (minutes > 0 || parts.length === 0)
            parts.push(`${minutes}m`);

        return parts.join(", ");
    }

    function refreshUptime() {
        uptimeFile.reload();
    }

    border.color: Theme.withAlpha(Theme.outline, 0.1)
    border.width: 1
    color: Theme.withAlpha(Theme.surfaceVariant, 0.38)
    implicitHeight: 58
    radius: Theme.cornerRadius + 6

    component HeaderButton: Item {
        id: buttonRoot

        property string accessibleName: ""
        property string iconName: ""
        property string tooltipText: accessibleName

        signal clicked

        implicitHeight: 36
        implicitWidth: 36

        MaterialButton {
            anchors.fill: parent
            backgroundColor: "transparent"
            buttonSize: 36
            iconName: buttonRoot.iconName
            iconSize: 20

            onClicked: buttonRoot.clicked()
        }

        HoverHandler {
            id: hoverHandler
        }

        Controls.ToolTip {
            id: tooltip

            delay: 500
            text: buttonRoot.tooltipText
            visible: hoverHandler.hovered

            background: Rectangle {
                border.color: Theme.outlineMedium
                border.width: 1
                color: Theme.popupBackground()
                radius: Theme.cornerRadius
            }

            contentItem: StyledText {
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                text: tooltip.text
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingM
        anchors.rightMargin: Theme.spacingXS
        spacing: Theme.spacingS

        Rectangle {
            Layout.preferredHeight: 46
            Layout.preferredWidth: 46
            color: Theme.archBlue
            radius: height / 2

            IconImage {
                id: archIcon

                anchors.fill: parent
                anchors.margins: 6
                asynchronous: true
                smooth: true
                source: Qt.resolvedUrl("../../Assets/archlinux.svg")
                visible: status === Image.Ready
            }

            MaterialIcon {
                anchors.centerIn: parent
                color: Theme.primaryText
                name: "terminal"
                size: 20
                visible: !archIcon.visible
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: Theme.spacingM
            spacing: 0

            StyledText {
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.DemiBold
                text: root.userName
            }

            StyledText {
                color: Theme.surfaceTextMedium
                font.pixelSize: Theme.fontSizeSmall
                text: `Up ${root.uptimeText}`
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 24
            Layout.preferredWidth: 1
            color: Theme.withAlpha(Theme.outline, 0.2)
        }

        HeaderButton {
            accessibleName: "Reload Hyprland"
            iconName: "restart_alt"

            onClicked: Quickshell.execDetached(["hyprctl", "reload"])
        }

        HeaderButton {
            accessibleName: "Settings"
            iconName: "settings"
            tooltipText: "Settings — coming soon"
        }

        HeaderButton {
            accessibleName: "Session"
            iconName: "power_settings_new"

            onClicked: root.sessionRequested(root.targetScreen)
        }
    }

    FileView {
        id: uptimeFile

        blockLoading: true
        path: "/proc/uptime"
        printErrors: false

        onLoaded: root.uptimeText = root.formatUptime(text())
    }

    Timer {
        interval: 60000
        repeat: true
        running: true

        onTriggered: root.refreshUptime()
    }

    Component.onCompleted: root.uptimeText = root.formatUptime(uptimeFile.text())
}
