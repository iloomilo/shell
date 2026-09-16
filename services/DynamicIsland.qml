pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
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

    readonly property var players: Mpris.players.values
    readonly property var activePlayer: {
        if (!players || players.length === 0)
            return null;
        for (let i = 0; i < players.length; i++) {
            if (players[i] && players[i].playbackState === MprisPlaybackState.Playing)
                return players[i];
        }
        for (let i = 0; i < players.length; i++) {
            if (players[i] && players[i].playbackState === MprisPlaybackState.Paused)
                return players[i];
        }
        return players[0] || null;
    }

    readonly property bool hasMedia: Boolean(activePlayer && (activePlayer.playbackState === MprisPlaybackState.Playing || activePlayer.playbackState === MprisPlaybackState.Paused) && trackTitle.length > 0)
    readonly property bool isMusicPlaying: Boolean(activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing)
    readonly property string trackTitle: activePlayer ? (activePlayer.trackTitle || "") : ""
    readonly property string trackArtist: activePlayer ? (activePlayer.trackArtist || "") : ""
    readonly property string trackAlbum: activePlayer ? (activePlayer.trackAlbum || "") : ""
    readonly property string trackArt: activePlayer ? (activePlayer.trackArtUrl || "") : ""
    readonly property string playerName: activePlayer ? (activePlayer.identity || "Media") : "Media"
    property real currentPosition: 0
    readonly property real length: activePlayer ? activePlayer.length : 0
    readonly property real progress: length > 0 ? Math.min(1.0, Math.max(0.0, currentPosition / length)) : 0
    readonly property bool isShuffle: Boolean(activePlayer && activePlayer.shuffle)
    readonly property var loopState: activePlayer ? activePlayer.loopState : MprisLoopState.None
    readonly property bool isLoop: Boolean(activePlayer && activePlayer.loopState !== MprisLoopState.None)
    readonly property bool isLoopTrack: Boolean(activePlayer && activePlayer.loopState === MprisLoopState.Track)
    readonly property string loopIcon: isLoopTrack ? "repeat_one" : "repeat"
    property var favoriteTracks: ({})
    readonly property string currentTrackKey: trackTitle + " - " + trackArtist
    readonly property bool isFavorite: Boolean(favoriteTracks[currentTrackKey])

    Timer {
        id: posTimer
        interval: 500
        running: root.isMusicPlaying
        repeat: true
        onTriggered: {
            if (root.activePlayer)
                root.currentPosition = root.activePlayer.position;
        }
    }

    property string lastTrackTitle: ""

    onHasMediaChanged: {
        if (hasMedia) {
            if (root.priority < 5) {
                root.mode = "media";
                root.priority = 5;
            }
        } else {
            if (root.mode === "media") {
                root.mode = "clock";
                root.priority = 0;
            }
        }
    }

    onTrackTitleChanged: {
        if (trackTitle !== lastTrackTitle && trackTitle.length > 0) {
            lastTrackTitle = trackTitle;
            if (root.priority < 5) {
                root.mode = "media";
                root.priority = 5;
            }
        }
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null
    readonly property real volume: audio ? audio.volume : 0.0
    readonly property bool muted: audio ? audio.muted : false

    property bool audioInitialized: false
    property bool suppressVolumeOsd: false

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
        if (!audioInitialized || suppressVolumeOsd)
            return;
        if (root.mode === "notification" && root.priority >= 30)
            return;
        root.triggerVolumeOsd();
    }

    onMutedChanged: {
        if (!audioInitialized || suppressVolumeOsd)
            return;
        if (root.mode === "notification" && root.priority >= 30)
            return;
        root.triggerVolumeOsd();
    }

    readonly property real brightness: Brightness.value

    onBrightnessChanged: {
        if (!Brightness.ready)
            return;
        if (root.mode === "notification" && root.priority >= 30)
            return;
        root.showOsd(Brightness.iconName, "Brightness", root.brightness, Math.round(root.brightness * 100) + "%");
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
            if (root.hasMedia) {
                root.mode = "media";
                root.priority = 5;
            } else {
                root.mode = "clock";
                root.priority = 0;
            }
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
        if (root.hasMedia) {
            root.mode = "media";
            root.priority = 5;
        } else {
            root.mode = "clock";
            root.priority = 0;
        }
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

    function togglePlay() {
        if (activePlayer && activePlayer.canTogglePlaying) {
            activePlayer.togglePlaying();
        }
    }

    function nextTrack() {
        if (activePlayer && activePlayer.canGoNext) {
            activePlayer.next();
        }
    }

    function previousTrack() {
        if (activePlayer && activePlayer.canGoPrevious) {
            activePlayer.previous();
        }
    }

    function seekRatio(ratio) {
        if (activePlayer && activePlayer.length > 0) {
            let target = Math.max(0, Math.min(activePlayer.length, ratio * activePlayer.length));
            try {
                activePlayer.position = target;
                currentPosition = target;
            } catch (e) {}
        }
    }

    function toggleFavorite() {
        if (!trackTitle)
            return;
        let favs = Object.assign({}, favoriteTracks);
        if (favs[currentTrackKey]) {
            delete favs[currentTrackKey];
        } else {
            favs[currentTrackKey] = true;
        }
        favoriteTracks = favs;
    }

    function toggleShuffle() {
        if (activePlayer && activePlayer.shuffleSupported) {
            activePlayer.shuffle = !activePlayer.shuffle;
        }
    }

    function toggleLoop() {
        if (!activePlayer || !activePlayer.loopSupported)
            return;
        if (activePlayer.loopState === MprisLoopState.None) {
            activePlayer.loopState = MprisLoopState.Playlist;
        } else if (activePlayer.loopState === MprisLoopState.Playlist) {
            activePlayer.loopState = MprisLoopState.Track;
        } else {
            activePlayer.loopState = MprisLoopState.None;
        }
    }

    Process {
        id: focusProc
    }

    function raisePlayer() {
        let id1 = (activePlayer && activePlayer.identity) ? activePlayer.identity : "";
        let id2 = (activePlayer && activePlayer.desktopEntry) ? activePlayer.desktopEntry : "";
        focusProc.command = ["python3", Quickshell.shellDir + "/scripts/focus_player.py", id1, id2];
        focusProc.running = true;
        if (activePlayer && activePlayer.canRaise) {
            try {
                activePlayer.raise();
            } catch (e) {}
        }
    }

    readonly property bool isLauncher: mode === "launcher"
    readonly property bool isWallpaper: mode === "wallpaper"
    readonly property bool isPicker: isLauncher || isWallpaper

    onIsWallpaperChanged: {
        if (!isWallpaper)
            WallpaperService.cancel();
    }

    function openLauncher() {
        mode = "launcher";
        priority = 100;
    }

    function closeLauncher() {
        if (mode === "launcher") {
            mode = hasMedia ? "media" : "clock";
            priority = hasMedia ? 5 : 0;
        }
    }

    function openWallpaper() {
        mode = "wallpaper";
        priority = 100;
        WallpaperService.refresh();
    }

    function closeWallpaper() {
        if (mode === "wallpaper") {
            mode = hasMedia ? "media" : "clock";
            priority = hasMedia ? 5 : 0;
        }
    }

    function toggleWallpaper() {
        if (isWallpaper) {
            closeWallpaper();
        } else {
            openWallpaper();
        }
    }

    function toggleLauncher() {
        if (isLauncher) {
            closeLauncher();
        } else {
            openLauncher();
        }
    }
}

