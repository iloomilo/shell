pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool powered: true
    property bool connected: false
    property string connectedDeviceName: ""
    property var devices: []
    property bool scanning: false

    readonly property string iconName: {
        if (!powered) return "bluetooth_disabled";
        if (connected) return "bluetooth_connected";
        return "bluetooth";
    }

    function check() {
        if (!statusProc.running) {
            statusProc.running = true;
        }
    }

    function scan(force, showIndicator) {
        let show = (showIndicator !== undefined) ? showIndicator : Boolean(force);
        if (show) {
            root.scanning = true;
            minScanTimer.restart();
        }
        if (!scanProc.running) {
            scanProc.running = true;
        }
    }

    Timer {
        id: minScanTimer
        interval: 800
        repeat: false
        onTriggered: {
            if (!scanProc.running) {
                root.scanning = false;
            }
        }
    }

    function togglePower() {
        if (toggleProc.running) toggleProc.running = false;
        toggleProc.running = true;
    }

    function connect(mac) {
        if (actionProc.running) actionProc.running = false;
        actionProc.command = ["python3", "/home/ilomilo/.config/quickshell/scripts/bluetooth.py", "connect", mac];
        actionProc.running = true;
    }

    function disconnect(mac) {
        if (actionProc.running) actionProc.running = false;
        actionProc.command = ["python3", "/home/ilomilo/.config/quickshell/scripts/bluetooth.py", "disconnect", mac];
        actionProc.running = true;
    }

    Process {
        id: statusProc
        command: ["python3", "/home/ilomilo/.config/quickshell/scripts/bluetooth.py", "status"]
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return;
                try {
                    let data = JSON.parse(text.trim());
                    root.powered = Boolean(data.powered);
                    let devs = data.devices || [];
                    root.devices = devs;
                    let hasConn = false;
                    let connName = "";
                    for (let i = 0; i < devs.length; ++i) {
                        if (devs[i].connected) {
                            hasConn = true;
                            connName = devs[i].name;
                            break;
                        }
                    }
                    root.connected = hasConn;
                    root.connectedDeviceName = connName;
                } catch (e) {}
            }
        }
    }

    Process {
        id: scanProc
        command: ["python3", "/home/ilomilo/.config/quickshell/scripts/bluetooth.py", "scan"]
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return;
                try {
                    let data = JSON.parse(text.trim());
                    root.powered = Boolean(data.powered);
                    root.devices = data.devices || [];
                } catch (e) {}
                if (!minScanTimer.running) {
                    root.scanning = false;
                }
            }
        }
        onExited: {
            if (!minScanTimer.running) {
                root.scanning = false;
            }
        }
    }

    Process {
        id: toggleProc
        command: ["python3", "/home/ilomilo/.config/quickshell/scripts/bluetooth.py", "toggle"]
        onExited: root.check()
    }

    Process {
        id: actionProc
        onExited: root.check()
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.check()
    }
}
