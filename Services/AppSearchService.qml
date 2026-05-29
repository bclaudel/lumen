pragma Singleton

import QtQuick

import Quickshell

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

function searchApplications(query) {
    if (query === "") {
        return applications;
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
                                           finalScore = nameScore * 100;
                                       } else if (nameLower.startsWith(queryLower)) {
                                           finalScore = nameScore * 50;
                                       } else if (nameLower.includes(" " + queryLower)
                                                  || nameLower.includes(queryLower + " ")
                                                  || nameLower.endsWith(" " + queryLower)) {
                                           finalScore = nameScore * 25;
                                       } else if (nameLower.includes(queryLower)) {
                                           finalScore = nameScore * 10;
                                       } else {
                                           finalScore = nameScore * 2 + commentScore * 0.1;
                                       }
                                   } else {
                                       finalScore = commentScore * 0.1;
                                   }

                                   return finalScore;
                               },
                               "limit": 50
                           });

    return results.map(r => r.obj.entry);
}
}
