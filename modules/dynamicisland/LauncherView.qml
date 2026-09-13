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

    NumberAnimation {
        id: scrollAnim
        target: appList
        property: "contentY"
        duration: 180
        easing.type: Easing.OutCubic
    }

    function ensureVisible(index, immediate) {
        if (appList.count === 0 || index < 0 || index >= appList.count) return;

        let itemHeight = 48;
        let spacing = appList.spacing;
        let itemStride = itemHeight + spacing;
        let itemTop = index * itemStride;
        let itemBottom = itemTop + itemHeight;

        let viewHeight = appList.height;
        let currentY = appList.contentY;
        let maxY = Math.max(0, (appList.contentHeight || 0) - viewHeight);

        let targetY = currentY;

        if (index === 0) {
            targetY = 0;
        } else if (index === appList.count - 1 && currentY > itemTop - viewHeight) {
            targetY = maxY;
        } else if (itemTop < currentY) {
            targetY = Math.max(0, itemTop - spacing);
        } else if (itemBottom > currentY + viewHeight) {
            targetY = Math.min(maxY, itemBottom - viewHeight + spacing);
        }

        if (immediate) {
            scrollAnim.stop();
            appList.contentY = targetY;
        } else if (Math.abs(targetY - currentY) > 1) {
            scrollAnim.stop();
            scrollAnim.from = currentY;
            scrollAnim.to = targetY;
            scrollAnim.start();
        }
    }

    Connections {
        target: LauncherService
        function onSelectedIndexChanged() {
            ensureVisible(LauncherService.selectedIndex, false);
        }
    }

    onVisibleChanged: {
        if (visible) {
            activeIndicator.animateMotion = false;
            scrollAnim.stop();
            appList.contentY = 0;
            LauncherService.reset();
            focusTimer.restart();
            reEnableTimer.restart();
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

    Timer {
        id: reEnableTimer
        interval: 40
        repeat: false
        onTriggered: activeIndicator.animateMotion = true
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // Search box
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 46
            radius: height / 2
            color: Colors.surface_container_high

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
                        font.family: Typography.family
                        font.pixelSize: Typography.sizeBody
                        font.weight: Typography.weightMedium
                        color: Colors.on_surface
                        selectionColor: Colors.primary
                        selectedTextColor: Colors.on_primary
                        clip: true

                        text: LauncherService.query
                        onTextChanged: {
                            activeIndicator.animateMotion = false;
                            scrollAnim.stop();
                            appList.contentY = 0;
                            if (LauncherService.query !== text) {
                                LauncherService.query = text;
                            }
                            reEnableTimer.restart();
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
                    radius: 10
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

        // Apps list
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Empty state
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
                onMovementStarted: scrollAnim.stop()

                Rectangle {
                    id: activeIndicator
                    parent: appList.contentItem
                    x: 0
                    width: appList.width
                    height: 48
                    radius: 16
                    color: Colors.secondary_container
                    visible: appList.count > 0 && LauncherService.results.length > 0
                    z: 0

                    property bool animateMotion: true

                    y: LauncherService.selectedIndex >= 0 ? (LauncherService.selectedIndex * (48 + appList.spacing)) : 0

                    Behavior on y {
                        enabled: activeIndicator.animateMotion && root.visible
                        SpringAnimation {
                            spring: 4.8
                            damping: 0.44
                            epsilon: 0.1
                        }
                    }

                    // Action key badge
                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 24
                        radius: 10
                        color: Qt.rgba(Colors.on_secondary_container.r, Colors.on_secondary_container.g, Colors.on_secondary_container.b, 0.12)

                        Icon {
                            anchors.centerIn: parent
                            text: "keyboard_return"
                            font.pixelSize: 15
                            color: Colors.on_secondary_container
                        }
                    }
                }

                delegate: Item {
                    id: delegateRoot
                    required property var modelData
                    required property int index

                    readonly property bool isSelected: index === LauncherService.selectedIndex

                    width: appList.width
                    height: 48
                    z: 1

                    Rectangle {
                        anchors.fill: parent
                        radius: 16
                        color: (itemHover.hovered && !delegateRoot.isSelected) 
                            ? Qt.rgba(Colors.surface_container_high.r, Colors.surface_container_high.g, Colors.surface_container_high.b, 0.4) 
                            : "transparent"
                        z: 0

                        Behavior on color {
                            ColorAnimation { duration: Motion.durationFast }
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12
                        z: 1

                        // App icon
                        Item {
                            width: 32
                            height: 32
                            Layout.alignment: Qt.AlignVCenter
                            scale: delegateRoot.isSelected ? 1.10 : 1.0

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 180
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.4
                                }
                            }

                            Image {
                                id: appIconImg
                                anchors.fill: parent
                                source: {
                                    let icon = modelData.icon || "";
                                    if (icon === "") return "";
                                    if (icon.startsWith("/") || icon.startsWith("file://")) {
                                        return icon.startsWith("file://") ? icon : ("file://" + icon);
                                    }
                                    return Quickshell.iconPath(icon, true);
                                }
                                sourceSize: Qt.size(32, 32)
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                visible: source != "" && status === Image.Ready
                            }

                            Icon {
                                anchors.centerIn: parent
                                text: "apps"
                                font.pixelSize: 24
                                color: delegateRoot.isSelected ? Colors.primary : Colors.on_surface_variant
                                visible: !appIconImg.visible
                            }
                        }

                        // App titles
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

                        // Spacer for action key badge
                        Item {
                            implicitWidth: 18
                            implicitHeight: 18
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
