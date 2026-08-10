import QtQuick
import Quickshell

import qs.Modules.Background
import qs.Modules.ControlCenter
import qs.Modules.OnScreenDisplay
import qs.Modules.Session
import qs.Modules.TopBar
import qs.Modules.Launcher

ShellRoot {
    id: root

    Background {}

    TopBar {
        controlCenterOpen: controlCenter.isOpen
        controlCenterScreen: controlCenter.targetScreen
        osdActive: onScreenDisplay.popupActive
        osdIcon: onScreenDisplay.indicatorIcon
        osdScreen: onScreenDisplay.targetScreen

        onControlCenterRequested: screen => {
            systemTrayPopup.close();
            controlCenter.toggleControlCenter(screen);
        }
        onTrayMenuRequested: (trayItem, anchorItem, screen) => {
            controlCenter.closeControlCenter();
            systemTrayPopup.showMenu(trayItem, anchorItem, screen);
        }
        onTrayOverflowRequested: (anchorItem, screen) => {
            controlCenter.closeControlCenter();
            systemTrayPopup.showOverflow(anchorItem, screen);
        }
    }

    ControlCenter {
        id: controlCenter

        onIsOpenChanged: {
            if (controlCenter.isOpen)
                systemTrayPopup.close();
        }
        onLauncherRequested: screen => {
            controlCenter.closeControlCenter();
            launcher.show(screen);
        }
        onSessionRequested: screen => {
            controlCenter.closeControlCenter();
            session.openSessionScreen(screen);
        }
    }

    OnScreenDisplay {
        id: onScreenDisplay

        suppressed: controlCenter.isOpen
    }

    Session {
        id: session
    }

    Launcher {
        id: launcher
    }

    SystemTrayPopup {
        id: systemTrayPopup
    }
}
