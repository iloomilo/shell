pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Tracks niri's globally focused output so shell components can follow focus
// across monitors. niri does not expose focus through ext-workspace-v1 (every
// output has its own active workspace), so we listen to the IPC event stream.
Singleton {
    id: root

    // Name of the focused output, e.g. "DP-1". Empty until niri reports it.
    property string focusedOutput: ""

    // Screen matching the focused output. Falls back to the first screen while
    // waiting for niri, or if the focused output gets disconnected.
    readonly property var focusedScreen: {
        const match = Quickshell.screens.find(s => s.name === root.focusedOutput);
        if (match)
            return match;
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    // Workspace id -> output name, kept in sync from WorkspacesChanged.
    property var workspaceOutputs: ({})

    function handleEvent(line) {
        let event;
        try {
            event = JSON.parse(line);
        } catch (e) {
            return;
        }

        if (event.WorkspacesChanged) {
            const outputs = {};
            let focused = "";
            for (const ws of event.WorkspacesChanged.workspaces) {
                outputs[ws.id] = ws.output;
                if (ws.is_focused)
                    focused = ws.output;
            }
            root.workspaceOutputs = outputs;
            if (focused !== "")
                root.focusedOutput = focused;
        } else if (event.WorkspaceActivated && event.WorkspaceActivated.focused) {
            const output = root.workspaceOutputs[event.WorkspaceActivated.id];
            if (output !== undefined)
                root.focusedOutput = output;
        }
    }

    Process {
        id: eventStream
        command: ["niri", "msg", "-j", "event-stream"]
        running: true

        stdout: SplitParser {
            onRead: line => root.handleEvent(line)
        }

        // Reconnect if niri restarts or the stream drops.
        onExited: restartTimer.restart()
    }

    Timer {
        id: restartTimer
        interval: 1000
        repeat: false
        onTriggered: eventStream.running = true
    }
}
