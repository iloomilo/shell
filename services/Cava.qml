pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string configPath: Quickshell.shellDir + "/scripts/cava.conf"
    readonly property int bars: 28

    property int refCount: 0
    property bool available: true

    property var values: {
        let out = [];
        for (let i = 0; i < bars; i++)
            out.push(0);
        return out;
    }

    readonly property bool running: proc.running
    readonly property bool shouldRun: refCount > 0 && available

    function acquire() {
        refCount++;
    }

    function release() {
        if (refCount > 0)
            refCount--;
    }

    onShouldRunChanged: {
        if (shouldRun)
            proc.running = true;
        else
            proc.running = false;
    }

    property bool didStart: false
    property int framesSeen: 0
    property int failedRestarts: 0

    Process {
        id: proc
        command: ["cava", "-p", root.configPath]

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: data => {
                if (!data)
                    return;

                const parts = data.split(";");
                const out = [];
                for (let i = 0; i < parts.length; i++) {
                    if (parts[i] === "")
                        continue;
                    const v = parseInt(parts[i], 10);
                    out.push(isNaN(v) ? 0 : Math.min(1, Math.max(0, v / 1000)));
                }

                if (out.length === 0)
                    return;

                root.framesSeen++;
                root.failedRestarts = 0;
                root.values = out;
            }
        }

        onStarted: {
            root.didStart = true;
            startWatchdog.stop();
        }

        onRunningChanged: {
            if (running) {
                root.didStart = false;
                root.framesSeen = 0;
                startWatchdog.restart();
                return;
            }

            startWatchdog.stop();

            if (!root.didStart) {
                root.available = false;
                return;
            }

            if (root.shouldRun) {
                root.failedRestarts++;
                if (root.failedRestarts > 3)
                    root.available = false;
                else
                    restartTimer.restart();
            }
        }
    }

    Timer {
        id: startWatchdog
        interval: 3000
        onTriggered: if (!root.didStart)
            root.available = false
    }

    Timer {
        id: restartTimer
        interval: 2000
        onTriggered: if (root.shouldRun)
            proc.running = true
    }
}
