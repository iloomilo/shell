pragma Singleton

import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    property string mode: "clock"
    property int priority: 0

    property string notifSummary: ""
    property string notifBody: ""
    property string notifAppName: ""
    property string notifIcon: ""
    property int notifUrgency: 1
    property var currentNotif: null

    property string osdIcon: ""
    property string osdTitle: ""
    property real osdValue: 0.0
    property string osdText: ""

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null
    readonly property real volume: audio ? audio.volume : 0.0
    readonly property bool muted: audio ? audio.muted : false

    property bool audioInitialized: false

    PwObjectTracker {
        objects: [root.sink]
    }

    Timer {
        interval: 1200
        running: true
        repeat: false
        onTriggered: root.audioInitialized = true
    }

    onVolumeChanged: {
        if (!audioInitialized)
            return;
        if (root.mode === "notification" && root.priority >= 30)
            return;
        root.triggerVolumeOsd();
    }

    onMutedChanged: {
        if (!audioInitialized)
            return;
        if (root.mode === "notification" && root.priority >= 30)
            return;
        root.triggerVolumeOsd();
    }

    NotificationServer {
        id: notifServer
        bodySupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: notif => {
            root.handleNotification(notif);
        }
    }

    Timer {
        id: displayTimer
        repeat: false
        onTriggered: {
            root.currentNotif = null;
            root.mode = "clock";
            root.priority = 0;
        }
    }

    function triggerVolumeOsd() {
        let icon = "volume_up";
        if (root.muted || root.volume <= 0.001) {
            icon = "volume_off";
        } else if (root.volume < 0.33) {
            icon = "volume_mute";
        } else if (root.volume < 0.66) {
            icon = "volume_down";
        }

        let valText = root.muted ? "Muted" : (Math.round(root.volume * 100) + "%");
        root.showOsd(icon, "Volume", root.muted ? 0.0 : root.volume, valText);
    }

    function showOsd(icon, title, value, valText) {
        if (root.mode === "notification" && root.priority >= 30)
            return;

        root.osdIcon = icon;
        root.osdTitle = title;
        root.osdValue = value;
        root.osdText = valText;
        root.mode = "osd";
        root.priority = 10;

        displayTimer.interval = 1800;
        displayTimer.restart();
    }

    function handleNotification(notif) {
        if (!notif)
            return;
        let urgencyVal = notif.urgency !== undefined ? notif.urgency : 1;
        let prio = urgencyVal === 2 ? 40 : 30;

        root.currentNotif = notif;
        root.notifSummary = notif.summary || "Notification";
        root.notifBody = notif.body || "";
        root.notifAppName = notif.appName || "";
        root.notifIcon = notif.appIcon || "notifications";
        root.notifUrgency = urgencyVal;

        root.mode = "notification";
        root.priority = prio;

        let duration = urgencyVal === 2 ? 8000 : 4500;
        displayTimer.interval = duration;
        displayTimer.restart();
    }

    function dismiss() {
        displayTimer.stop();
        if (root.currentNotif) {
            root.currentNotif.dismiss();
            root.currentNotif = null;
        }
        root.mode = "clock";
        root.priority = 0;
    }

    function pauseTimer() {
        displayTimer.stop();
    }

    function resumeTimer() {
        if (root.mode === "notification") {
            displayTimer.interval = 2500;
            displayTimer.restart();
        }
    }
}
