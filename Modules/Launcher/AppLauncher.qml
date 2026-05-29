import QtQuick

import qs.Common
import qs.Services as Services

Item {
    id: root

    property alias model: filteredModel

    property string searchQuery: ""
    property int selectedIndex: 0
    property bool debounceSearch: true
    property int debounceInterval: 50

    function updateFilteredModel() {
        filteredModel.clear();
        var apps = [];
        if (searchQuery === "") {
            apps = Services.AppSearchService.searchApplications(searchQuery);
        } else {
            apps = Services.AppSearchService.searchApplications(searchQuery);
        }

        if (searchQuery === "") {
            apps.sort((a, b) => {
                var aFrecency = AppUsageHistoryData.computeFrecency(a.id);
                var bFrecency = AppUsageHistoryData.computeFrecency(b.id);

                // First sort by frecency
                if (aFrecency !== bFrecency) {
                    return bFrecency - aFrecency;
                }

                // Then sort alphabetically
                var aName = (a.name || "").toLowerCase();
                var bName = (b.name || "").toLowerCase();
                return aName.localeCompare(bName);
            });
        }

        apps.forEach(app => {
            if (app) {
                filteredModel.append({
                                         "name": app.name || "",
                                         "exec": app.exec || "",
                                         "icon": app.icon || "application-x-executable",
                                         "comment": app.comment || "",
                                         "categories": app.categories || [],
                                         "desktopEntry": app
                                     });
            }
        });
    }

    function selectNext() {
        if (filteredModel.count > 0) {
            selectedIndex = Math.min(selectedIndex + 1, filteredModel.count - 1);
        }
    }

    function selectPrevious() {
        if (filteredModel.count > 0) {
            selectedIndex = Math.max(selectedIndex - 1, 0);
        }
    }

    function launchSelected() {
        if (filteredModel.count > 0 && selectedIndex >= 0 && selectedIndex < filteredModel.count) {
            var selectedApp = filteredModel.get(selectedIndex);
            launchApp(selectedApp);
        }
    }

    function launchApp(appData) {
        if (!appData)
            return;

        AppUsageHistoryData.addAppUsage(appData.desktopEntry);
        appData.desktopEntry.execute();
    }

    onSearchQueryChanged: {
        if (debounceSearch) {
            searchDebounceTimer.restart();
        } else {
            updateFilteredModel();
        }
    }

    Component.onCompleted: {
        updateFilteredModel();
    }

    ListModel {
        id: filteredModel
    }

    Timer {
        id: searchDebounceTimer

        interval: root.debounceInterval
        onTriggered: root.updateFilteredModel()
    }
}
