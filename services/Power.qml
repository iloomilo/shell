pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool menuOpen: false

    readonly property var actions: [
        { icon: "lock", label: "Lock", command: ["qs", "ipc", "call", "lock", "lock"] },
        { icon: "logout", label: "Log out", confirm: true, command: ["niri", "msg", "action", "quit", "--skip-confirmation"] },
        { icon: "bedtime", label: "Suspend", command: ["systemctl", "suspend"] },
        { icon: "restart_alt", label: "Restart", confirm: true, command: ["systemctl", "reboot"] },
        { icon: "power_settings_new", label: "Shut down", confirm: true, command: ["systemctl", "poweroff"] }
    ]

    function open() {
        menuOpen = true;
    }

    function close() {
        menuOpen = false;
    }

    function toggle() {
        menuOpen = !menuOpen;
    }

    function run(command) {
        if (!command || command.length === 0)
            return;
        menuOpen = false;
        proc.command = command;
        proc.running = true;
    }

    property string uptimeText: ""

    Timer {
        interval: 60000
        running: root.menuOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: uptimeProc.running = true
    }

    Process {
        id: uptimeProc
        command: ["cat", "/proc/uptime"]
        stdout: StdioCollector {
            onStreamFinished: {
                const total = Math.floor(parseFloat(text.split(" ")[0]) || 0);
                const days = Math.floor(total / 86400);
                const hours = Math.floor((total % 86400) / 3600);
                const minutes = Math.floor((total % 3600) / 60);
                if (days > 0)
                    root.uptimeText = days + " d " + hours + " h";
                else if (hours > 0)
                    root.uptimeText = hours + " h " + minutes + " min";
                else
                    root.uptimeText = minutes + " min";
            }
        }
    }

    IpcHandler {
        target: "power"

        function toggle(): void {
            root.toggle();
        }

        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }
    }

    Process {
        id: proc
    }
}
