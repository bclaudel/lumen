pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
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
                                                                      * Theme.spacingXS) : 260
    readonly property real popupX: {
        const preferredX = anchorPosition.x + (anchorItem?.width ?? 0) - popupWidth;
        return Math.max(Theme.spacingXS, Math.min(width - popupWidth - Theme.spacingXS,
                                                  preferredX));

    }

    function close() {
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

        relocating = true;
        visible = false;
        anchorItem = anchor;
        anchorPosition = anchor.mapToItem(null, 0, 0);
        targetScreen = resolvedScreen;
        Qt.callLater(() => {
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

        border.color: Theme.outlineMedium
        border.width: 1
        clip: true
        color: Theme.popupBackground()
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

                spacing: 1
                width: menuFlickable.width

                Rectangle {
                    color: Theme.withAlpha(Theme.surfaceContainer, 0)
                    height: 30
                    radius: Theme.cornerRadius
                    visible: root.submenuStack.length > 0
                    width: parent.width

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingXS

                        MaterialIcon {
                            name: "arrow_back"
                            size: Theme.iconSizeSmall
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: Theme.fontSizeSmall
                            text: "Back"
                        }
                    }

                    StateLayer {
                        cornerRadius: Theme.cornerRadius
                        stateColor: Theme.primary

                        onClicked: root.goBack()
                    }
                }

                Repeater {
                    model: menuOpener.children

                    Rectangle {
                        id: menuEntryRoot

                        required property var modelData
                        readonly property var menuEntry: modelData

                        color: menuEntry?.isSeparator ? Theme.outlineMedium : Theme.withAlpha(
                                                            Theme.surfaceContainer, 0)
                        height: menuEntry?.isSeparator ? 1 : 32
                        radius: menuEntry?.isSeparator ? 0 : Theme.cornerRadius
                        width: menuColumn.width

                        MouseArea {
                            id: entryArea

                            anchors.fill: parent
                            cursorShape: enabled ? Qt.PointingHandCursor : undefined
                            enabled: !menuEntryRoot.menuEntry?.isSeparator
                                     && menuEntryRoot.menuEntry?.enabled !== false
                            hoverEnabled: true

                            onClicked: {
                                const entry = menuEntryRoot.menuEntry;
                                if (!entry)
                                return;

                                if (entry.hasChildren) {
                                    root.openSubmenu(entry);
                                } else {
                                    if (typeof entry.triggered === "function")
                                    entry.triggered();
                                    Qt.callLater(() => root.close());
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: Theme.surfaceHover
                            radius: parent.radius
                            visible: entryArea.containsMouse
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingS
                            anchors.rightMargin: Theme.spacingS
                            spacing: Theme.spacingS
                            visible: !menuEntryRoot.menuEntry?.isSeparator

                            Item {
                                Layout.preferredHeight: Theme.iconSizeSmall
                                Layout.preferredWidth: Theme.iconSizeSmall

                                Rectangle {
                                    anchors.fill: parent
                                    border.color: Theme.outline
                                    border.width: 1
                                    color: menuEntryRoot.menuEntry?.buttonType
                                           === QsMenuButtonType.CheckBox && menuEntryRoot.menuEntry
                                           ?.checkState === Qt.Checked ? Theme.primary :
                                                                         "transparent"
                                    radius: menuEntryRoot.menuEntry?.buttonType
                                            === QsMenuButtonType.RadioButton ? width / 2 : 2
                                    visible: menuEntryRoot.menuEntry?.buttonType
                                             !== QsMenuButtonType.None

                                    Rectangle {
                                        anchors.centerIn: parent
                                        color: Theme.primary
                                        height: parent.height - 6
                                        radius: height / 2
                                        visible: menuEntryRoot.menuEntry?.buttonType
                                                 === QsMenuButtonType.RadioButton
                                                 && menuEntryRoot.menuEntry?.checkState
                                                 === Qt.Checked
                                        width: parent.width - 6
                                    }

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        color: Theme.primaryText
                                        name: "check"
                                        size: Theme.iconSizeSmall - 4
                                        visible: menuEntryRoot.menuEntry?.buttonType
                                                 === QsMenuButtonType.CheckBox
                                                 && menuEntryRoot.menuEntry?.checkState
                                                 === Qt.Checked
                                    }
                                }
                            }

                            Item {
                                Layout.preferredHeight: Theme.iconSizeSmall
                                Layout.preferredWidth: Theme.iconSizeSmall

                                IconImage {
                                    anchors.fill: parent
                                    source: menuEntryRoot.menuEntry?.icon ?? ""
                                    visible: source !== ""
                                }
                            }

                            StyledText {
                                color: menuEntryRoot.menuEntry?.enabled !== false
                                       ? Theme.surfaceText : Theme.surfaceTextMedium
                                elide: Text.ElideRight
                                font.pixelSize: Theme.fontSizeSmall
                                Layout.alignment: Qt.AlignVCenter
                                Layout.fillWidth: true
                                text: menuEntryRoot.menuEntry?.text ?? ""
                            }

                            Item {
                                Layout.preferredHeight: Theme.iconSizeSmall
                                Layout.preferredWidth: Theme.iconSizeSmall

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    name: "chevron_right"
                                    size: Theme.iconSizeSmall
                                    visible: menuEntryRoot.menuEntry?.hasChildren ?? false
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

        Keys.onEscapePressed: {
            if (root.submenuStack.length > 0)
            root.goBack();
            else
            root.close();
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
