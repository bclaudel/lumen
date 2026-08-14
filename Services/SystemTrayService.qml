pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import Quickshell.Services.SystemTray as TrayService

import qs.Common

Singleton {
    id: root

    readonly property var items: TrayService.SystemTray.items.values
    readonly property var visibleItems: root.filterVisibleItems(items)
    readonly property var inlineItems: visibleItems.filter(item => !root.isOverflowOnly(item)).slice(
                                           0, SettingsData.trayMaxVisibleItems)
    readonly property var overflowItems: visibleItems.filter(item => root.isOverflowOnly(item)
                                                                     || inlineItems.indexOf(item)
                                                                     === -1)

    function filterVisibleItems(sourceItems) {
        const filteredItems = [];
        const seenIds = new Set();

        // Iterate backwards so a replacement registration wins over a stale one.
        for (let index = sourceItems.length - 1; index >= 0; --index) {
            const item = sourceItems[index];
            if (!item || item.status === TrayService.Status.Passive)
                continue;

            const id = String(item.id || "").trim().toLowerCase();
            if (id !== "" && seenIds.has(id))
                continue;

            if (id !== "")
                seenIds.add(id);
            filteredItems.unshift(item);
        }

        return filteredItems;
    }

    function isOverflowOnly(item) {
        return item && SettingsData.trayOverflowItemIds.includes(item.id);
    }
}
