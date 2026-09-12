import QtQuick
import QtQuick.Layouts
import qs.services
import qs.theme
import qs.components

Item {
    id: root

    anchors.fill: parent

    property string passwordPromptSsid: ""
    property bool showPassword: false

    onPasswordPromptSsidChanged: {
        if (passwordPromptSsid !== "") {
            showPassword = false;
            focusTimer.restart();
        }
    }

    Timer {
        id: focusTimer
        interval: 50
        onTriggered: pwdInput.forceActiveFocus()
    }

    Connections {
        target: Network
        function onConnectedChanged() {
            if (Network.connected && Network.ssid === root.passwordPromptSsid) {
                root.passwordPromptSsid = "";
            }
        }
    }

    // 1. Network List View
    Item {
        id: listViewContainer
        anchors.fill: parent
        opacity: root.passwordPromptSsid === "" ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: Motion.durationNormal }
        }

        EmptyState {
            anchors.centerIn: parent
            opacity: wifiList.count === 0 ? 1.0 : 0.0
            visible: opacity > 0
            icon: Network.scanning ? "sync" : "wifi_off"
            rotating: Network.scanning
            text: Network.scanning ? "Searching networks..." : "No networks found"

            Behavior on opacity {
                FadeAnimation {
                    entering: wifiList.count === 0
                    stagger: Motion.contentStagger
                }
            }
        }

        ListView {
            id: wifiList
            anchors.fill: parent
            clip: true
            spacing: Metrics.layoutSpacing
            model: Network.networkModel
            boundsBehavior: Flickable.StopAtBounds

            add: Transition {
                NumberAnimation {
                    properties: "opacity"
                    from: 0.0
                    to: 1.0
                    duration: Motion.contentEnter
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.emphasizedDecelerate
                }
                NumberAnimation {
                    properties: "scale"
                    from: 0.92
                    to: 1.0
                    duration: Motion.contentEnter
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.emphasizedDecelerate
                }
            }

            remove: Transition {
                NumberAnimation {
                    properties: "opacity"
                    to: 0.0
                    duration: Motion.contentExit
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.emphasizedAccelerate
                }
                NumberAnimation {
                    properties: "scale"
                    to: 0.92
                    duration: Motion.contentExit
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.emphasizedAccelerate
                }
            }

            displaced: Transition {
                NumberAnimation {
                    properties: "x,y"
                    duration: Motion.durationMedium2
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.emphasized
                }
            }

            delegate: DeviceListItem {
                required property string ssid
                required property int strength
                required property bool inUse
                required property bool locked

                readonly property bool isConnecting: Network.connectingTo === ssid
                readonly property bool hasFailed: Network.failedSsid === ssid

                width: wifiList.width
                active: inUse
                loading: isConnecting
                icon: {
                    if (strength >= 67) return "wifi";
                    if (strength >= 34) return "wifi_2_bar";
                    return "wifi_1_bar";
                }
                title: ssid
                subtitle: {
                    if (isConnecting) return "Connecting...";
                    if (hasFailed) return "Failed • Click to retry password";
                    return inUse ? "Connected" : (locked ? (Network.isSaved(ssid) ? "Saved" : "Secured") : "Open");
                }
                subtitleColor: hasFailed ? Colors.error : (isConnecting ? Colors.tertiary : (inUse ? Colors.primary : Colors.on_surface_variant))
                trailingIcon: locked ? "lock" : ""

                onClicked: {
                    if (inUse || isConnecting)
                        return;

                    // If locked and not already saved, or if previous connection failed: ask for password!
                    if (locked && (!Network.isSaved(ssid) || hasFailed)) {
                        pwdInput.text = "";
                        root.passwordPromptSsid = ssid;
                    } else {
                        Network.connect(ssid);
                    }
                }
            }
        }
    }

    // 2. Password Entry View
    Item {
        id: passwordViewContainer
        anchors.fill: parent
        opacity: root.passwordPromptSsid !== "" ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: Motion.durationNormal }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 12

            // Top Header: Back button & Network Title
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                IconButton {
                    icon: "arrow_back"
                    pixelSize: 18
                    touchTarget: 32
                    Layout.alignment: Qt.AlignVCenter
                    onClicked: root.passwordPromptSsid = ""
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    StyledText {
                        text: root.passwordPromptSsid
                        font.pixelSize: Typography.sizeTitle
                        font.weight: Typography.weightBold
                        color: Colors.on_surface
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    StyledText {
                        text: "Enter Wi-Fi password"
                        font.pixelSize: Typography.sizeCaption
                        color: Colors.on_surface_variant
                    }
                }

                Icon {
                    text: "lock"
                    color: Colors.primary
                    font.pixelSize: 18
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // Password Input Box
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 46
                radius: Metrics.radiusCard
                color: Colors.surface_container_high
                border.width: pwdInput.activeFocus ? 2 : 1
                border.color: pwdInput.activeFocus ? Colors.primary : Colors.outline_variant

                Behavior on border.color {
                    ColorAnimation { duration: Motion.durationFast }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 6
                    spacing: 8

                    Icon {
                        text: "key"
                        font.pixelSize: 18
                        color: pwdInput.activeFocus ? Colors.primary : Colors.on_surface_variant
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color {
                            ColorAnimation { duration: Motion.durationFast }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        TextInput {
                            id: pwdInput
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            color: Colors.on_surface
                            font.family: Typography.family
                            font.pixelSize: Typography.sizeBody
                            font.letterSpacing: root.showPassword ? 0 : 3
                            echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                            passwordCharacter: "✦"
                            passwordMaskDelay: 800
                            clip: true
                            focus: true
                            activeFocusOnTab: true
                            selectByMouse: true
                            onAccepted: {
                                if (pwdInput.text.length > 0 && !Network.connectingTo) {
                                    Network.connect(root.passwordPromptSsid, pwdInput.text);
                                }
                            }

                            Keys.onEscapePressed: {
                                root.passwordPromptSsid = "";
                            }
                        }

                        StyledText {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Password"
                            font.pixelSize: Typography.sizeBody
                            color: Colors.outline
                            visible: pwdInput.text.length === 0 && !pwdInput.activeFocus
                            enabled: false
                        }
                    }

                    IconButton {
                        icon: root.showPassword ? "visibility_off" : "visibility"
                        pixelSize: 18
                        touchTarget: 32
                        Layout.alignment: Qt.AlignVCenter
                        onClicked: root.showPassword = !root.showPassword
                    }
                }
            }

            // Error Message (if connection failed)
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: Network.failedSsid === root.passwordPromptSsid

                Icon {
                    text: "error"
                    font.pixelSize: 14
                    color: Colors.error
                }

                StyledText {
                    text: "Connection failed. Please check the password."
                    font.pixelSize: Typography.sizeCaption
                    color: Colors.error
                    Layout.fillWidth: true
                }
            }

            Item {
                Layout.fillHeight: true
            }

            // Action Buttons (Cancel / Connect)
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Cancel Button
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: Metrics.radiusPill
                    color: cancelMouse.containsMouse ? Colors.surface_container_highest : Colors.surface_container

                    Behavior on color {
                        ColorAnimation { duration: Motion.durationFast }
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.pixelSize: Typography.sizeBody
                        font.weight: Typography.weightMedium
                        color: Colors.on_surface
                    }

                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.passwordPromptSsid = ""
                    }
                }

                // Connect Button
                Rectangle {
                    id: connectButton
                    readonly property bool canConnect: pwdInput.text.length > 0 && Network.connectingTo !== root.passwordPromptSsid
                    readonly property bool isConnecting: Network.connectingTo === root.passwordPromptSsid

                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: Metrics.radiusPill
                    color: canConnect 
                        ? (connectMouse.containsMouse ? Qt.lighter(Colors.primary, 1.15) : Colors.primary)
                        : Colors.surface_container_highest
                    opacity: canConnect || isConnecting ? 1.0 : 0.6

                    Behavior on color {
                        ColorAnimation { duration: Motion.durationFast }
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Icon {
                            visible: connectButton.isConnecting
                            text: "progress_activity"
                            font.pixelSize: 16
                            color: Colors.on_primary

                            RotationAnimator on rotation {
                                running: connectButton.isConnecting
                                from: 0
                                to: 360
                                loops: Animation.Infinite
                                duration: Motion.durationSpin
                            }
                        }

                        StyledText {
                            text: connectButton.isConnecting ? "Connecting..." : "Connect"
                            font.pixelSize: Typography.sizeBody
                            font.weight: Typography.weightBold
                            color: connectButton.canConnect ? Colors.on_primary : Colors.on_surface_variant
                        }
                    }

                    MouseArea {
                        id: connectMouse
                        anchors.fill: parent
                        hoverEnabled: connectButton.canConnect
                        cursorShape: connectButton.canConnect ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (connectButton.canConnect) {
                                Network.connect(root.passwordPromptSsid, pwdInput.text);
                            }
                        }
                    }
                }
            }
        }
    }
}
