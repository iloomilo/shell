import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.services
import qs.theme
import qs.components

Item {
    id: root

    anchors.fill: parent
    anchors.margins: 14

    readonly property int columns: 4

    onVisibleChanged: {
        if (visible)
            focusTimer.restart();
        else
            previewTimer.stop();
    }

    Timer {
        id: previewTimer
        interval: 1000
        onTriggered: WallpaperService.previewSelected()
    }

    Connections {
        target: WallpaperService
        function onSelectedIndexChanged() {
            if (root.visible)
                previewTimer.restart();
        }
        function onCategoryChanged() {
            if (root.visible)
                previewTimer.restart();
        }
        function onSchemeChanged() {
            if (root.visible)
                previewTimer.restart();
        }
    }

    Timer {
        id: focusTimer
        interval: 30
        onTriggered: keyHandler.forceActiveFocus()
    }

    Item {
        id: keyHandler
        focus: true

        Keys.onPressed: event => {
            let key = event.key;
            if (event.modifiers & Qt.ControlModifier) {
                if (key === Qt.Key_H)
                    key = Qt.Key_Left;
                else if (key === Qt.Key_J)
                    key = Qt.Key_Down;
                else if (key === Qt.Key_K)
                    key = Qt.Key_Up;
                else if (key === Qt.Key_L)
                    key = Qt.Key_Right;
            }
            switch (key) {
            case Qt.Key_Escape:
                DynamicIsland.closeWallpaper();
                break;
            case Qt.Key_Left:
                WallpaperService.select(-1);
                break;
            case Qt.Key_Right:
                WallpaperService.select(1);
                break;
            case Qt.Key_Up:
                WallpaperService.select(-root.columns);
                break;
            case Qt.Key_Down:
                WallpaperService.select(root.columns);
                break;
            case Qt.Key_Tab:
                WallpaperService.cycleCategory(1);
                break;
            case Qt.Key_Backtab:
                WallpaperService.cycleCategory(-1);
                break;
            case Qt.Key_BracketLeft:
                WallpaperService.cycleScheme(-1);
                break;
            case Qt.Key_BracketRight:
                WallpaperService.cycleScheme(1);
                break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
                WallpaperService.applySelected();
                break;
            default:
                return;
            }
            event.accepted = true;
        }
    }

    component FilterChip: Rectangle {
        id: chip

        required property string label
        required property bool selected
        property real chipHeight: 32

        signal activated()

        readonly property color contentColor: selected ? Colors.on_secondary_container : Colors.on_surface_variant

        height: chipHeight
        width: chipRow.implicitWidth + 28
        radius: height / 2
        color: selected ? Colors.secondary_container : Colors.surface_container_high

        Behavior on color {
            ColorAnimation { duration: Motion.durationNormal }
        }

        Behavior on width {
            NumberAnimation {
                duration: Motion.durationShort4
                easing.type: Easing.Bezier
                easing.bezierCurve: Motion.emphasized
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: chip.contentColor
            opacity: chipTap.pressed ? 0.12 : (chipHover.hovered ? 0.08 : 0.0)

            Behavior on opacity {
                NumberAnimation { duration: Motion.durationShort2 }
            }
        }

        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: 6

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                visible: chip.selected
                text: "check"
                color: chip.contentColor
                font.pixelSize: 16
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.label
                color: chip.contentColor
                font.pixelSize: Typography.sizeBody
                font.weight: Typography.weightMedium
            }
        }

        TapHandler {
            id: chipTap
            onTapped: chip.activated()
        }

        HoverHandler {
            id: chipHover
            cursorShape: Qt.PointingHandCursor
        }
    }

    Rectangle {
        id: thumbMask
        width: grid.cellWidth - 10
        height: grid.cellHeight - 10
        radius: Metrics.radiusCard
        visible: false
        layer.enabled: true
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            spacing: 10

            Icon {
                text: "wallpaper"
                color: Colors.primary
                font.pixelSize: Typography.sizeIconLarge
                Layout.alignment: Qt.AlignVCenter
            }

            StyledText {
                text: "Wallpapers"
                font.pixelSize: Typography.sizeHeader + 2
                font.weight: Typography.weightBold
                Layout.alignment: Qt.AlignVCenter
            }

            StyledText {
                text: WallpaperService.hasPendingChange
                    ? "Previewing · Enter to apply"
                    : WallpaperService.filtered.length + (WallpaperService.filtered.length === 1 ? " image" : " images")
                color: WallpaperService.hasPendingChange ? Colors.primary : Colors.on_surface_variant
                font.pixelSize: Typography.sizeCaption
                Layout.alignment: Qt.AlignVCenter
            }

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                implicitWidth: 32
                implicitHeight: 20
                radius: height / 2
                color: Colors.surface_container_highest
                Layout.alignment: Qt.AlignVCenter

                StyledText {
                    anchors.centerIn: parent
                    text: "esc"
                    font.pixelSize: Typography.sizeSmall
                    font.weight: Typography.weightBold
                    color: Colors.on_surface_variant
                }

                TapHandler {
                    onTapped: DynamicIsland.closeWallpaper()
                }

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }

        ListView {
            id: categoryChips
            Layout.fillWidth: true
            implicitHeight: 32
            orientation: ListView.Horizontal
            spacing: 8
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: WallpaperService.categories

            delegate: FilterChip {
                required property string modelData
                label: modelData
                selected: WallpaperService.category === modelData
                onActivated: WallpaperService.category = modelData
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            EmptyState {
                anchors.centerIn: parent
                visible: WallpaperService.filtered.length === 0 && !WallpaperService.scanning
                icon: WallpaperService.directoryExists ? "image_not_supported" : "folder_off"
                text: WallpaperService.directoryExists ? "No images here yet" : "Create ~/Pictures/Wallpapers to get started"
            }

            GridView {
                id: grid
                anchors.fill: parent
                clip: true
                cellWidth: Math.floor(width / root.columns)
                cellHeight: Math.round(cellWidth * 0.66)
                model: WallpaperService.filtered
                currentIndex: WallpaperService.selectedIndex
                boundsBehavior: Flickable.StopAtBounds
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)

                delegate: Item {
                    id: cell

                    required property var modelData
                    required property int index
                    readonly property bool selected: index === WallpaperService.selectedIndex
                    readonly property bool isCurrent: modelData.path === WallpaperService.current

                    width: grid.cellWidth
                    height: grid.cellHeight

                    Item {
                        anchors.fill: parent
                        anchors.margins: 5
                        scale: cellHover.hovered ? 1.03 : 1.0

                        Behavior on scale {
                            NumberAnimation {
                                duration: Motion.durationShort4
                                easing.type: Easing.Bezier
                                easing.bezierCurve: Motion.emphasized
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: Metrics.radiusCard
                            color: Colors.surface_container_high
                        }

                        Image {
                            id: thumb
                            anchors.fill: parent
                            source: WallpaperService.fileUrl(cell.modelData.path)
                            sourceSize.width: 360
                            sourceSize.height: 240
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            visible: false
                        }

                        MultiEffect {
                            anchors.fill: parent
                            source: thumb
                            maskEnabled: true
                            maskSource: thumbMask
                            visible: thumb.status === Image.Ready
                        }

                        Icon {
                            anchors.centerIn: parent
                            text: "broken_image"
                            color: Colors.on_surface_variant
                            font.pixelSize: Typography.sizeIconLarge
                            visible: thumb.status === Image.Error
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -3
                            radius: Metrics.radiusCard + 3
                            color: "transparent"
                            border.width: 3
                            border.color: Colors.primary
                            opacity: cell.selected ? 1.0 : 0.0

                            Behavior on opacity {
                                NumberAnimation { duration: Motion.durationShort3 }
                            }
                        }

                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 8
                            width: 24
                            height: 24
                            radius: width / 2
                            color: Colors.primary
                            visible: cell.isCurrent

                            Icon {
                                anchors.centerIn: parent
                                text: "check"
                                color: Colors.on_primary
                                font.pixelSize: 16
                            }
                        }
                    }

                    HoverHandler {
                        id: cellHover
                        cursorShape: Qt.PointingHandCursor
                        onHoveredChanged: {
                            if (hovered)
                                WallpaperService.selectedIndex = cell.index;
                        }
                    }

                    TapHandler {
                        onTapped: WallpaperService.apply(cell.modelData.path)
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Icon {
                text: "palette"
                color: Colors.on_surface_variant
                font.pixelSize: Typography.sizeIconMedium
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 4
            }

            ListView {
                id: schemeChips
                Layout.fillWidth: true
                implicitHeight: 30
                orientation: ListView.Horizontal
                spacing: 6
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: WallpaperService.schemes
                currentIndex: Math.max(0, WallpaperService.schemes.findIndex(s => s.id === WallpaperService.scheme))
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                delegate: FilterChip {
                    required property var modelData
                    chipHeight: 30
                    label: modelData.label
                    selected: WallpaperService.scheme === modelData.id
                    onActivated: WallpaperService.scheme = modelData.id
                }
            }
        }
    }
}
