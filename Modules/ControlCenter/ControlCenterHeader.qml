pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Io
import Quickshell.Widgets

import qs.Common
import qs.Widgets

ControlCenterSurface {
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

    implicitHeight: 58

    component HeaderButton: IconButton {
        buttonSize: Theme.controlCenterButtonSize
        iconSize: Theme.iconSize
        tooltipText: accessibleName
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingM
        anchors.rightMargin: Theme.spacingXS
        spacing: Theme.spacingS

        Rectangle {
            Layout.preferredHeight: Theme.controlCenterButtonSize
            Layout.preferredWidth: Theme.controlCenterButtonSize
            color: Theme.archBlue
            radius: height / 2

            IconImage {
                id: archIcon

                anchors.centerIn: parent
                asynchronous: true
                height: Theme.iconSize
                smooth: true
                source: Qt.resolvedUrl("../../Assets/archlinux.svg")
                visible: status === Image.Ready
                width: Theme.iconSize
            }

            MaterialIcon {
                anchors.centerIn: parent
                color: Theme.primaryText
                name: "terminal"
                size: Theme.iconSize
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
            accessibleName: "Reload Lumen"
            iconName: "restart_alt"

            onClicked: Quickshell.reload(true)
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
