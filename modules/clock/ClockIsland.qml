import QtQuick
import QtQuick.Layouts
import qs.services
import qs.theme
import qs.components

GlassContainer {
    id: root
    height: DynamicIsland.mode === "notification" ? 50 : Metrics.islandHeight
    width: {
        if (DynamicIsland.mode === "notification")
            return 340;
        if (DynamicIsland.mode === "osd")
            return 210;
        return timeText.implicitWidth + 28;
    }
    radius: DynamicIsland.mode === "notification" ? Metrics.radiusContainer : Metrics.radiusPill
    clip: true

    Behavior on width {
        SpringAnimation {
            spring: Motion.springStiffness
            damping: Motion.springDamping
            epsilon: Motion.springEpsilon
        }
    }

    Behavior on height {
        SpringAnimation {
            spring: Motion.springStiffness
            damping: Motion.springDamping
            epsilon: Motion.springEpsilon
        }
    }

    Behavior on radius {
        SpringAnimation {
            spring: Motion.springStiffness
            damping: Motion.springDamping
            epsilon: Motion.springEpsilon
        }
    }

    Item {
        id: clockView
        anchors.fill: parent
        opacity: DynamicIsland.mode === "clock" ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.durationNormal
            }
        }

        StyledText {
            id: timeText
            anchors.centerIn: parent
            text: Time.time
            font.pixelSize: Typography.sizeTitle
            font.weight: Typography.weightBold
        }
    }

    Item {
        id: osdView
        anchors.fill: parent
        opacity: DynamicIsland.mode === "osd" ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.durationNormal
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
        opacity: DynamicIsland.mode === "notification" ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.durationNormal
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
            if (DynamicIsland.mode === "notification") {
                if (hovered) {
                    DynamicIsland.pauseTimer();
                } else {
                    DynamicIsland.resumeTimer();
                }
            }
        }
    }
}
