import QtQuick
import QtQuick.Effects
import Quickshell
import qs.theme
import qs.components
import qs.services as Services

Item {
    id: root

    property bool animateIn: true
    property real reveal: animateIn ? 0 : 1
    property bool exiting: false
    property bool started: false
    property real exit: 0
    readonly property bool ready: wallpaper.source == "" || wallpaper.status === Image.Ready || wallpaper.status === Image.Error
    readonly property bool success: Services.Lock.unlocking

    signal exitFinished()

    function maybeStart() {
        if (!animateIn || started || !ready)
            return;
        started = true;
        startFrames.running = true;
    }

    function playExit() {
        if (exiting)
            return;
        exiting = true;
        exitAnim.start();
    }

    onReadyChanged: maybeStart()

    Component.onCompleted: {
        if (!animateIn)
            return;
        startGuard.start();
        maybeStart();
    }

    FrameAnimation {
        id: startFrames
        property int count: 0
        running: false
        onTriggered: {
            if (++count < 4)
                return;
            running = false;
            revealAnim.start();
        }
    }

    Timer {
        id: startGuard
        interval: 400
        onTriggered: {
            if (root.started)
                return;
            root.started = true;
            startFrames.running = true;
        }
    }

    NumberAnimation {
        id: revealAnim
        target: root
        property: "reveal"
        from: 0
        to: 1
        duration: Motion.durationLong2
        easing.type: Easing.Bezier
        easing.bezierCurve: Motion.emphasizedDecelerate
    }

    NumberAnimation {
        id: exitAnim
        target: root
        property: "exit"
        from: 0
        to: 1
        duration: 750
        easing.type: Easing.Bezier
        easing.bezierCurve: Motion.emphasized
        onFinished: root.exitFinished()
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Item {
        id: holeMask
        anchors.fill: parent
        visible: false
        layer.enabled: true

        Rectangle {
            readonly property real maxRadius: Math.hypot(root.width, root.height) + 80
            readonly property real r: Math.pow(root.exit, 1.8) * maxRadius
            x: clockWidget.x + clockWidget.clockCenter.x - r
            y: clockWidget.y + clockWidget.clockCenter.y - r
            width: r * 2
            height: r * 2
            radius: r
            color: "white"
        }
    }

    Item {
        id: content
        anchors.fill: parent
        layer.enabled: root.exiting || !root.animateIn
        layer.effect: MultiEffect {
            maskEnabled: true
            maskInverted: true
            maskSource: holeMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 0.05
        }

        Rectangle {
            anchors.fill: parent
            color: Colors.surface_container_lowest
        }

        Item {
            anchors.fill: parent
            visible: wallpaper.status === Image.Ready
            scale: 1.0 + 0.06 * (1 - root.reveal) + 0.1 * root.exit

            Image {
                id: wallpaper
                width: Math.ceil(root.width * 1.2 / 4)
                height: Math.ceil(root.height * 1.2 / 4)
                sourceSize.width: width
                sourceSize.height: height
                source: Services.Lock.wallpaper.length > 0 ? "file://" + Services.Lock.wallpaper : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                visible: false
            }

            MultiEffect {
                x: -root.width * 0.1
                y: -root.height * 0.1
                width: wallpaper.width
                height: wallpaper.height
                source: wallpaper
                autoPaddingEnabled: false
                blurEnabled: true
                blurMax: 20
                blur: 1.0
                saturation: -0.1
                layer.enabled: true
                layer.smooth: true
                transform: Scale {
                    xScale: root.width * 1.2 / wallpaper.width
                    yScale: root.height * 1.2 / wallpaper.height
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Colors.scrim
            opacity: 0.45
        }

        ClockWidget {
            id: clockWidget
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 6 + 40 * (1 - root.reveal)
            clockSize: Math.min(root.height * 0.2, 190)

            readonly property real stackGap: clockSize * 0.24
            date: clock.date
            exit: root.exit
        }

        Item {
            id: lowerGroup
            anchors.fill: parent
            opacity: Math.max(0, 1 - root.exit * 2.5)
            transform: Translate { y: root.exit * 60 }

            Row {
                id: userBlock
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: clockWidget.y - height - clockWidget.stackGap + 30 * (1 - root.reveal)
                spacing: 14

                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44
                    height: 44

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Colors.primary_container
                        visible: avatarImage.status !== Image.Ready

                        StyledText {
                            anchors.centerIn: parent
                            text: Services.Lock.displayName.charAt(0).toUpperCase()
                            color: Colors.on_primary_container
                            font.pixelSize: 20
                            font.weight: Font.Bold
                        }
                    }

                    Image {
                        id: avatarImage
                        anchors.fill: parent
                        source: Services.Lock.avatar
                        sourceSize.width: 96
                        sourceSize.height: 96
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: false
                    }

                    Rectangle {
                        id: avatarMask
                        anchors.fill: parent
                        radius: width / 2
                        visible: false
                        layer.enabled: true
                    }

                    MultiEffect {
                        anchors.fill: parent
                        source: avatarImage
                        maskEnabled: true
                        maskSource: avatarMask
                        visible: avatarImage.status === Image.Ready
                    }
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Services.Lock.greeting + ", " + Services.Lock.displayName
                    color: Colors.on_surface
                    font.pixelSize: Typography.sizeHeader + 6
                    font.weight: Typography.weightBold
                }
            }

            Item {
                id: inputArea
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: clockWidget.y + clockWidget.height + clockWidget.stackGap + 30 * (1 - root.reveal)
                width: Math.max(280, clockWidget.width)
                height: 56 + 28

                Rectangle {
                    id: field
                    x: shake.offset
                    width: parent.width
                    height: 56
                    radius: height / 2
                    color: Colors.surface_container_high
                    border.width: Services.Lock.failed || root.success || input.activeFocus ? 2 : 0
                    border.color: Services.Lock.failed ? Colors.error : Colors.primary

                    Behavior on border.color {
                        ColorAnimation { duration: Motion.durationNormal }
                    }

                    QtObject {
                        id: shake
                        property real offset: 0
                    }

                    SequentialAnimation {
                        id: shakeAnim
                        NumberAnimation { target: shake; property: "offset"; to: -12; duration: 50; easing.type: Easing.OutQuad }
                        NumberAnimation { target: shake; property: "offset"; to: 10; duration: 70; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: shake; property: "offset"; to: -6; duration: 70; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: shake; property: "offset"; to: 3; duration: 60; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: shake; property: "offset"; to: 0; duration: 60; easing.type: Easing.OutQuad }
                    }

                    Connections {
                        target: Services.Lock
                        function onAuthFailed() {
                            shakeAnim.restart();
                        }
                    }

                    Icon {
                        id: lockIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        text: Services.Lock.failed || root.success ? "lock_open_right" : "lock"
                        color: Services.Lock.failed ? Colors.error : (root.success ? Colors.primary : Colors.on_surface_variant)
                        font.pixelSize: Typography.sizeIconLarge
                    }

                    StyledText {
                        anchors.left: lockIcon.right
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Password"
                        color: Colors.on_surface_variant
                        font.pixelSize: Typography.sizeHeader
                        visible: input.text.length === 0 && !Services.Lock.authenticating && !root.success
                    }

                    TextInput {
                        id: input
                        anchors.left: lockIcon.right
                        anchors.leftMargin: 14
                        anchors.right: submit.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        focus: root.animateIn
                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        color: Colors.on_surface
                        selectionColor: Colors.primary_container
                        font.family: Typography.family
                        font.pixelSize: Typography.sizeHeader + 2
                        font.letterSpacing: 2
                        clip: true
                        cursorVisible: activeFocus && !root.success
                        enabled: !Services.Lock.authenticating && !root.success
                        text: Services.Lock.password
                        onTextEdited: {
                            Services.Lock.password = text;
                            Services.Lock.failed = false;
                        }
                        onAccepted: Services.Lock.tryUnlock()

                        Component.onCompleted: if (root.animateIn) forceActiveFocus()
                    }

                    Rectangle {
                        id: submit
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 40
                        height: 40
                        radius: Services.Lock.authenticating ? 12 : width / 2
                        color: input.text.length > 0 || Services.Lock.authenticating || root.success ? Colors.primary : Colors.surface_container_highest

                        Behavior on color {
                            ColorAnimation { duration: Motion.durationNormal }
                        }

                        Behavior on radius {
                            NumberAnimation { duration: Motion.durationMedium1; easing.type: Easing.Bezier; easing.bezierCurve: Motion.emphasized }
                        }

                        RotationAnimator on rotation {
                            running: Services.Lock.authenticating
                            from: 0
                            to: 360
                            loops: Animation.Infinite
                            duration: Motion.durationSpin
                            onRunningChanged: if (!running) submit.rotation = 0
                        }

                        Icon {
                            anchors.centerIn: parent
                            text: Services.Lock.authenticating ? "" : (root.success ? "check" : "arrow_forward")
                            color: input.text.length > 0 || root.success ? Colors.on_primary : Colors.on_surface_variant
                            font.pixelSize: Typography.sizeIconMedium + 2
                        }

                        TapHandler {
                            onTapped: Services.Lock.tryUnlock()
                        }

                        HoverHandler {
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    text: Services.Lock.message
                    color: Colors.error
                    font.pixelSize: Typography.sizeBody
                    opacity: Services.Lock.failed ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: Motion.durationNormal }
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 1 - root.reveal
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            enabled: !root.exiting
            onClicked: input.forceActiveFocus()
        }
    }
}
