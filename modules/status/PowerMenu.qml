import QtQuick
import QtQuick.Layouts
import qs.services
import qs.theme
import qs.components

Item {
    id: root

    anchors.fill: parent

    signal actionTriggered()

    property int pendingIndex: -1
    property real pendingProgress: 0

    function trigger(index) {
        const action = Power.actions[index];
        if (!action.confirm) {
            run(index);
            return;
        }
        if (pendingIndex === index) {
            cancel();
            return;
        }
        pendingIndex = index;
        countdown.restart();
    }

    function cancel() {
        pendingIndex = -1;
        countdown.stop();
        pendingProgress = 0;
    }

    function run(index) {
        const action = Power.actions[index];
        cancel();
        root.actionTriggered();
        Power.run(action.command);
    }

    NumberAnimation {
        id: countdown
        target: root
        property: "pendingProgress"
        from: 0
        to: 1
        duration: 2000
        onFinished: {
            if (root.pendingIndex >= 0)
                root.run(root.pendingIndex);
        }
    }

    Connections {
        target: Power
        function onMenuOpenChanged() {
            if (!Power.menuOpen)
                root.cancel();
        }
    }

    component PowerTile: Rectangle {
        id: tile

        required property int actionIndex
        property bool danger: false

        readonly property var action: Power.actions[actionIndex]
        readonly property bool pending: root.pendingIndex === actionIndex
        readonly property color contentColor: danger ? Colors.on_error_container : Colors.on_secondary_container

        radius: tileHover.hovered || pending ? height / 2 : Metrics.radiusCard
        color: danger ? Colors.error_container : Colors.secondary_container

        Behavior on radius {
            NumberAnimation {
                duration: Motion.durationMedium1
                easing.type: Easing.Bezier
                easing.bezierCurve: Motion.emphasized
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: tile.pending ? Math.max(tile.radius * 2, parent.width * root.pendingProgress) : 0
            radius: tile.radius
            color: tile.danger ? Colors.error : Colors.primary
            opacity: 0.35
            visible: tile.pending
        }

        Rectangle {
            anchors.fill: parent
            radius: tile.radius
            color: tile.contentColor
            opacity: tileTap.pressed ? 0.12 : (tileHover.hovered ? 0.08 : 0.0)

            Behavior on opacity {
                NumberAnimation {
                    duration: Motion.durationShort2
                }
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 8

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                text: tile.pending ? "close" : tile.action.icon
                color: tile.contentColor
                font.pixelSize: Typography.sizeIconMedium + 2
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: tile.pending ? "Cancel" : tile.action.label
                color: tile.contentColor
                font.pixelSize: Typography.sizeBody + 1
                font.weight: Typography.weightMedium
            }
        }

        TapHandler {
            id: tileTap
            onTapped: root.trigger(tile.actionIndex)
        }

        HoverHandler {
            id: tileHover
            cursorShape: Qt.PointingHandCursor
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 2
        anchors.rightMargin: 2
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.bottomMargin: 4
            spacing: 12

            Rectangle {
                implicitWidth: 40
                implicitHeight: 40
                radius: width / 2
                color: Colors.primary_container

                StyledText {
                    anchors.centerIn: parent
                    text: Lock.displayName.charAt(0).toUpperCase()
                    color: Colors.on_primary_container
                    font.pixelSize: 18
                    font.weight: Font.Bold
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    text: Lock.displayName
                    color: Colors.on_surface
                    font.pixelSize: Typography.sizeHeader + 1
                    font.weight: Typography.weightBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                StyledText {
                    text: Power.uptimeText.length > 0 ? "Up " + Power.uptimeText : " "
                    color: Colors.on_surface_variant
                    font.pixelSize: Typography.sizeCaption
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 8
            columnSpacing: 8

            Repeater {
                model: [0, 2, 1, 3]

                PowerTile {
                    required property int modelData
                    actionIndex: modelData
                    Layout.fillWidth: true
                    implicitHeight: 56
                }
            }
        }

        PowerTile {
            actionIndex: 4
            danger: true
            Layout.fillWidth: true
            implicitHeight: 48
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
