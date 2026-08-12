pragma Singleton
pragma ComponentBehavior

import QtQuick
import Quickshell

Singleton {
    id: root

    property int themeIndex: 0
    property real hyprlandGapsOut: 5
    property int maxWorkspaces: 8
    property string networkPreference: "auto"
    property real topBarTransparency: 0.75
    property int trayMaxVisibleItems: 5
    property var trayOverflowItemIds: ["Fcitx"]
    property string wallpaperPath: "/home/benoit/Pictures/arch_2560x1440.png"
    property string displayFontFamily: "Adwaita Sans"
    property string fontFamily: "Adwaita Sans"

    function isTrayOverflowOnly(item) {
        return item && root.trayOverflowItemIds.includes(item.id);
    }

    function setNetworkPreference(preference) {
        root.networkPreference = preference;
    }
}
