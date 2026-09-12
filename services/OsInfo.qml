pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string name: "Linux"
    property string prettyName: "Linux"
    property string id: ""
    property string logo: ""
    property string kernel: ""

    readonly property bool hasLogo: logo.length > 0
    readonly property url logoUrl: logo.length > 0 ? "file://" + logo : ""

    Process {
        running: true
        command: ["python3", Quickshell.shellDir + "/scripts/os_logo.py"]

        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0)
                    return;
                try {
                    const data = JSON.parse(text.trim());
                    root.name = data.name || "Linux";
                    root.prettyName = data.prettyName || root.name;
                    root.id = data.id || "";
                    root.logo = data.logo || "";
                    root.kernel = data.kernel || "";
                } catch (e) {}
            }
        }
    }
}
