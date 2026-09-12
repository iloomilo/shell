pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null
    readonly property real volume: audio ? audio.volume : 0.0
    readonly property bool muted: audio ? audio.muted : false

    readonly property string iconName: {
        if (!audio || muted || volume <= 0.001)
            return "volume_off";
        if (volume < 0.33)
            return "volume_mute";
        if (volume < 0.66)
            return "volume_down";
        return "volume_up";
    }

    readonly property var sinks: {
        let list = [];
        let nodes = Pipewire.nodes.values;
        if (!nodes) return list;
        for (let i = 0; i < nodes.length; i++) {
            let n = nodes[i];
            if (n && n.isSink) {
                list.push(n);
            }
        }
        return list;
    }

    PwObjectTracker {
        objects: [root.sink]
    }

    Process {
        id: wpctlProc
    }

    Timer {
        id: suppressTimer
        interval: 350
        repeat: false
        onTriggered: DynamicIsland.suppressVolumeOsd = false
    }

    function setVolume(val, suppressOsd = true) {
        if (suppressOsd) {
            DynamicIsland.suppressVolumeOsd = true;
            suppressTimer.restart();
        }
        if (root.audio) {
            let clamped = Math.max(0.0, Math.min(1.0, Math.round(val * 100) / 100));
            root.audio.volume = clamped;
            if (root.audio.muted && clamped > 0)
                root.audio.muted = false;
        }
    }

    function toggleMute(suppressOsd = true) {
        if (suppressOsd) {
            DynamicIsland.suppressVolumeOsd = true;
            suppressTimer.restart();
        }
        if (root.audio) {
            root.audio.muted = !root.audio.muted;
        }
    }

    function setDefaultSink(sinkId) {
        if (!sinkId)
            return;
        wpctlProc.command = ["wpctl", "set-default", sinkId.toString()];
        wpctlProc.running = true;
    }

    function cleanSinkName(sinkNode) {
        if (!sinkNode)
            return "Unknown Output";
        if (sinkNode.description && sinkNode.description.length > 0)
            return sinkNode.description;
        if (sinkNode.nickname && sinkNode.nickname.length > 0)
            return sinkNode.nickname;
        if (sinkNode.name && sinkNode.name.length > 0) {
            // Clean up common technical prefixes
            let n = sinkNode.name;
            n = n.replace(/^alsa_output\./, "").replace(/\.analog-stereo$/, "");
            return n.replace(/_/g, " ");
        }
        return "Audio Output " + sinkNode.id;
    }

    function sinkIcon(sinkNode) {
        if (!sinkNode)
            return "speaker";
        let str = ((sinkNode.description || "") + " " + (sinkNode.name || "") + " " + (sinkNode.nickname || "")).toLowerCase();
        if (str.includes("headphone") || str.includes("headset") || str.includes("earphone") || str.includes("airpod") || str.includes("buds"))
            return "headphones";
        if (str.includes("bluez") || str.includes("bluetooth"))
            return "bluetooth_audio";
        if (str.includes("hdmi") || str.includes("displayport") || str.includes("dp") || str.includes("tv"))
            return "tv";
        if (str.includes("usb"))
            return "usb";
        return "speaker";
    }
}
