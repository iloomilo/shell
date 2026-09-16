pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // Backlight device under /sys/class/backlight
    property string device: "intel_backlight"

    property int current: 0
    property int max: 0
    readonly property real value: max > 0 ? current / max : 0.0
    // Becomes true after the first read, so the initial value doesn't trigger an OSD
    property bool ready: false

    readonly property string iconName: {
        if (value < 0.33)
            return "brightness_low";
        if (value < 0.66)
            return "brightness_medium";
        return "brightness_high";
    }

    function refresh() {
        readProc.running = true;
    }

    // sysfs attributes don't emit inotify events, so listen for kernel uevents instead
    Process {
        id: monitorProc
        command: ["udevadm", "monitor", "--kernel", "--subsystem-match=backlight"]
        running: true

        stdout: SplitParser {
            onRead: line => {
                if (line.indexOf(" change ") !== -1 && line.indexOf("/" + root.device + " ") !== -1)
                    root.refresh();
            }
        }

        // Restart if udevadm exits unexpectedly
        onExited: restartTimer.restart()
    }

    Timer {
        id: restartTimer
        interval: 2000
        onTriggered: monitorProc.running = true
    }

    Process {
        id: readProc
        command: ["cat", "/sys/class/backlight/" + root.device + "/brightness", "/sys/class/backlight/" + root.device + "/max_brightness"]

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("\n");
                if (parts.length < 2)
                    return;
                const cur = parseInt(parts[0]);
                const mx = parseInt(parts[1]);
                if (isNaN(cur) || isNaN(mx))
                    return;
                root.max = mx;
                root.current = cur;
                root.ready = true;
            }
        }
    }

    Component.onCompleted: refresh()
}
