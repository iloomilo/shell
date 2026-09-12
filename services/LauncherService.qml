pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property string query: ""
    property int selectedIndex: 0
    property var allApps: []

    function updateApps() {
        let raw = DesktopEntries.applications.values;
        if (!raw || raw.length === 0)
            return;

        let filtered = [];
        let seen = {};

        for (let i = 0; i < raw.length; i++) {
            let app = raw[i];
            if (!app || app.noDisplay || !app.name || app.name.trim().length === 0)
                continue;

            // Deduplicate identical app names or IDs
            let key = (app.name + "::" + (app.execString || "")).toLowerCase();
            if (seen[key])
                continue;
            seen[key] = true;

            filtered.push({
                id: app.id || "",
                name: app.name,
                genericName: app.genericName || "",
                comment: app.comment || "",
                icon: app.icon || "",
                categories: app.categories || [],
                keywords: app.keywords || [],
                execString: app.execString || "",
                entry: app
            });
        }

        filtered.sort((a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: "base" }));
        root.allApps = filtered;
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root.updateApps();
        }
    }

    Component.onCompleted: {
        root.updateApps();
    }

    onQueryChanged: {
        root.selectedIndex = 0;
    }

    readonly property var results: {
        let q = query.trim().toLowerCase();
        if (q.length === 0)
            return root.allApps;

        let scored = [];
        for (let i = 0; i < root.allApps.length; i++) {
            let app = root.allApps[i];
            let name = app.name.toLowerCase();
            let score = 0;

            if (name === q) {
                score = 1000;
            } else if (name.startsWith(q)) {
                score = 800 - (name.length - q.length);
            } else {
                let words = name.split(/\s+/);
                let wordMatch = false;
                for (let w = 0; w < words.length; w++) {
                    if (words[w].startsWith(q)) {
                        score = 500;
                        wordMatch = true;
                        break;
                    }
                }
                if (!wordMatch) {
                    let idx = name.indexOf(q);
                    if (idx !== -1) {
                        score = 300 - idx;
                    } else if (app.genericName && app.genericName.toLowerCase().includes(q)) {
                        score = 150;
                    } else if (app.comment && app.comment.toLowerCase().includes(q)) {
                        score = 100;
                    } else if (app.execString && app.execString.toLowerCase().includes(q)) {
                        score = 80;
                    } else {
                        let catMatch = false;
                        for (let c = 0; c < app.categories.length; c++) {
                            if (app.categories[c].toLowerCase().includes(q)) {
                                score = 50;
                                catMatch = true;
                                break;
                            }
                        }
                    }
                }
            }

            if (score > 0) {
                scored.push({ app: app, score: score });
            }
        }

        scored.sort((a, b) => {
            if (b.score !== a.score) return b.score - a.score;
            return a.app.name.localeCompare(b.app.name);
        });

        return scored.map(s => s.app);
    }

    function selectNext() {
        if (results.length > 0) {
            root.selectedIndex = (root.selectedIndex + 1) % results.length;
        }
    }

    function selectPrevious() {
        if (results.length > 0) {
            root.selectedIndex = (root.selectedIndex - 1 + results.length) % results.length;
        }
    }

    function launch(app) {
        if (app && app.entry) {
            app.entry.execute();
            DynamicIsland.closeLauncher();
            root.query = "";
            root.selectedIndex = 0;
        }
    }

    function launchSelected() {
        if (results.length > 0 && selectedIndex >= 0 && selectedIndex < results.length) {
            launch(results[selectedIndex]);
        }
    }

    function reset() {
        root.query = "";
        root.selectedIndex = 0;
    }
}
