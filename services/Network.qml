pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool connected: false
    // Wired link is up (nmcli device type "ethernet").
    property bool ethernetConnected: false
    property string ssid: ""
    property int signal: 0
    property var networks: []
    property bool scanning: false
    property string connectingTo: ""
    property string failedSsid: ""

    // True when any link (wired or wireless) is up. `connected` stays Wi-Fi only
    // because the Wi-Fi menu and connect flow key off it.
    readonly property bool online: connected || ethernetConnected

    readonly property string iconName: {
        if (ethernetConnected) return "settings_ethernet";
        if (!connected) return "wifi_off";
        if (signal >= 75) return "wifi";
        if (signal >= 50) return "wifi_2_bar";
        return "wifi_1_bar";
    }

    readonly property alias networkModel: networkModel

    ListModel {
        id: networkModel
    }

    function syncNetworks(list) {
        for (let i = networkModel.count - 1; i >= 0; --i) {
            const ssid = networkModel.get(i).ssid;
            let stillThere = false;
            for (let j = 0; j < list.length; ++j) {
                if (list[j].ssid === ssid) {
                    stillThere = true;
                    break;
                }
            }
            if (!stillThere)
                networkModel.remove(i);
        }

        for (let k = 0; k < list.length; ++k) {
            const n = list[k];
            const entry = {
                ssid: n.ssid,
                strength: n.signal,
                inUse: n.inUse,
                locked: n.locked
            };

            let at = -1;
            for (let m = 0; m < networkModel.count; ++m) {
                if (networkModel.get(m).ssid === n.ssid) {
                    at = m;
                    break;
                }
            }

            if (at === -1) {
                networkModel.insert(Math.min(k, networkModel.count), entry);
            } else {
                if (at !== k && k < networkModel.count)
                    networkModel.move(at, k, 1);
                networkModel.set(k, entry);
            }
        }
    }

    function check() {
        if (!statusProc.running) {
            statusProc.running = true;
        }
        if (!devStatusProc.running) {
            devStatusProc.running = true;
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

    property var savedConnections: []

    function isSaved(targetSsid) {
        if (!targetSsid || !savedConnections) return false;
        return savedConnections.indexOf(targetSsid) !== -1;
    }

    function updateSaved() {
        if (!savedProc.running) {
            savedProc.running = true;
        }
    }

    function connect(targetSsid, password) {
        if (connectProc.running)
            return;
        root.failedSsid = "";
        root.connectingTo = targetSsid;
        if (password && password.length > 0) {
            connectProc.command = ["nmcli", "dev", "wifi", "connect", targetSsid, "password", password];
        } else {
            connectProc.command = ["nmcli", "dev", "wifi", "connect", targetSsid];
        }
        connectProc.running = true;
    }

    Process {
        id: savedProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onTextChanged: {
                let lines = text.trim().split("\n");
                let list = [];
                for (let i = 0; i < lines.length; i++) {
                    let parts = lines[i].split(":");
                    if (parts.length >= 2 && parts[1] === "802-11-wireless" && parts[0]) {
                        list.push(parts[0]);
                    }
                }
                root.savedConnections = list;
            }
        }
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
        id: devStatusProc
        command: ["nmcli", "-t", "-f", "TYPE,STATE", "dev", "status"]
        stdout: StdioCollector {
            onTextChanged: {
                let lines = text.trim().split("\n");
                let wired = false;
                for (let i = 0; i < lines.length; ++i) {
                    const parts = lines[i].split(":");
                    if (parts[0] === "ethernet" && parts[1] === "connected") {
                        wired = true;
                        break;
                    }
                }
                root.ethernetConnected = wired;
            }
        }
    }

    // NetworkManager streams device/connection changes; react immediately
    // instead of waiting for the periodic poll.
    Process {
        id: monitorProc
        command: ["nmcli", "monitor"]
        running: true

        stdout: SplitParser {
            onRead: line => monitorDebounce.restart()
        }

        onExited: monitorRestart.restart()
    }

    Timer {
        id: monitorDebounce
        interval: 250
        repeat: false
        onTriggered: root.check()
    }

    Timer {
        id: monitorRestart
        interval: 2000
        repeat: false
        onTriggered: monitorProc.running = true
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
                root.syncNetworks(list);
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
        stderr: StdioCollector {}
        onExited: exitCode => {
            if (exitCode !== 0) {
                root.failedSsid = root.connectingTo;
                failedResetTimer.restart();
            }
            root.connectingTo = "";
            root.check();
            root.updateSaved();
            root.scan(true);
        }
    }

    Timer {
        id: failedResetTimer
        interval: 4000
        repeat: false
        onTriggered: root.failedSsid = ""
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.check();
            root.updateSaved();
            root.scan(false, false);
        }
    }
}
