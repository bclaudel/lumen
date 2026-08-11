pragma Singleton

import QtQuick

import Quickshell

import qs.Common

import "../Common/fuzzysort.js" as Fuzzy

Singleton {
    id: root

    property var applications: DesktopEntries.applications.values
    property var preppedApps: {
        return applications.map(app => ({
            "name": Fuzzy.prepare(app.name || ""),
            "comment": Fuzzy.prepare(app.comment || ""),
            "entry": app
        }));
}

function compareFrecency(a, b) {
    var frecencyDifference = AppUsageHistoryData.computeFrecency(b.id)
            - AppUsageHistoryData.computeFrecency(a.id);
    if (frecencyDifference !== 0)
        return frecencyDifference;

    return (a.name || "").toLowerCase().localeCompare((b.name || "").toLowerCase());
}

function frecencyBonus(app) {
    var frecency = Math.max(0, AppUsageHistoryData.computeFrecency(app.id));

    // Match tiers remain dominant, while usage meaningfully orders equally relevant apps.
    return 10 * frecency / (frecency + 1);
}

function searchApplications(query) {
    if (query === "") {
        return applications.slice().sort(compareFrecency);
    }

    if (preppedApps.length === 0) {
        return [];
    }

    var results = Fuzzy.go(query, preppedApps, {
                               "all": false,
                               "keys": ["name", "comment"],
                               "scoreFn": r => {
                                   var nameScore = r[0] ? r[0].score : 0;
                                   var commentScore = r[1] ? r[1].score : 0;
                                   var appName = r.obj.entry.name || "";
                                   var finalScore = 0;

                                   if (nameScore > 0) {
                                       var queryLower = query.toLowerCase();
                                       var nameLower = appName.toLowerCase();

                                       if (nameLower === queryLower) {
                                           finalScore = 500;
                                       } else if (nameLower.startsWith(queryLower)) {
                                           finalScore = 400;
                                       } else if (nameLower.includes(" " + queryLower)
                                                  || nameLower.includes(queryLower + " ")
                                                  || nameLower.endsWith(" " + queryLower)) {
                                           finalScore = 300;
                                       } else if (nameLower.includes(queryLower)) {
                                           finalScore = 200;
                                       } else {
                                           finalScore = 100;
                                       }

                                       finalScore += nameScore * 10 + commentScore;
                                   } else {
                                       finalScore = commentScore * 10;
                                   }

                                   return finalScore + root.frecencyBonus(r.obj.entry);
                               },
                               "limit": 50
                           });

    return results.map(r => r.obj.entry);
}
}
