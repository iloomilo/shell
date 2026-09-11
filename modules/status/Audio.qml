import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.theme
import qs.components

RowLayout {
    id: root
    spacing: 0

    property bool expanded: false

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

    function resetTimer() {
        if (autoCloseTimer.running || root.expanded) {
            autoCloseTimer.restart();
        }
    }

    PwObjectTracker {
        objects: [root.sink]
    }

    Timer {
        id: autoCloseTimer
        interval: 3000
        repeat: false
        onTriggered: {
            if (!moduleHover.hovered) {
                root.expanded = false;
            }
        }
    }

    HoverHandler {
        id: moduleHover
        onHoveredChanged: {
            if (!hovered && root.expanded) {
                autoCloseTimer.restart();
            } else if (hovered) {
                autoCloseTimer.stop();
            }
        }
    }

    onExpandedChanged: {
        if (expanded && !moduleHover.hovered) {
            autoCloseTimer.restart();
        } else if (!expanded) {
            autoCloseTimer.stop();
        }
    }

    Icon {
        id: iconText
        text: root.iconName
        color: root.muted ? Colors.error : (hover.hovered ? Colors.on_surface : Colors.on_surface_variant)
        Layout.alignment: Qt.AlignVCenter

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        TapHandler {
            onTapped: root.expanded = !root.expanded
        }

        WheelHandler {
            enabled: Boolean(root.audio)
            orientation: Qt.Vertical
            onWheel: event => {
                if (!root.audio)
                    return;
                let step = (event.angleDelta.y > 0 ? 0.05 : -0.05);
                root.audio.volume = Math.max(0.0, Math.min(1.0, root.audio.volume + step));
                root.expanded = true;
                root.resetTimer();
            }
        }

        HoverHandler {
            id: hover
            cursorShape: Qt.PointingHandCursor
        }
    }

    Item {
        id: sliderContainer
        clip: true
        Layout.alignment: Qt.AlignVCenter
        implicitHeight: 20
        implicitWidth: root.expanded ? 128 : 0
        width: implicitWidth
        Layout.preferredWidth: implicitWidth
        opacity: root.expanded ? 1.0 : 0.0

        Behavior on implicitWidth {
            NumberAnimation {
                duration: Motion.durationMorph
                easing.type: Motion.easingStandard
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.durationNormal
            }
        }

        Rectangle {
            id: track
            x: 8
            width: Math.max(0, parent.width - 8)
            anchors.verticalCenter: parent.verticalCenter
            height: 6
            radius: 3
            color: Colors.surface_container_highest

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * Math.min(1.0, Math.max(0.0, root.volume))
                radius: 3
                color: root.muted ? Colors.error : Colors.primary

                Behavior on color {
                    ColorAnimation {
                        duration: Motion.durationNormal
                    }
                }
            }

            MouseArea {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 22
                cursorShape: Qt.PointingHandCursor
                preventStealing: true

                function updateVolume(mouse) {
                    if (!root.audio)
                        return;
                    let pos = Math.max(0, Math.min(track.width, mouse.x));
                    let val = track.width > 0 ? (pos / track.width) : 0;
                    root.audio.volume = Math.round(val * 100) / 100;
                    if (root.audio.muted)
                        root.audio.muted = false;
                    root.resetTimer();
                }

                onPressed: mouse => updateVolume(mouse)
                onPositionChanged: mouse => {
                    if (pressed)
                        updateVolume(mouse);
                }
                onReleased: root.resetTimer()
            }
        }
    }
}
