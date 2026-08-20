pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell

Singleton {
    id: root

    property var windows: []

    function registerWindow(window) {
        if (!window || windows.includes(window))
            return;
        windows = windows.concat([window]);
    }

    function unregisterWindow(window) {
        const index = windows.indexOf(window);
        if (index < 0)
            return;
        const nextWindows = windows.slice();
        nextWindows.splice(index, 1);
        windows = nextWindows;
    }
}
