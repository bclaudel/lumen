pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland

import qs.Common

Rectangle {
    id: root

    property int maxWorkspaces: SettingsData.maxWorkspaces
    property var screen
    property real contentScale: 0.925
    property var workspaces: getWorkspaces()
    readonly property var monitor: Hyprland.monitors.values.find(monitor => monitor.name
                                                                            === root.screen?.name)
    readonly property int activeWorkspaceId: monitor?.activeWorkspace?.id ?? -1

    function activateWorkspace(workspaceIndex) {
        const workspace = workspaces[workspaceIndex];
        if (workspace !== undefined) {
            workspace.activate();
            return;
        }

        const workspaceId = workspaceIndex + 1;
        Hyprland.dispatch(`hl.dsp.focus({ workspace = "${workspaceId}" })`);
    }

    // Function to get the workspaces
    function getWorkspaces() {
        workspaces = Array.from({
                                    "length": maxWorkspaces
                                }, (_, i) => {
                                    return Hyprland.workspaces.values.find(ws => ws.id === i + 1);
                                });
    }

    anchors.verticalCenter: parent.verticalCenter
    color: Theme.widgetBackground
    height: Theme.topBarWidgetHeight
    radius: Theme.cornerRadius
    width: workspacesRow.width + 2 * Theme.spacingM

    // Initialize the workspaces when the component is created
    Component.onCompleted: getWorkspaces()

    // Listen for changes in Hyprland.workspaces.values
    Connections {
        function onValuesChanged() {
            root.getWorkspaces();
        }

        target: Hyprland.workspaces
    }

    Row {
        id: workspacesRow

        anchors.centerIn: parent
        spacing: Theme.spacingS * root.contentScale

        Repeater {
            model: root.maxWorkspaces

            Rectangle {
                id: workspaceItem

                required property int index
                property bool isActive: root.activeWorkspaceId === index + 1
                property bool isOccupied: root.workspaces[index] !== undefined

                color: isActive ? Theme.primary : isOccupied ? Theme.surfaceTextAlpha :
                                                               Theme.surfaceTextLight
                height: Theme.spacingL * root.contentScale
                radius: height / 2
                width: (isActive ? Theme.spacingXL + Theme.spacingM : Theme.spacingL
                                   + Theme.spacingXS) * root.contentScale

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: root.activateWorkspace(workspaceItem.index)
                }
            }
        }
    }
}
