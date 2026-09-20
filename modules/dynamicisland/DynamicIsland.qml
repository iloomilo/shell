import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.services
import qs.theme
import qs.components

Container {
    id: root

    property bool isHovered: false

    Timer {
        id: unhoverTimer
        interval: 350
        repeat: false
        onTriggered: root.isHovered = false
    }

    function formatTime(seconds) {
        if (!seconds || isNaN(seconds) || seconds < 0)
            return (DynamicIsland.length >= 3600) ? "0:00:00" : "0:00";
        let s = Math.floor(seconds % 60);
        let m = Math.floor(seconds / 60);
        let h = Math.floor(m / 60);
        m = m % 60;
        if (h > 0 || DynamicIsland.length >= 3600) {
            return h + ":" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
        }
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    readonly property bool isMediaExpanded: DynamicIsland.hasMedia && root.isHovered && DynamicIsland.mode !== "notification" && DynamicIsland.mode !== "osd" && !DynamicIsland.isPicker
    readonly property bool isMorphExpanding: DynamicIsland.isPicker || isMediaExpanded || DynamicIsland.mode === "notification" || DynamicIsland.mode === "osd"

    readonly property string activeView: {
        if (DynamicIsland.mode === "launcher")
            return "launcher";
        if (DynamicIsland.mode === "wallpaper")
            return "wallpaper";
        if (DynamicIsland.mode === "notification")
            return "notification";
        if (DynamicIsland.mode === "osd")
            return "osd";
        if (isMediaExpanded)
            return "media";
        return "compact";
    }

    property bool viewReady: true
    readonly property bool isCompactReady: activeView === "compact" && viewReady

    onActiveViewChanged: {
        viewReady = false;
        if (activeView === "launcher" || activeView === "wallpaper") {
            viewDelay.interval = 100;
        } else if (activeView === "compact") {
            viewDelay.interval = 250;
        } else {
            viewDelay.interval = Motion.contentStagger;
        }
        viewDelay.restart();
    }

    Timer {
        id: viewDelay
        repeat: false
        onTriggered: root.viewReady = true
    }

    property real morphProgress: activeView === "media" ? 1.0 : 0.0

    Behavior on morphProgress {
        MorphAnimation { expanding: root.isMorphExpanding }
    }

    height: {
        if (DynamicIsland.mode === "wallpaper")
            return 520;
        if (DynamicIsland.mode === "launcher")
            return 420;
        if (DynamicIsland.mode === "notification")
            return 50;
        if (isMediaExpanded)
            return 140;
        return Metrics.islandHeight;
    }

    width: {
        if (DynamicIsland.mode === "wallpaper")
            return 720;
        if (DynamicIsland.mode === "launcher")
            return 480;
        if (DynamicIsland.mode === "notification")
            return 340;
        if (DynamicIsland.mode === "osd")
            return 210;
        if (isMediaExpanded)
            return 310;
        if (DynamicIsland.hasMedia)
            return timeText.implicitWidth + 74;
        return timeText.implicitWidth + 28;
    }

    radius: (DynamicIsland.isPicker || isMediaExpanded || DynamicIsland.mode === "notification") ? Metrics.radiusContainer : Metrics.radiusPill
    clip: true

    Behavior on width {
        NumberAnimation {
            duration: (DynamicIsland.isPicker || root.activeView === "launcher" || root.activeView === "wallpaper") 
                ? (root.isMorphExpanding ? 250 : 200) 
                : (root.isMorphExpanding ? Motion.morphEnter : Motion.morphExit)
            easing.type: Easing.OutCubic
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: (DynamicIsland.isPicker || root.activeView === "launcher" || root.activeView === "wallpaper") 
                ? (root.isMorphExpanding ? 250 : 200) 
                : (root.isMorphExpanding ? Motion.morphEnter : Motion.morphExit)
            easing.type: Easing.OutCubic
        }
    }

    Behavior on radius {
        NumberAnimation {
            duration: (DynamicIsland.isPicker || root.activeView === "launcher" || root.activeView === "wallpaper") 
                ? (root.isMorphExpanding ? 250 : 200) 
                : (root.isMorphExpanding ? Motion.morphEnter : Motion.morphExit)
            easing.type: Easing.OutCubic
        }
    }

    Item {
        id: compactPillView
        anchors.fill: parent
        opacity: root.isCompactReady ? 1.0 : 0.0
        visible: opacity > 0

        transform: Translate {
            y: (root.activeView === "compact") ? timeText.entryY : 0
        }

        Behavior on opacity {
            NumberAnimation {
                duration: root.isCompactReady ? 180 : Motion.durationFast
                easing.type: Easing.OutCubic
            }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 8

            Rectangle {
                width: 18
                height: 18
                radius: 5
                color: Colors.surface_container_highest
                visible: DynamicIsland.hasMedia
                opacity: DynamicIsland.isMusicPlaying ? 1.0 : 0.65
                Layout.alignment: Qt.AlignVCenter

                Icon {
                    anchors.centerIn: parent
                    text: "music_note"
                    font.pixelSize: 12
                    color: Colors.primary
                }
            }

            Item {
                implicitWidth: timeText.implicitWidth
                implicitHeight: timeText.implicitHeight
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle {
                width: 18
                height: 18
                radius: 5
                color: Colors.surface_container_highest
                visible: DynamicIsland.hasMedia
                opacity: DynamicIsland.isMusicPlaying ? 1.0 : 0.65
                Layout.alignment: Qt.AlignVCenter
                antialiasing: true

                Item {
                    id: miniMask
                    anchors.fill: parent
                    layer.enabled: true
                    layer.smooth: true
                    layer.samples: 4
                    visible: false

                    Rectangle {
                        anchors.fill: parent
                        radius: 5
                        color: "black"
                        antialiasing: true
                    }
                }

                Image {
                    id: miniCover
                    anchors.fill: parent
                    source: DynamicIsland.trackArt
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    mipmap: true
                    smooth: true
                    antialiasing: true
                    visible: false
                }

                MultiEffect {
                    anchors.fill: parent
                    source: miniCover
                    maskEnabled: true
                    maskSource: miniMask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                    visible: miniCover.status === Image.Ready
                }

                Icon {
                    anchors.centerIn: parent
                    text: "music_note"
                    font.pixelSize: 12
                    color: Colors.primary
                    visible: miniCover.status !== Image.Ready
                }
            }
        }
    }

    StyledText {
        id: timeText
        text: Time.time
        font.pixelSize: Typography.sizeTitle
        font.weight: Typography.weightBold
        font.features: { "tnum": 1 }
        z: 10

        readonly property real compactX: DynamicIsland.hasMedia ? 37 : 14
        readonly property real expandedX: root.width - width - 12
        readonly property real compactY: (Metrics.islandHeight - height) / 2
        readonly property real expandedY: 12

        x: compactX + (expandedX - compactX) * root.morphProgress
        y: compactY + (expandedY - compactY) * root.morphProgress
        color: root.activeView === "media" ? Colors.on_surface_variant : Colors.on_surface
        opacity: (root.activeView === "media") ? 1.0 : (root.isCompactReady ? 1.0 : 0.0)
        visible: opacity > 0

        property real entryY: 0

        Connections {
            target: root
            function onActiveViewChanged() {
                if (root.activeView === "compact") {
                    timeText.entryY = 10;
                } else {
                    timeText.entryY = 0;
                }
            }
            function onViewReadyChanged() {
                if (root.activeView !== "compact" || !root.viewReady)
                    return;
                Qt.callLater(() => {
                    if (root.isCompactReady)
                        timeText.entryY = 0;
                });
            }
        }

        Behavior on entryY {
            enabled: root.isCompactReady
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        transform: Translate {
            y: (root.activeView === "compact") ? timeText.entryY : 0
        }

        Behavior on color {
            ColorAnimation { duration: Motion.durationNormal }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: root.isCompactReady ? 180 : Motion.durationFast
                easing.type: Easing.OutCubic
            }
        }
    }

    Item {
        id: expandedMediaView
        width: 310
        height: 140
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        opacity: (root.activeView === "media" && root.viewReady) ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.contentFade
                easing.type: Easing.Bezier
                easing.bezierCurve: Motion.standard
            }
        }

        WaveVisualizer {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 48
            active: DynamicIsland.isMusicPlaying
            color: Colors.primary
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    width: 44
                    height: 44
                    radius: Metrics.radiusCard
                    color: Colors.surface_container_highest
                    Layout.alignment: Qt.AlignVCenter
                    antialiasing: true

                    Item {
                        id: fullMask
                        anchors.fill: parent
                        layer.enabled: true
                        layer.smooth: true
                        layer.samples: 4
                        visible: false

                        Rectangle {
                            anchors.fill: parent
                            radius: Metrics.radiusCard
                            color: "black"
                            antialiasing: true
                        }
                    }

                    Image {
                        id: fullCover
                        anchors.fill: parent
                        source: DynamicIsland.trackArt
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        mipmap: true
                        smooth: true
                        antialiasing: true
                        visible: false
                    }

                    MultiEffect {
                        anchors.fill: parent
                        source: fullCover
                        maskEnabled: true
                        maskSource: fullMask
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1.0
                        visible: fullCover.status === Image.Ready
                    }

                    Icon {
                        anchors.centerIn: parent
                        text: "music_note"
                        font.pixelSize: 22
                        color: Colors.primary
                        visible: fullCover.status !== Image.Ready
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: DynamicIsland.raisePlayer()
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.rightMargin: timeText.width + 8
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    StyledText {
                        text: DynamicIsland.trackTitle.length > 0 ? DynamicIsland.trackTitle : "Playing"
                        font.pixelSize: Typography.sizeTitle
                        font.weight: Typography.weightBold
                        color: Colors.on_surface
                        elide: Text.ElideRight
                        Layout.fillWidth: true

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: DynamicIsland.raisePlayer()
                        }
                    }

                    StyledText {
                        text: DynamicIsland.trackArtist.length > 0 ? DynamicIsland.trackArtist : "Unknown Artist"
                        font.pixelSize: Typography.sizeCaption
                        color: Colors.on_surface_variant
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                StyledText {
                    id: positionText
                    text: root.formatTime(mediaSlider.isPressed ? (mediaSlider.dragValue * DynamicIsland.length) : DynamicIsland.currentPosition)
                    font.pixelSize: 10
                    font.features: { "tnum": 1 }
                    color: Colors.on_surface_variant
                    Layout.alignment: Qt.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    Layout.preferredWidth: Math.max(32, lengthText.implicitWidth)
                }

                Slider {
                    id: mediaSlider
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    trackHeight: 6
                    thumbWidth: 4
                    thumbHeight: 18
                    thumbPressedHeight: 22
                    gap: 3
                    implicitHeight: 24
                    value: DynamicIsland.progress
                    activeColor: Colors.primary
                    thumbColor: Colors.primary
                    inactiveColor: Colors.surface_container_highest
                    onCommitted: ratio => DynamicIsland.seekRatio(ratio)
                }

                StyledText {
                    id: lengthText
                    text: root.formatTime(DynamicIsland.length)
                    font.pixelSize: 10
                    font.features: { "tnum": 1 }
                    color: Colors.on_surface_variant
                    Layout.alignment: Qt.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: Math.max(32, implicitWidth)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                Item {
                    Layout.fillWidth: true
                }

                IconButton {
                    icon: "skip_previous"
                    pixelSize: 18
                    Layout.alignment: Qt.AlignVCenter
                    onClicked: DynamicIsland.previousTrack()
                }

                Rectangle {
                    id: playButton
                    width: 32
                    height: 32
                    radius: DynamicIsland.isMusicPlaying ? 10 : width / 2
                    color: playMouse.containsMouse ? Qt.lighter(Colors.primary, 1.15) : Colors.primary

                    Behavior on radius {
                        NumberAnimation {
                            duration: Motion.durationMedium1
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Motion.emphasized
                        }
                    }
                    scale: playMouse.pressed ? 0.92 : (playMouse.containsMouse ? 1.08 : 1.0)
                    Layout.alignment: Qt.AlignVCenter

                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.durationFast
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: Motion.durationShort2
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Motion.standard
                        }
                    }

                    Icon {
                        anchors.centerIn: parent
                        text: DynamicIsland.isMusicPlaying ? "pause" : "play_arrow"
                        font.pixelSize: 18
                        color: Colors.on_primary
                    }

                    MouseArea {
                        id: playMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: DynamicIsland.togglePlay()
                    }
                }

                IconButton {
                    icon: "skip_next"
                    pixelSize: 18
                    Layout.alignment: Qt.AlignVCenter
                    onClicked: DynamicIsland.nextTrack()
                }

                Item {
                    Layout.fillWidth: true
                }
            }
        }
    }

    Item {
        id: osdView
        anchors.fill: parent
        opacity: root.activeView === "osd" ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.contentFade
                easing.type: Easing.Bezier
                easing.bezierCurve: Motion.standard
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            OsdIcon {
                visible: DynamicIsland.osdKind !== ""
                kind: DynamicIsland.osdKind || "volume"
                value: DynamicIsland.osdValue
                muted: DynamicIsland.osdKind === "volume" && DynamicIsland.muted
                color: Colors.primary
                size: 18
                Layout.alignment: Qt.AlignVCenter
            }

            // Fallback for OSDs without a vector icon
            Icon {
                visible: DynamicIsland.osdKind === ""
                text: DynamicIsland.osdIcon
                color: Colors.primary
                font.pixelSize: 18
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                height: 6
                radius: Metrics.radiusSmall
                color: Colors.surface_container_highest

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * Math.min(1.0, Math.max(0.0, DynamicIsland.osdValue))
                    radius: Metrics.radiusSmall
                    color: Colors.primary

                    Behavior on width {
                        NumberAnimation {
                            duration: 100
                        }
                    }
                }
            }

            StyledText {
                text: DynamicIsland.osdText
                font.pixelSize: Typography.sizeCaption
                font.weight: Typography.weightBold
                color: Colors.on_surface_variant
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    Item {
        id: notifView
        anchors.fill: parent
        opacity: (root.activeView === "notification" && root.viewReady) ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.contentFade
                easing.type: Easing.Bezier
                easing.bezierCurve: Motion.standard
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            Rectangle {
                width: 32
                height: 32
                radius: Metrics.radiusSmall
                color: DynamicIsland.notifUrgency === 2 ? Colors.error_container : Colors.primary_container
                Layout.alignment: Qt.AlignVCenter

                Icon {
                    anchors.centerIn: parent
                    text: DynamicIsland.notifUrgency === 2 ? "priority_high" : "notifications"
                    color: DynamicIsland.notifUrgency === 2 ? Colors.error : Colors.primary
                    font.pixelSize: 18
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 1

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    StyledText {
                        text: DynamicIsland.notifSummary
                        font.pixelSize: Typography.sizeBody
                        font.weight: Typography.weightBold
                        color: Colors.on_surface
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    StyledText {
                        text: DynamicIsland.notifAppName
                        font.pixelSize: Typography.sizeSmall
                        color: Colors.outline
                        visible: text.length > 0
                    }
                }

                StyledText {
                    text: DynamicIsland.notifBody
                    font.pixelSize: Typography.sizeCaption
                    color: Colors.on_surface_variant
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    visible: text.length > 0
                }
            }

            IconButton {
                icon: "close"
                pixelSize: 16
                Layout.alignment: Qt.AlignVCenter
                onClicked: DynamicIsland.dismiss()
            }
        }
    }

    LauncherView {
        anchors.fill: parent
        opacity: (root.activeView === "launcher" && root.viewReady) ? 1.0 : 0.0
        scale: (root.activeView === "launcher" && root.viewReady) ? 1.0 : 0.96
        transformOrigin: Item.Center
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.durationNormal
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Motion.durationNormal
                easing.type: Easing.OutCubic
            }
        }
    }

    WallpaperView {
        anchors.fill: parent
        opacity: (root.activeView === "wallpaper" && root.viewReady) ? 1.0 : 0.0
        scale: (root.activeView === "wallpaper" && root.viewReady) ? 1.0 : 0.96
        transformOrigin: Item.Center
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.durationNormal
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Motion.durationNormal
                easing.type: Easing.OutCubic
            }
        }
    }

    TapHandler {
        enabled: DynamicIsland.mode === "notification"
        onTapped: DynamicIsland.dismiss()
    }

    HoverHandler {
        id: islandHover
        onHoveredChanged: {
            if (hovered) {
                unhoverTimer.stop();
                root.isHovered = true;
                if (DynamicIsland.mode === "notification") {
                    DynamicIsland.pauseTimer();
                }
            } else {
                unhoverTimer.restart();
                if (DynamicIsland.mode === "notification") {
                    DynamicIsland.resumeTimer();
                }
            }
        }
    }
}
