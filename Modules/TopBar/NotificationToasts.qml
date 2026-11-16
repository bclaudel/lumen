pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.Common
import qs.Services

PanelWindow {
    id: root

    property bool suppressed: false

    anchors.right: true
    anchors.top: true
    color: "transparent"
    exclusiveZone: 0
    implicitWidth: 380
    implicitHeight: toastColumn.implicitHeight
    screen: ScreenService.resolveScreen(NotificationService.toastScreen)
    visible: NotificationService.toasts.length > 0 && !suppressed

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.margins.right: SettingsData.hyprlandGapsOut
    WlrLayershell.margins.top: Theme.topBarSurfaceOffset + SettingsData.hyprlandGapsOut

    mask: Region {
        item: toastColumn
    }

    Column {
        id: toastColumn
        width: parent.width
        spacing: Theme.spacingS

        Repeater {
            model: ScriptModel {
                values: NotificationService.toasts
            }

            delegate: NotificationCard {
                required property var modelData
                width: toastColumn.width
                entry: modelData
                toast: true
                onDismissRequested: id => NotificationService.dismiss(id)
                onActionRequested: (id, index) => NotificationService.invokeAction(id, index)
                onHoverChanged: hovered => NotificationService.setHovered(entry.id, hovered)
            }
        }
    }
}
