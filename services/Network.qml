pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool connected: false
    property string ssid: ""
    property int signal: 0
    property var networks: []
    property bool scanning: false

    readonly property string iconName: {
        if (!connected) return "wifi_off";
        if (signal >= 75) return "wifi";
        if (signal >= 50) return "wifi_2_bar";
        return "wifi_1_bar";
    }

    function check() {
        if (!statusProc.running) {
            statusProc.running = true;
        }
    }

    function scan(force, showIndicator) {
        if (!scanProc.running) {
            let show = (showIndicator !== undefined) ? showIndicator : Boolean(force);
            if (show) {
                root.scanning = true;
                minScanTimer.restart();
            }
            scanProc.command = ["nmcli", "-t", "-f", "in-use,ssid,signal,security", "dev", "wifi", "list", "--rescan", force ? "yes" : "auto"];
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

    function connect(targetSsid) {
        connectProc.command = ["nmcli", "dev", "wifi", "connect", targetSsid];
        connectProc.running = true;
    }

    Process {
        id: statusProc
        command: ["nmcli", "-t", "-f", "active,ssid,signal", "dev", "wifi"]
        stdout: StdioCollector {
            onTextChanged: {
                let lines = text.trim().split("\n");
                let found = false;
                for (let i = 0; i < lines.length; ++i) {
                    let parts = lines[i].split(":");
                    if (parts[0] === "yes") {
                        root.connected = true;
                        root.ssid = parts[1] || "";
                        root.signal = parseInt(parts[2], 10) || 0;
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    root.connected = false;
                    root.ssid = "";
                    root.signal = 0;
                }
            }
        }
    }

    Process {
        id: scanProc
        command: ["nmcli", "-t", "-f", "in-use,ssid,signal,security", "dev", "wifi", "list", "--rescan", "auto"]
        stdout: StdioCollector {
            onTextChanged: {
                let lines = text.trim().split("\n");
                let list = [];
                let seen = {};
                for (let i = 0; i < lines.length; ++i) {
                    let parts = lines[i].split(":");
                    if (parts.length < 3) continue;
                    let inUse = parts[0] === "*";
                    let netSsid = parts[1];
                    if (!netSsid || netSsid === "--" || seen[netSsid]) continue;
                    seen[netSsid] = true;
                    let sig = parseInt(parts[2], 10) || 0;
                    let sec = parts[3] || "";
                    list.push({
                        inUse: inUse,
                        ssid: netSsid,
                        signal: sig,
                        locked: Boolean(sec && sec.length > 0)
                    });
                }
                root.networks = list;
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
        id: connectProc
        onExited: {
            root.check();
            root.scan(true);
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.check();
            root.scan(false, false);
        }
    }
}
