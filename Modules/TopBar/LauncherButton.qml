pragma ComponentBehavior: Bound

import QtQuick

import Quickshell.Widgets

import qs.Widgets

TopBarButton {
    id: root

    accessibleName: "Open launcher"

    contentItem: Item {
        IconImage {
            id: archIcon

            anchors.centerIn: parent
            height: root.iconSize
            smooth: true
            source: Qt.resolvedUrl("../../Assets/archlinux.svg")
            visible: status === Image.Ready
            width: root.iconSize
        }

        MaterialIcon {
            anchors.centerIn: parent
            name: "apps"
            size: root.iconSize
            visible: !archIcon.visible
        }
    }
}
