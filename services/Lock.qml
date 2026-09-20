pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import QtQuick

Singleton {
    id: root

    property bool locked: false
    property string wallpaper: ""
    property string password: ""
    property bool authenticating: false
    property bool unlocking: false
    property bool failed: false
    property string message: ""
    readonly property string userName: Quickshell.env("USER") ?? ""
    property string realName: ""
    readonly property string displayName: realName.length > 0 ? realName : userName
    property string avatar: ""
    readonly property string greeting: {
        const hour = greetClock.date.getHours();
        if (hour >= 5 && hour < 12)
            return "Good morning";
        if (hour >= 12 && hour < 18)
            return "Good afternoon";
        if (hour >= 18 && hour < 23)
            return "Good evening";
        return "Good night";
    }

    signal authFailed()

    Component.onCompleted: {
        wallpaperProc.running = true;
        userProc.running = true;
        avatarProc.running = true;
        startupLockProc.running = true;
    }

    function lock() {
        if (locked || unlocking)
            return;
        password = "";
        failed = false;
        message = "";
        wallpaperProc.running = true;
        locked = true;
    }

    function tryUnlock() {
        if (authenticating || unlocking || password.length === 0)
            return;
        failed = false;
        message = "";
        authenticating = true;
        pam.start();
    }

    function releaseLock() {
        handoffTimer.stop();
        if (!locked)
            return;
        locked = false;
        safetyTimer.restart();
    }

    function finishUnlock() {
        safetyTimer.stop();
        unlocking = false;
        password = "";
        authenticating = false;
        failed = false;
        message = "";
        markUnlockedProc.running = true;
    }

    Timer {
        id: handoffTimer
        interval: 1000
        onTriggered: root.releaseLock()
    }

    Timer {
        id: safetyTimer
        interval: 3000
        onTriggered: root.finishUnlock()
    }

    PamContext {
        id: pam
        config: "login"

        onResponseRequiredChanged: {
            if (!responseRequired)
                return;
            respond(root.password);
        }

        onPamMessage: {
            if (messageIsError)
                root.message = message;
        }

        onCompleted: result => {
            root.authenticating = false;
            if (result === PamResult.Success) {
                root.unlocking = true;
                handoffTimer.restart();
                return;
            }
            root.password = "";
            root.failed = true;
            if (result === PamResult.MaxTries)
                root.message = "Too many attempts";
            else if (root.message.length === 0)
                root.message = "Wrong password";
            root.authFailed();
        }

        onError: error => {
            root.authenticating = false;
            root.password = "";
            root.failed = true;
            root.message = "Authentication error";
            root.authFailed();
        }
    }

    Process {
        id: wallpaperProc
        command: ["awww", "query"]
        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.match(/image:\s*(.+)$/m);
                if (match)
                    root.wallpaper = match[1].trim();
            }
        }
    }

    SystemClock {
        id: greetClock
        precision: SystemClock.Hours
    }

    Process {
        id: userProc
        command: ["getent", "passwd", root.userName]
        stdout: StdioCollector {
            onStreamFinished: {
                const gecos = (text.split(":")[4] || "").split(",")[0].trim();
                if (gecos.length > 0 && gecos !== root.userName)
                    root.realName = gecos;
            }
        }
    }

    Process {
        id: avatarProc
        command: ["sh", "-c", "test -r \"$HOME/.face\" && printf %s \"$HOME/.face\""]
        stdout: StdioCollector {
            onStreamFinished: root.avatar = text.length > 0 ? "file://" + text : ""
        }
    }

    Process {
        id: startupLockProc
        command: ["test", "-f", (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/quickshell-session-unlocked"]
        onExited: exitCode => {
            if (exitCode !== 0)
                root.lock();
        }
    }

    Process {
        id: markUnlockedProc
        command: ["touch", (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/quickshell-session-unlocked"]
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lock();
        }

        function isLocked(): bool {
            return root.locked;
        }
    }
}
