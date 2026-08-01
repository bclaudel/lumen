pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    readonly property var focusedScreen: resolveScreen(Quickshell.screens.find(screen
                                                                               => screen.name
                                                                                  === Hyprland.focusedMonitor
                                                                                  ?.name))

    function isConnected(screen) {
        if (!screen)
            return false;

        return Quickshell.screens.some(connectedScreen => connectedScreen === screen);
    }

    function resolveScreen(requestedScreen) {
        if (isConnected(requestedScreen))
            return requestedScreen;

        const focusedMonitorName = Hyprland.focusedMonitor?.name;
        const focused = Quickshell.screens.find(screen => screen.name === focusedMonitorName);
        return focused ?? Quickshell.screens[0] ?? null;
    }
}
