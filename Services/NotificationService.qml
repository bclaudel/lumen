pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

import qs.Services

Singleton {
    id: root

    property var history: []
    property var toastIds: []
    property var toastScreen: null
    readonly property var toasts: toastIds.map(id => history.find(entry => entry.id === id)).filter(
                                      Boolean)

    readonly property int unreadCount: history.filter(entry => entry.unread).length

    function receive(notification) {
        notification.tracked = true;
        const now = Date.now();
        const timeout = notification.expireTimeout;
        const defaultDuration = notification.urgency === NotificationUrgency.Critical ? 0 :
                                                                                        notification.urgency
                                                                                        === NotificationUrgency.Low
                                                                                        ? 4000 : 6000;
        const duration = timeout < 0 ? defaultDuration : timeout * 1000;
        const entry = {
            id: notification.id,
            appName: notification.appName || "Application",
            icon: notification.appIcon || "",
            summary: notification.summary || "Notification",
            body: notification.body || "",
            urgency: notification.urgency,
            active: notification,
            unread: !notification.transient && !notification.lastGeneration,
            transient: notification.transient,
            receivedAt: now,
            expiresAt: duration > 0 ? now + duration : 0,
            hoveredAt: 0
        };
        const entries = [entry].concat(history.filter(item => item.id !== entry.id));
        history = entries.slice(0, 100);
        for (const oldEntry of entries.slice(100)) {
            if (oldEntry.active)
                oldEntry.active.expire();
        }
        if (!notification.lastGeneration) {
            toastScreen = ScreenService.resolveScreen(ScreenService.focusedScreen);
            toastIds = [entry.id].concat(toastIds.filter(id => id !== entry.id)).slice(0, 3);
        }
        notification.closed.connect(reason => root.closed(entry.id, notification));
    }

    function closed(id, notification) {
        const entry = history.find(item => item.id === id);
        if (!entry || entry.active !== notification)
            return;
        entry.active = null;
        history = history.slice();
        toastIds = toastIds.filter(item => item !== id);
    }

    function dismiss(id) {
        const entry = history.find(item => item.id === id);
        history = history.filter(item => item.id !== id);
        toastIds = toastIds.filter(item => item !== id);
        if (entry?.active)
            entry.active.dismiss();
    }

    function clearAll() {
        const active = history.map(entry => entry.active).filter(Boolean);
        history = [];
        toastIds = [];
        for (const notification of active)
            notification.dismiss();
    }

    function invokeAction(id, index) {
        const entry = history.find(item => item.id === id);
        const action = entry?.active?.actions[index];
        if (action)
            action.invoke();
    }

    function markAllRead() {
        if (unreadCount === 0)
            return;
        history = history.map(entry => Object.assign({}, entry, {
                                                         unread: false
                                                     }));
    }

    function hideToasts() {
        for (const entry of toasts)
            entry.hoveredAt = 0;
        toastIds = [];
    }

    function setHovered(id, hovered) {
        const entry = history.find(item => item.id === id);
        if (!entry)
            return;
        if (hovered)
            entry.hoveredAt = Date.now();
        else if (entry.hoveredAt) {
            if (entry.expiresAt)
                entry.expiresAt += Date.now() - entry.hoveredAt;
            entry.hoveredAt = 0;
        }
    }

    NotificationServer {
        keepOnReload: true
        persistenceSupported: true
        actionsSupported: true
        bodySupported: true

        onNotification: notification => root.receive(notification)
    }

    Timer {
        interval: 250
        repeat: true
        running: root.history.some(entry => entry.active && entry.expiresAt > 0)

        onTriggered: {
            const now = Date.now();
            for (const entry of root.history) {
                if (entry.expiresAt && !entry.hoveredAt && now >= entry.expiresAt) {
                    root.toastIds = root.toastIds.filter(id => id !== entry.id);
                    if (entry.active)
                        entry.active.expire();
                }
            }
        }
    }
}
