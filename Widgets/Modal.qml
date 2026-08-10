import QtQuick

import Quickshell
import Quickshell.Wayland

import qs.Common
import qs.Services

PanelWindow {
    id: root

    property alias content: contentLoader.sourceComponent

    property real modalHeight: 300
    property real modalWidth: 400
    property string positioning: "top"
    property real topMargin: 5 * Theme.barHeight
    property color backgroundColor: Theme.popupBackground()
    property color borderColor: Theme.outlineMedium
    property real borderWidth: 1
    property real cornerRadius: Theme.cornerRadius
    property var targetScreen: null

    signal backgroundClicked

    function close() {
        if (!visible)
            return;

        visible = false;
    }

    function open(requestedScreen) {
        const resolvedScreen = ScreenService.resolveScreen(requestedScreen);
        if (!resolvedScreen)
            return;

        if (visible && targetScreen === resolvedScreen) {
            focusScope.forceActiveFocus();
            return;
        }

        const screenChanged = targetScreen !== resolvedScreen;
        if (screenChanged)
            visible = false;
        targetScreen = resolvedScreen;

        if (screenChanged) {
            Qt.callLater(() => {
                if (ScreenService.isConnected(root.targetScreen)) {
                    root.visible = true;
                    focusScope.forceActiveFocus();
                }
            });
            return;
        }

        visible = true;
        focusScope.forceActiveFocus();
    }

    function toggle(requestedScreen) {
        const resolvedScreen = ScreenService.resolveScreen(requestedScreen);
        if (!resolvedScreen)
            return;

        if (visible && targetScreen === resolvedScreen)
            close();
        else
            open(resolvedScreen);
    }

    color: "transparent"
    screen: targetScreen
    visible: false

    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Rectangle {
        id: background

        anchors.fill: parent
        color: Theme.modalScrimBackground

        MouseArea {
            anchors.fill: parent
            enabled: root.visible

            onClicked: mouse => {
                var localPos = mapToItem(content, mouse.x, mouse.y);

                // Check if the click is outside the content area
                if (localPos.x < 0 || localPos.x > content.width || localPos.y < 0 || localPos.y
                        > content.height) {
                    root.backgroundClicked();
                }
            }
        }
    }

    Rectangle {
        id: content

        height: root.modalHeight
        width: root.modalWidth
        x: Math.round((parent.width - width) / 2)
        y: root.positioning === "center" ? Math.round((parent.height - height) / 2) : root.topMargin

        color: root.backgroundColor
        radius: root.cornerRadius
        border.color: root.borderColor
        border.width: root.borderWidth

        Loader {
            id: contentLoader

            anchors.fill: parent
            active: root.visible
            asynchronous: false
        }
    }

    FocusScope {
        id: focusScope

        anchors.fill: parent
        focus: root.visible
        visible: root.visible

        Keys.onEscapePressed: event => {
            root.close();
        }
    }

    Connections {
        function onScreensChanged() {
            if (root.visible && !ScreenService.isConnected(root.targetScreen))
                root.close();
        }

        target: Quickshell
    }
}
