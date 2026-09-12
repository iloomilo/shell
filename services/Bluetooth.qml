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
    property string busyMac: ""

    readonly property string iconName: {
        if (!powered) return "bluetooth_disabled";
        if (connected) return "bluetooth_connected";
        return "bluetooth";
    }

    readonly property alias deviceModel: deviceModel

    ListModel {
        id: deviceModel
    }

    function syncDevices(list) {
        for (let i = deviceModel.count - 1; i >= 0; --i) {
            const mac = deviceModel.get(i).mac;
            let stillThere = false;
            for (let j = 0; j < list.length; ++j) {
                if (list[j].mac === mac) {
                    stillThere = true;
                    break;
                }
            }
            if (!stillThere)
                deviceModel.remove(i);
        }

        for (let k = 0; k < list.length; ++k) {
            const d = list[k];
            const entry = {
                mac: d.mac || "",
                name: d.name || "",
                deviceIcon: d.icon || "bluetooth",
                connected: Boolean(d.connected),
                paired: Boolean(d.paired),
                battery: (d.battery === undefined || d.battery === null) ? -1 : d.battery
            };

            let at = -1;
            for (let m = 0; m < deviceModel.count; ++m) {
                if (deviceModel.get(m).mac === entry.mac) {
                    at = m;
                    break;
                }
            }

            if (at === -1) {
                deviceModel.insert(Math.min(k, deviceModel.count), entry);
            } else {
                if (at !== k && k < deviceModel.count)
                    deviceModel.move(at, k, 1);
                deviceModel.set(k, entry);
            }
        }
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
        root.busyMac = mac;
        actionProc.command = ["python3", Quickshell.shellDir + "/scripts/bluetooth.py", "connect", mac];
        actionProc.running = true;
    }

    function disconnect(mac) {
        if (actionProc.running) actionProc.running = false;
        root.busyMac = mac;
        actionProc.command = ["python3", Quickshell.shellDir + "/scripts/bluetooth.py", "disconnect", mac];
        actionProc.running = true;
    }

    Process {
        id: statusProc
        command: ["python3", Quickshell.shellDir + "/scripts/bluetooth.py", "status"]
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return;
                try {
                    let data = JSON.parse(text.trim());
                    root.powered = Boolean(data.powered);
                    let devs = data.devices || [];
                    root.devices = devs;
                    root.syncDevices(devs);
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
        command: ["python3", Quickshell.shellDir + "/scripts/bluetooth.py", "scan"]
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return;
                try {
                    let data = JSON.parse(text.trim());
                    root.powered = Boolean(data.powered);
                    root.devices = data.devices || [];
                    root.syncDevices(root.devices);
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
        command: ["python3", Quickshell.shellDir + "/scripts/bluetooth.py", "toggle"]
        onExited: root.check()
    }

    Process {
        id: actionProc
        onExited: {
            root.busyMac = "";
            root.check();
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.check()
    }
}
