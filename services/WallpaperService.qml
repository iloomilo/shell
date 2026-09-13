pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string directory: Quickshell.env("QS_WALLPAPER_DIR") || (Quickshell.env("HOME") + "/Pictures/Wallpapers")
    property var wallpapers: []
    property var categories: ["All"]
    property string category: "All"
    property string current: ""
    property bool scanning: false
    property bool directoryExists: true
    property int selectedIndex: 0

    readonly property var schemes: [
        { id: "", label: "Tonal spot · Default" },
        { id: "scheme-content", label: "Content" },
        { id: "scheme-expressive", label: "Expressive" },
        { id: "scheme-fidelity", label: "Fidelity" },
        { id: "scheme-fruit-salad", label: "Fruit salad" },
        { id: "scheme-monochrome", label: "Monochrome" },
        { id: "scheme-neutral", label: "Neutral" },
        { id: "scheme-rainbow", label: "Rainbow" },
        { id: "scheme-vibrant", label: "Vibrant" },
        { id: "scheme-smart", label: "Smart" }
    ]
    property string scheme: ""
    readonly property string appliedScheme: stateAdapter.appliedScheme === "scheme-tonal-spot" ? "" : stateAdapter.appliedScheme
    property string previewing: ""
    property string previewScheme: ""
    readonly property bool isPreviewing: previewing.length > 0
    readonly property bool hasPendingChange: isPreviewing || scheme !== appliedScheme

    readonly property var filtered: category === "All" ? wallpapers : wallpapers.filter(w => w.category === category)

    onCategoryChanged: selectedIndex = 0

    function refresh() {
        scheme = appliedScheme;
        scanning = true;
        scanProc.running = true;
        currentProc.running = true;
    }

    function fileUrl(path) {
        return "file://" + path.split("/").map(encodeURIComponent).join("/");
    }

    function run(path, schemeId, preview) {
        const args = [Quickshell.shellDir + "/scripts/set-wallpaper.sh"];
        if (preview)
            args.push("--preview");
        if (schemeId.length > 0)
            args.push("--scheme", schemeId);
        args.push(path);
        Quickshell.execDetached(args);
    }

    function apply(path) {
        if (!path)
            return;
        current = path;
        previewing = "";
        previewScheme = "";
        stateAdapter.appliedScheme = scheme;
        stateFile.writeAdapter();
        run(path, scheme, false);
    }

    function applySelected() {
        if (selectedIndex >= 0 && selectedIndex < filtered.length)
            apply(filtered[selectedIndex].path);
    }

    function previewSelected() {
        if (selectedIndex < 0 || selectedIndex >= filtered.length)
            return;
        const path = filtered[selectedIndex].path;
        if (path === current && scheme === appliedScheme) {
            restore();
            return;
        }
        if (path === previewing && scheme === previewScheme)
            return;
        previewing = path;
        previewScheme = scheme;
        run(path, scheme, true);
    }

    function restore() {
        if (!isPreviewing)
            return;
        previewing = "";
        previewScheme = "";
        if (current.length > 0)
            run(current, appliedScheme, true);
    }

    function cancel() {
        restore();
        scheme = appliedScheme;
    }

    function select(delta) {
        if (filtered.length === 0)
            return;
        selectedIndex = Math.max(0, Math.min(filtered.length - 1, selectedIndex + delta));
    }

    function cycleCategory(step) {
        const index = categories.indexOf(category);
        category = categories[(index + step + categories.length) % categories.length];
    }

    function cycleScheme(step) {
        const index = Math.max(0, schemes.findIndex(s => s.id === scheme));
        scheme = schemes[(index + step + schemes.length) % schemes.length].id;
    }

    FileView {
        id: stateFile
        path: Quickshell.statePath("wallpaper.json")
        printErrors: false

        JsonAdapter {
            id: stateAdapter
            property string appliedScheme: ""
        }
    }

    Process {
        id: scanProc
        command: ["sh", "-c", "test -d \"$1\" || exit 3; find -L \"$1\" -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' -o -iname '*.gif' \\) -printf '%P\\n' | sort -f", "sh", root.directory]
        onExited: exitCode => {
            root.directoryExists = exitCode !== 3;
            root.scanning = false;
        }
        stdout: StdioCollector {
            onStreamFinished: {
                const list = [];
                const found = [];
                const lines = text.split("\n").filter(line => line.length > 0);
                for (const relative of lines) {
                    const parts = relative.split("/");
                    const category = parts.length > 1 ? parts[0] : "Unsorted";
                    const file = parts[parts.length - 1];
                    list.push({
                        path: root.directory + "/" + relative,
                        name: file.replace(/\.[^.]+$/, "").replace(/[-_]+/g, " "),
                        category: category
                    });
                    if (!found.includes(category))
                        found.push(category);
                }
                found.sort((a, b) => a === "Unsorted" ? 1 : (b === "Unsorted" ? -1 : a.localeCompare(b)));
                root.wallpapers = list;
                root.categories = ["All"].concat(found);
                if (!root.categories.includes(root.category))
                    root.category = "All";
                root.selectedIndex = Math.max(0, root.filtered.findIndex(w => w.path === root.current));
            }
        }
    }

    Process {
        id: currentProc
        command: ["sh", "-c", "if command -v awww >/dev/null 2>&1; then awww query; else swww query; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.match(/image:\s*(.+)$/m);
                if (match)
                    root.current = match[1].trim();
            }
        }
    }
}
