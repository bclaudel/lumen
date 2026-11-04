pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

import qs.Common
import qs.Services
import qs.Widgets

PanelWindow {
    id: root

    property var anchorItem: null
    property point anchorPosition: Qt.point(0, 0)
    property var currentTrayItem: null
    property string mode: ""
    property bool relocating: false
    property int openGeneration: 0
    property var submenuStack: []
    property var targetScreen: null
    readonly property var activeMenu: submenuStack.length > 0 ? submenuStack[submenuStack.length
                                                                             - 1] : currentTrayItem
                                                                ?.menu ?? null
    readonly property var overflowItems: SystemTrayService.overflowItems
    readonly property real overflowHeight: 30
    readonly property real overflowWidth: overflowItems.length * (Theme.iconSize + Theme.spacingXS)
                                          - Theme.spacingXS + 6
    readonly property real popupHeight: {
        if (mode === "overflow")
            return overflowHeight;

        return Math.min((targetScreen?.height ?? 686) * 0.7, menuColumn.implicitHeight + 2
                        * Theme.spacingS);

    }
    readonly property real popupWidth: mode === "overflow" ? Math.min(overflowWidth, width - 2
                                                                      * Theme.spacingXS) : Math.min(
                                                                 300, width - 2 * Theme.spacingXS)
    readonly property real popupX: {
        const preferredX = anchorPosition.x + (anchorItem?.width ?? 0) - popupWidth;
        return Math.max(Theme.spacingXS, Math.min(width - popupWidth - Theme.spacingXS,
                                                  preferredX));

    }

    function close() {
        openGeneration++;
        relocating = false;
        visible = false;
    }

    function closeSubmenus() {
        for (const entry of submenuStack) {
            if (entry && typeof entry.closed === "function")
                entry.closed();
        }
        submenuStack = [];
    }

    function goBack() {
        if (submenuStack.length === 0)
            return;

        const entry = submenuStack[submenuStack.length - 1];
        if (entry && typeof entry.closed === "function")
            entry.closed();
        submenuStack = submenuStack.slice(0, -1);
    }

    function openAt(anchor, screen) {
        const resolvedScreen = ScreenService.resolveScreen(screen);
        if (!anchor || !resolvedScreen)
            return;

        const generation = ++openGeneration;
        relocating = true;
        visible = false;
        anchorItem = anchor;
        anchorPosition = anchor.mapToItem(null, 0, 0);
        targetScreen = resolvedScreen;
        Qt.callLater(() => {
            if (generation !== root.openGeneration)
                return;
            if (root.anchorItem && ScreenService.isConnected(root.targetScreen)) {
                root.visible = true;
                popupFocus.forceActiveFocus();
            }
            root.relocating = false;
        });
    }

    function openSubmenu(entry) {
        if (!entry?.hasChildren)
            return;

        if (typeof entry.opened === "function")
            entry.opened();
        submenuStack = submenuStack.concat([entry]);
    }

    function showMenu(trayItem, anchor, screen) {
        if (!trayItem?.hasMenu)
            return;

        closeSubmenus();
        currentTrayItem = trayItem;
        mode = "menu";
        openAt(anchor, screen);
    }

    function showOverflow(anchor, screen) {
        closeSubmenus();
        currentTrayItem = null;
        mode = "overflow";
        openAt(anchor, screen);
    }

    anchors {
        bottom: true
        left: true
        right: true
        top: true
    }
    color: "transparent"
    exclusiveZone: 0
    screen: targetScreen
    visible: false
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onVisibleChanged: {
        if (!visible && !relocating) {
            closeSubmenus();
            mode = "";
            currentTrayItem = null;
        }
    }

    QsMenuOpener {
        id: menuOpener

        menu: root.activeMenu
    }

    HyprlandFocusGrab {
        active: root.visible
        windows: [root].concat(TopBarService.windows)

        onCleared: root.close()
    }

    MouseArea {
        anchors.fill: parent

        onClicked: root.close()
    }

    Rectangle {
        id: popupContent

        border.color: Theme.withAlpha(Theme.outline, 0.16)
        border.width: 1
        clip: true
        color: Theme.withAlpha(Theme.surfaceContainer, 0.9)
        height: root.popupHeight
        radius: Theme.cornerRadius
        width: root.popupWidth
        x: root.popupX
        y: Theme.spacingXS

        MouseArea {
            anchors.fill: parent
        }

        Flickable {
            id: overflowFlickable

            anchors.fill: parent
            clip: true
            contentHeight: height
            contentWidth: overflowRow.width + 6
            interactive: contentWidth > width
            visible: root.mode === "overflow"

            Row {
                id: overflowRow

                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingXS
                x: 3

                Repeater {
                    model: root.overflowItems

                    TrayItem {
                        required property var modelData

                        height: Theme.iconSize
                        trayItem: modelData
                        width: Theme.iconSize

                        onActionTriggered: root.close()
                        onMenuRequested: (trayItem, anchorItem) => {
                            root.showMenu(trayItem, root.anchorItem, root.targetScreen);
                        }
                    }
                }
            }
        }

        Flickable {
            id: menuFlickable

            anchors.fill: parent
            anchors.margins: Theme.spacingS
            clip: true
            contentHeight: menuColumn.implicitHeight
            interactive: contentHeight > height
            visible: root.mode === "menu"

            Column {
                id: menuColumn

                spacing: Theme.spacingXS
                width: menuFlickable.width

                TrayMenuRow {
                    width: parent.width
                    visible: root.submenuStack.length > 0
                    entry: ({
                                "text": "Back",
                                "enabled": true
                            })
                    onClicked: root.goBack()
                }
                Repeater {
                    model: menuOpener.children

                    Column {
                        id: menuEntryRoot

                        required property var modelData

                        width: menuColumn.width

                        Item {
                            visible: menuEntryRoot.modelData?.isSeparator ?? false
                            width: parent.width
                            height: Theme.spacingM + 1

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: Theme.spacingM
                                anchors.rightMargin: Theme.spacingM
                                height: 1
                                color: Theme.withAlpha(Theme.surfaceText, 0.12)
                            }
                        }

                        TrayMenuRow {
                            width: parent.width
                            entry: menuEntryRoot.modelData
                            visible: !entry?.isSeparator

                            onClicked: {
                                if (entry?.hasChildren) {
                                    root.openSubmenu(entry);
                                } else if (entry) {
                                    entry.triggered();
                                    root.close();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    FocusScope {
        id: popupFocus

        anchors.fill: parent
        focus: root.visible

        Shortcut {
            sequence: "Escape"
            context: Qt.WindowShortcut
            enabled: root.visible

            onActivated: {
                if (root.submenuStack.length > 0)
                    root.goBack();
                else
                    root.close();
            }
        }
    }

    Connections {
        function onDestroyed() {
            root.close();
        }

        ignoreUnknownSignals: true
        target: root.anchorItem
    }

    Connections {
        function onScreensChanged() {
            if (root.visible && !ScreenService.isConnected(root.targetScreen))
                root.close();
        }

        target: Quickshell
    }

    Connections {
        function onOverflowItemsChanged() {
            if (!root.visible)
                return;

            if (root.mode === "overflow" && root.overflowItems.length === 0)
                root.close();
        }

        function onVisibleItemsChanged() {
            if (root.visible && root.mode === "menu" && SystemTrayService.visibleItems.indexOf(
                        root.currentTrayItem) === -1)
                root.close();
        }

        target: SystemTrayService
    }
}
