import QtQuick
import Quickshell

import qs.Modules.ControlCenter
import qs.Modules.Session
import qs.Modules.TopBar
import qs.Modules.Launcher

ShellRoot {
    id: root

    TopBar {
        controlCenterOpen: controlCenter.isOpen
        controlCenterScreen: controlCenter.targetScreen

        onControlCenterRequested: screen => {
            controlCenter.toggleControlCenter(screen);
        }
    }

    ControlCenter {
        id: controlCenter

        onLauncherRequested: screen => {
            controlCenter.closeControlCenter();
            launcher.show(screen);
        }
        onSessionRequested: screen => {
            controlCenter.closeControlCenter();
            session.openSessionScreen(screen);
        }
    }

    Session {
        id: session
    }

    Launcher {
        id: launcher
    }
}
