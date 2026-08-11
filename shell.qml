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

    function activateExclusiveSurface(activeSurface) {
        if (activeSurface !== bluetoothPopup)
            bluetoothPopup.close();
        if (activeSurface !== controlCenter)
            controlCenter.closeControlCenter();
        if (activeSurface !== launcher)
            launcher.hide();
        if (activeSurface !== session)
            session.closeSessionScreen();
        if (activeSurface !== systemTrayPopup)
            systemTrayPopup.close();
        if (activeSurface !== wifiPopup)
            wifiPopup.close();
    }

    Background {}

    TopBar {
        bluetoothPopupOpen: bluetoothPopup.visible
        bluetoothPopupScreen: bluetoothPopup.targetScreen
        controlCenterOpen: controlCenter.isOpen
        controlCenterScreen: controlCenter.targetScreen
        osdActive: onScreenDisplay.popupActive
        osdIcon: onScreenDisplay.indicatorIcon
        osdScreen: onScreenDisplay.targetScreen
        wifiPopupOpen: wifiPopup.visible
        wifiPopupScreen: wifiPopup.targetScreen

        onBluetoothPopupRequested: (anchorItem, screen) => {
            bluetoothPopup.toggle(anchorItem, screen);
        }
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
        onWifiPopupRequested: (anchorItem, screen) => {
            wifiPopup.toggle(anchorItem, screen);
        }
    }

    BluetoothPopup {
        id: bluetoothPopup

        onVisibleChanged: {
            if (bluetoothPopup.visible)
                root.activateExclusiveSurface(bluetoothPopup);
        }
    }

    ControlCenter {
        id: controlCenter

        onIsOpenChanged: {
            if (controlCenter.isOpen)
                root.activateExclusiveSurface(controlCenter);
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

        onIsOpenChanged: {
            if (session.isOpen)
                root.activateExclusiveSurface(session);
        }
    }

    Launcher {
        id: launcher

        onVisibleChanged: {
            if (launcher.visible)
                root.activateExclusiveSurface(launcher);
        }
    }

    SystemTrayPopup {
        id: systemTrayPopup

        onVisibleChanged: {
            if (systemTrayPopup.visible)
                root.activateExclusiveSurface(systemTrayPopup);
        }
    }

    WifiPopup {
        id: wifiPopup

        onVisibleChanged: {
            if (wifiPopup.visible)
                root.activateExclusiveSurface(wifiPopup);
        }
    }
}
