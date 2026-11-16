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
        if (activeSurface !== calendarPopup)
            calendarPopup.close();
        if (activeSurface !== controlCenter)
            controlCenter.closeControlCenter();
        if (activeSurface !== gamingPopup)
            gamingPopup.close();
        if (activeSurface !== launcher)
            launcher.hide();
        if (activeSurface !== notificationCenter)
            notificationCenter.close();
        if (activeSurface !== performancePopup)
            performancePopup.close();
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
        calendarPopupOpen: calendarPopup.visible
        calendarPopupScreen: calendarPopup.targetScreen
        controlCenterOpen: controlCenter.isOpen
        controlCenterScreen: controlCenter.targetScreen
        gamingPopupOpen: gamingPopup.visible
        gamingPopupScreen: gamingPopup.targetScreen
        launcherOpen: launcher.visible
        launcherScreen: launcher.targetScreen
        notificationCenterOpen: notificationCenter.visible
        notificationCenterScreen: notificationCenter.targetScreen
        osdActive: onScreenDisplay.popupActive
        osdIcon: onScreenDisplay.indicatorIcon
        osdScreen: onScreenDisplay.targetScreen
        performancePopupOpen: performancePopup.visible
        performancePopupScreen: performancePopup.targetScreen
        wifiPopupOpen: wifiPopup.visible
        wifiPopupScreen: wifiPopup.targetScreen

        onBluetoothPopupRequested: (anchorItem, screen) => {
            bluetoothPopup.toggle(anchorItem, screen);
        }
        onCalendarPopupRequested: (anchorItem, screen) => {
            calendarPopup.toggle(anchorItem, screen);
        }
        onControlCenterRequested: screen => {
            systemTrayPopup.close();
            controlCenter.toggleControlCenter(screen);
        }
        onGamingPopupRequested: (anchorItem, screen) => {
            gamingPopup.toggle(anchorItem, screen);
        }
        onLauncherRequested: screen => launcher.toggle(screen)
        onNotificationCenterRequested: (anchorItem, screen) => {
            notificationCenter.toggle(anchorItem, screen);
        }
        onPerformancePopupRequested: (anchorItem, screen) => {
            performancePopup.toggle(anchorItem, screen);
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

    CalendarPopup {
        id: calendarPopup

        onVisibleChanged: {
            if (calendarPopup.visible)
                root.activateExclusiveSurface(calendarPopup);
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

    GamingPopup {
        id: gamingPopup

        onVisibleChanged: {
            if (gamingPopup.visible)
                root.activateExclusiveSurface(gamingPopup);
        }
    }

    OnScreenDisplay {
        id: onScreenDisplay

        suppressed: controlCenter.isOpen
    }

    NotificationCenter {
        id: notificationCenter

        onVisibleChanged: {
            if (notificationCenter.visible)
                root.activateExclusiveSurface(notificationCenter);
        }
    }

    NotificationToasts {
        suppressed: bluetoothPopup.visible || calendarPopup.visible || controlCenter.isOpen
                    || gamingPopup.visible || launcher.visible || notificationCenter.visible
                    || performancePopup.visible || session.isOpen || systemTrayPopup.visible
                    || wifiPopup.visible || onScreenDisplay.popupActive
    }

    SystemPerformancePopup {
        id: performancePopup

        onVisibleChanged: {
            if (performancePopup.visible)
                root.activateExclusiveSurface(performancePopup);
        }
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
