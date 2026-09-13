pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool menuOpen: false

    readonly property var actions: [
        { icon: "lock", label: "Lock", command: ["qs", "ipc", "call", "lock", "lock"] },
        { icon: "logout", label: "Log out", command: ["niri", "msg", "action", "quit", "--skip-confirmation"] },
        { icon: "bedtime", label: "Suspend", command: ["systemctl", "suspend"] },
        { icon: "restart_alt", label: "Restart", command: ["systemctl", "reboot"] },
        { icon: "power_settings_new", label: "Shut down", command: ["systemctl", "poweroff"] }
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
