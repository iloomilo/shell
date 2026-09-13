import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.services
import qs.theme
import qs.components

Item {
    id: root

    property bool tinted: true
    property color tint: hover.hovered ? Colors.on_surface : Colors.on_surface_variant

    property bool showTooltip: false
    property bool tooltipOpen: false

    implicitWidth: 20
    implicitHeight: 20

    Item {
        id: logo
        anchors.centerIn: parent
        width: 18
        height: 18
        visible: OsInfo.hasLogo && logoSource.status === Image.Ready
        scale: hover.hovered ? 1.12 : 1.0

        Behavior on scale {
            NumberAnimation {
                duration: Motion.durationShort2
                easing.type: Easing.Bezier
                easing.bezierCurve: Motion.standard
            }
        }

        Image {
            id: logoSource
            anchors.fill: parent
            source: OsInfo.logoUrl
            sourceSize.width: 36
            sourceSize.height: 36
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: false
            visible: !root.tinted
            layer.enabled: root.tinted
        }

        Rectangle {
            id: tintSource
            anchors.fill: parent
            color: root.tint
            visible: false
            layer.enabled: true

            Behavior on color {
                ColorAnimation { duration: Motion.durationNormal }
            }
        }

        MultiEffect {
            anchors.fill: parent
            source: tintSource
            maskEnabled: true
            maskSource: logoSource
            visible: root.tinted
        }
    }

    Icon {
        anchors.centerIn: parent
        text: "terminal"
        color: root.tint
        visible: !logo.visible
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
        onHoveredChanged: {
            if (hovered) {
                tooltipHide.stop();
                tooltipDelay.restart();
            } else {
                tooltipDelay.stop();
                root.tooltipOpen = false;
                if (root.showTooltip)
                    tooltipHide.restart();
            }
        }
    }

    Timer {
        id: tooltipDelay
        interval: 350
        repeat: false
        onTriggered: {
            root.showTooltip = true;
            root.tooltipOpen = true;
        }
    }

    Timer {
        id: tooltipHide
        interval: Motion.durationShort4
        repeat: false
        onTriggered: root.showTooltip = false
    }

    PopupWindow {
        visible: root.showTooltip
        color: "transparent"
        implicitWidth: card.implicitWidth
        implicitHeight: card.implicitHeight

        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 14

        Rectangle {
            id: card
            implicitWidth: cardContent.implicitWidth + 24
            implicitHeight: cardContent.implicitHeight + 16
            radius: Metrics.radiusContainer
            color: Colors.surface_container

            transformOrigin: Item.Top
            opacity: root.tooltipOpen ? 1.0 : 0.0
            scale: root.tooltipOpen ? 1.0 : 0.88

            Behavior on opacity {
                NumberAnimation {
                    duration: Motion.durationShort3
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.emphasized
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: Motion.durationShort4
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.emphasized
                }
            }

            ColumnLayout {
                id: cardContent
                anchors.centerIn: parent
                spacing: 2

                StyledText {
                    text: OsInfo.prettyName
                    color: Colors.on_surface
                    font.pixelSize: Typography.sizeTitle
                    font.weight: Typography.weightBold
                    Layout.alignment: Qt.AlignHCenter
                }

                StyledText {
                    text: OsInfo.kernel
                    color: Colors.on_surface_variant
                    font.pixelSize: Typography.sizeCaption
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}
