import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.theme
import qs.components

Item {
    id: root

    anchors.fill: parent
    anchors.margins: 14

    Connections {
        target: LauncherService
        function onSelectedIndexChanged() {
            if (appList.count > 0 && LauncherService.selectedIndex >= 0 && LauncherService.selectedIndex < appList.count) {
                appList.positionViewAtIndex(LauncherService.selectedIndex, ListView.Contain);
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            LauncherService.reset();
            focusTimer.restart();
        }
    }

    Timer {
        id: focusTimer
        interval: 30
        repeat: false
        onTriggered: {
            searchInput.forceActiveFocus();
            searchInput.selectAll();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // 1. Search Box
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 46
            radius: Metrics.radiusCard
            color: Colors.surface_container_high
            border.width: searchInput.activeFocus ? 1.5 : 1
            border.color: searchInput.activeFocus ? Colors.primary : Colors.outline_variant

            Behavior on border.color {
                ColorAnimation { duration: Motion.durationFast }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 10
                spacing: 10

                Icon {
                    text: "search"
                    color: searchInput.text.length > 0 ? Colors.primary : Colors.on_surface_variant
                    font.pixelSize: Typography.sizeIconMedium
                    Layout.alignment: Qt.AlignVCenter
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    TextInput {
                        id: searchInput
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.sizeBody
                        font.weight: Typography.weightMedium
                        color: Colors.on_surface
                        selectionColor: Colors.primary
                        selectedTextColor: Colors.on_primary
                        clip: true

                        text: LauncherService.query
                        onTextChanged: {
                            if (LauncherService.query !== text) {
                                LauncherService.query = text;
                            }
                        }

                        Keys.onPressed: event => {
                            if ((event.modifiers & Qt.ControlModifier) && (event.key === Qt.Key_J || event.key === Qt.Key_N)) {
                                event.accepted = true;
                                LauncherService.selectNext();
                            } else if ((event.modifiers & Qt.ControlModifier) && (event.key === Qt.Key_K || event.key === Qt.Key_P)) {
                                event.accepted = true;
                                LauncherService.selectPrevious();
                            }
                        }

                        Keys.onDownPressed: event => {
                            event.accepted = true;
                            LauncherService.selectNext();
                        }
                        Keys.onUpPressed: event => {
                            event.accepted = true;
                            LauncherService.selectPrevious();
                        }
                        Keys.onReturnPressed: event => {
                            event.accepted = true;
                            LauncherService.launchSelected();
                        }
                        Keys.onEnterPressed: event => {
                            event.accepted = true;
                            LauncherService.launchSelected();
                        }
                        Keys.onEscapePressed: event => {
                            event.accepted = true;
                            DynamicIsland.closeLauncher();
                        }

                        StyledText {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Search apps..."
                            font.pixelSize: Typography.sizeBody
                            color: Colors.outline
                            visible: searchInput.text.length === 0
                        }
                    }
                }

                // Clear button
                IconButton {
                    visible: searchInput.text.length > 0
                    icon: "close"
                    pixelSize: 18
                    touchTarget: 28
                    Layout.alignment: Qt.AlignVCenter
                    onClicked: {
                        searchInput.text = "";
                        searchInput.forceActiveFocus();
                    }
                }

                // Esc badge
                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 20
                    radius: 5
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
                        onTapped: DynamicIsland.closeLauncher()
                    }
                }
            }
        }

        // 2. Apps List View
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Animated Empty State Micro-interaction
            ColumnLayout {
                id: emptyStateBox
                anchors.centerIn: parent
                spacing: 12
                visible: opacity > 0
                opacity: LauncherService.results.length === 0 ? 1.0 : 0.0
                scale: LauncherService.results.length === 0 ? 1.0 : 0.85

                Behavior on opacity {
                    NumberAnimation { duration: 180; easing.type: Motion.easingStandard }
                }
                Behavior on scale {
                    SpringAnimation { spring: 3.5; damping: 0.55; epsilon: 0.01 }
                }

                // Animated Badge with subtle float
                Rectangle {
                    width: 56
                    height: 56
                    radius: 16
                    color: Colors.surface_container_high
                    border.width: 1
                    border.color: Colors.outline_variant
                    Layout.alignment: Qt.AlignHCenter

                    Icon {
                        id: emptyIcon
                        anchors.centerIn: parent
                        text: "search_off"
                        font.pixelSize: 28
                        color: Colors.primary

                        SequentialAnimation on y {
                            running: LauncherService.results.length === 0
                            loops: Animation.Infinite
                            NumberAnimation { to: (parent.height - height) / 2 - 3; duration: 1200; easing.type: Easing.InOutSine }
                            NumberAnimation { to: (parent.height - height) / 2 + 3; duration: 1200; easing.type: Easing.InOutSine }
                        }
                    }
                }

                ColumnLayout {
                    spacing: 3
                    Layout.alignment: Qt.AlignHCenter

                    StyledText {
                        text: "No matches found"
                        font.pixelSize: Typography.sizeBody
                        font.weight: Typography.weightBold
                        color: Colors.on_surface
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledText {
                        text: searchInput.text.length > 0 ? ("Nothing matches \"" + searchInput.text + "\"") : "No applications available"
                        font.pixelSize: Typography.sizeCaption
                        color: Colors.on_surface_variant
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                // Suggestion chip
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 4
                    implicitWidth: tipText.implicitWidth + 20
                    implicitHeight: 24
                    radius: 12
                    color: Colors.surface_container

                    StyledText {
                        id: tipText
                        anchors.centerIn: parent
                        text: "Check spelling or try generic terms"
                        font.pixelSize: Typography.sizeSmall
                        color: Colors.outline
                    }
                }
            }

            ListView {
                id: appList
                anchors.fill: parent
                clip: true
                spacing: 4
                model: LauncherService.results
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: LauncherService.selectedIndex

                highlightFollowsCurrentItem: true
                highlightMoveDuration: 0

                highlight: Rectangle {
                    width: appList.width
                    height: 50
                    radius: 10
                    color: Colors.surface_container_highest
                    visible: appList.count > 0
                    z: 0

                    Behavior on y {
                        SpringAnimation {
                            spring: 5.0
                            damping: 0.55
                            epsilon: 0.25
                        }
                    }
                }

                delegate: Rectangle {
                    id: delegateRoot
                    required property var modelData
                    required property int index

                    readonly property bool isSelected: index === LauncherService.selectedIndex

                    width: appList.width
                    height: 50
                    radius: 10
                    color: (itemHover.hovered && !isSelected) 
                        ? Qt.rgba(Colors.surface_container_high.r, Colors.surface_container_high.g, Colors.surface_container_high.b, 0.4) 
                        : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: Motion.durationFast }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 12
                        spacing: 12
                        z: 1

                        // App Icon
                        Item {
                            width: 32
                            height: 32
                            Layout.alignment: Qt.AlignVCenter

                            Image {
                                id: appIconImg
                                anchors.fill: parent
                                source: Quickshell.iconPath(modelData.icon)
                                sourceSize: Qt.size(32, 32)
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                visible: status === Image.Ready
                            }

                            Icon {
                                anchors.centerIn: parent
                                text: "apps"
                                font.pixelSize: 24
                                color: delegateRoot.isSelected ? Colors.primary : Colors.on_surface_variant
                                visible: appIconImg.status !== Image.Ready
                            }
                        }

                        // App Titles
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 1

                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.name
                                font.pixelSize: Typography.sizeBody
                                font.weight: delegateRoot.isSelected ? Typography.weightBold : Typography.weightMedium
                                color: delegateRoot.isSelected ? Colors.primary : Colors.on_surface
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.genericName || modelData.comment || ""
                                font.pixelSize: Typography.sizeCaption
                                color: Colors.on_surface_variant
                                elide: Text.ElideRight
                                visible: text.length > 0
                            }
                        }

                        // Selected action indicator
                        Icon {
                            visible: delegateRoot.isSelected
                            text: "keyboard_return"
                            font.pixelSize: 18
                            color: Colors.primary
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    HoverHandler {
                        id: itemHover
                        cursorShape: Qt.PointingHandCursor
                        onHoveredChanged: {
                            if (hovered) {
                                LauncherService.selectedIndex = index;
                            }
                        }
                    }

                    TapHandler {
                        onTapped: {
                            LauncherService.launch(modelData);
                        }
                    }
                }
            }
        }
    }
}
