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
            return "0:00";
        let m = Math.floor(seconds / 60);
        let s = Math.floor(seconds % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    readonly property bool isMediaExpanded: DynamicIsland.hasMedia && root.isHovered && DynamicIsland.mode !== "notification" && DynamicIsland.mode !== "osd"
    readonly property bool isMorphExpanding: isMediaExpanded || DynamicIsland.mode === "notification" || DynamicIsland.mode === "osd"

    readonly property string activeView: {
        if (DynamicIsland.mode === "notification")
            return "notification";
        if (DynamicIsland.mode === "osd")
            return "osd";
        if (isMediaExpanded)
            return "media";
        return "compact";
    }

    property bool viewReady: true

    onActiveViewChanged: {
        viewReady = false;
        viewDelay.interval = activeView === "compact" ? Motion.collapseStagger : Motion.contentStagger;
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
        if (DynamicIsland.mode === "notification")
            return 50;
        if (isMediaExpanded)
            return 140;
        return Metrics.islandHeight;
    }

    width: {
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

    radius: (isMediaExpanded || DynamicIsland.mode === "notification") ? Metrics.radiusContainer : Metrics.radiusPill
    clip: true

    Behavior on width {
        MorphAnimation { expanding: root.isMorphExpanding }
    }

    Behavior on height {
        MorphAnimation { expanding: root.isMorphExpanding }
    }

    Behavior on radius {
        MorphAnimation { expanding: root.isMorphExpanding }
    }

    Item {
        id: compactPillView
        anchors.fill: parent
        opacity: (root.activeView === "compact" && root.viewReady) ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.contentFade
                easing.type: Easing.Bezier
                easing.bezierCurve: Motion.standard
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

                Item {
                    id: miniMask
                    anchors.fill: parent
                    layer.enabled: true
                    visible: false

                    Rectangle {
                        anchors.fill: parent
                        radius: 5
                        color: "black"
                    }
                }

                Image {
                    id: miniCover
                    anchors.fill: parent
                    source: DynamicIsland.trackArt
                    fillMode: Image.PreserveAspectCrop
                    visible: false
                }

                MultiEffect {
                    anchors.fill: parent
                    source: miniCover
                    maskEnabled: true
                    maskSource: miniMask
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
        z: 10

        readonly property real compactX: DynamicIsland.hasMedia ? 37 : 14
        readonly property real expandedX: root.width - width - 12
        readonly property real compactY: (Metrics.islandHeight - height) / 2
        readonly property real expandedY: 12

        x: compactX + (expandedX - compactX) * root.morphProgress
        y: compactY + (expandedY - compactY) * root.morphProgress
        color: root.activeView === "media" ? Colors.on_surface_variant : Colors.on_surface
        opacity: (root.activeView === "compact" || root.activeView === "media") ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on color {
            ColorAnimation { duration: Motion.durationNormal }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.contentFade
                easing.type: Easing.Bezier
                easing.bezierCurve: Motion.standard
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

                    Item {
                        id: fullMask
                        anchors.fill: parent
                        layer.enabled: true
                        visible: false

                        Rectangle {
                            anchors.fill: parent
                            radius: Metrics.radiusCard
                            color: "black"
                        }
                    }

                    Image {
                        id: fullCover
                        anchors.fill: parent
                        source: DynamicIsland.trackArt
                        fillMode: Image.PreserveAspectCrop
                        visible: false
                    }

                    MultiEffect {
                        anchors.fill: parent
                        source: fullCover
                        maskEnabled: true
                        maskSource: fullMask
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
                    text: root.formatTime(seekTrack.isDragging ? (seekTrack.dragProgress * DynamicIsland.length) : DynamicIsland.currentPosition)
                    font.pixelSize: 10
                    color: Colors.on_surface_variant
                    Layout.alignment: Qt.AlignVCenter
                }

                Rectangle {
                    id: seekTrack
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    height: 4
                    radius: 2
                    color: Colors.surface_container_highest

                    property bool isDragging: false
                    property real dragProgress: 0.0

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * Math.min(1.0, Math.max(0.0, seekTrack.isDragging ? seekTrack.dragProgress : DynamicIsland.progress))
                        radius: 2
                        color: Colors.primary
                    }

                    Rectangle {
                        width: 10
                        height: 10
                        radius: 5
                        color: Colors.primary
                        x: Math.max(0, Math.min(parent.width - width, parent.width * (seekTrack.isDragging ? seekTrack.dragProgress : DynamicIsland.progress) - 5))
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    MouseArea {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.topMargin: -10
                        anchors.bottomMargin: -10
                        cursorShape: Qt.PointingHandCursor
                        preventStealing: true

                        onPressed: mouse => {
                            seekTrack.isDragging = true;
                            seekTrack.dragProgress = Math.max(0, Math.min(seekTrack.width, mouse.x)) / (seekTrack.width || 1);
                        }

                        onPositionChanged: mouse => {
                            if (pressed) {
                                seekTrack.dragProgress = Math.max(0, Math.min(seekTrack.width, mouse.x)) / (seekTrack.width || 1);
                            }
                        }

                        onReleased: mouse => {
                            if (seekTrack.isDragging) {
                                let ratio = Math.max(0, Math.min(seekTrack.width, mouse.x)) / (seekTrack.width || 1);
                                DynamicIsland.seekRatio(ratio);
                                seekTrack.isDragging = false;
                            }
                        }

                        onCanceled: seekTrack.isDragging = false
                    }
                }

                StyledText {
                    text: root.formatTime(DynamicIsland.length)
                    font.pixelSize: 10
                    color: Colors.on_surface_variant
                    Layout.alignment: Qt.AlignVCenter
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
                    radius: Metrics.radiusPill
                    color: playMouse.containsMouse ? Qt.lighter(Colors.primary, 1.15) : Colors.primary
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

            Icon {
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
