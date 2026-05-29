pragma Singleton

import QtCore
import QtQuick

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var appUsageRanking: ({})

    Component.onCompleted: {
        loadSettings();
    }

    function loadSettings() {
        parseSettings(settingsFile.text());

        // On first run the file does not exist yet, so persist the default shape.
        if (!settingsFile.loaded) {
            saveSettings();
        }
    }

    function parseSettings(content) {
        try {
            if (content && content.trim()) {
                var settings = JSON.parse(content);
                appUsageRanking = settings.appUsageRanking || {};
            }
        } catch (e) {
            console.warn("Failed to parse settings:", e);
        }
    }

    function saveSettings() {
        settingsFile.setText(JSON.stringify({
                                                "appUsageRanking": appUsageRanking
                                            }, null, 2));
    }

    function addAppUsage(app) {
        if (!app)
            return;
        if (!app.id)
            return;

        var currentRanking = Object.assign({}, root.appUsageRanking);
        if (currentRanking[app.id]) {
            currentRanking[app.id].score = currentRanking[app.id].score + 1;
            currentRanking[app.id].lastUsed = Date.now();
        } else {
            currentRanking[app.id] = {
                "score": 1,
                "lastUsed": Date.now()
            };
        }

        appUsageRanking = currentRanking;
        saveSettings();
    }

    function computeFrecency(appId) {
        if (!appId)
            return 0;

        var appData = root.appUsageRanking[appId];
        if (!appData)
            return 0;

        var score = appData.score;
        var ageSeconds = (Date.now() - appData.lastUsed) / 1000;

        // Weight by recency
        if (ageSeconds < 60 * 60) {
            score *= 4;
        } else if (ageSeconds < 24 * 60 * 60) {
            score *= 2;
        } else if (ageSeconds < 7 * 24 * 60 * 60) {
            score *= 0.5;
        } else {
            score *= 0.25;
        }

        return score;
    }

    FileView {
        id: settingsFile

        path: StandardPaths.writableLocation(StandardPaths.GenericStateLocation)
              + "/lumen/appUsageHistory.json"
        blockLoading: true
        blockWrites: true
        printErrors: false
        watchChanges: true

        onLoaded: {
            root.parseSettings(settingsFile.text());
        }
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                console.warn("Failed to load settings file:", path, FileViewError.toString(error));
        }
    }
}
