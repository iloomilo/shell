import QtQuick
import qs.theme

Item {
    id: root

    property alias text: hiddenInput.text
    property string placeholderText: "Password"
    property bool showPassword: false
    readonly property bool hasFocus: hiddenInput.activeFocus

    property int activeUnmaskedIndex: -1

    signal accepted()
    signal escapePressed()

    function forceActiveFocus() {
        hiddenInput.forceActiveFocus();
    }

    implicitHeight: 32
    implicitWidth: 200

    onTextChanged: {
        if (!root.showPassword && hiddenInput.text.length > 0) {
            root.activeUnmaskedIndex = hiddenInput.text.length - 1;
            maskTimer.restart();
        } else {
            root.activeUnmaskedIndex = -1;
        }
    }

    Timer {
        id: maskTimer
        interval: 400
        repeat: false
        onTriggered: root.activeUnmaskedIndex = -1
    }

    TextInput {
        id: hiddenInput
        anchors.fill: parent
        color: "transparent"
        selectionColor: "transparent"
        selectedTextColor: "transparent"
        cursorVisible: false
        clip: true
        focus: true
        activeFocusOnTab: true
        selectByMouse: true

        onAccepted: root.accepted()
        Keys.onEscapePressed: root.escapePressed()
    }

    StyledText {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.placeholderText
        font.pixelSize: Typography.sizeBody
        color: Colors.outline
        visible: hiddenInput.text.length === 0 && !hiddenInput.activeFocus
        enabled: false
    }

    ListView {
        id: charList
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 24
        orientation: ListView.Horizontal
        spacing: 3
        interactive: false
        clip: true
        model: hiddenInput.text.length

        onCountChanged: {
            charList.positionViewAtEnd();
        }

        add: Transition {
            NumberAnimation {
                properties: "scale,opacity"
                from: 0.0
                to: 1.0
                duration: Motion.durationShort3
                easing.type: Easing.OutBack
            }
        }

        remove: Transition {
            NumberAnimation {
                properties: "scale,opacity"
                to: 0.0
                duration: Motion.durationShort2
            }
        }

        displaced: Transition {
            NumberAnimation {
                properties: "x"
                duration: Motion.durationShort3
                easing.type: Easing.Bezier
                easing.bezierCurve: Motion.standard
            }
        }

        delegate: Item {
            id: charDelegate
            required property int index

            readonly property string charVal: index < hiddenInput.text.length ? hiddenInput.text.charAt(index) : ""
            readonly property bool isRevealed: root.showPassword || (index === root.activeUnmaskedIndex)

            width: Math.max(12, charText.implicitWidth + 2)
            height: 24

            // The typed character (visible only if revealed, then morphs into dot)
            Text {
                id: charText
                anchors.centerIn: parent
                text: charDelegate.charVal
                font.family: Typography.family
                font.pixelSize: Typography.sizeBody
                font.weight: Typography.weightBold
                color: Colors.on_surface
                opacity: charDelegate.isRevealed ? 1.0 : 0.0
                scale: charDelegate.isRevealed ? 1.0 : 0.2

                Behavior on opacity {
                    NumberAnimation {
                        duration: Motion.durationNormal
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Motion.standard
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: Motion.durationNormal
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Motion.emphasized
                    }
                }
            }

            // The Material Dot (visible for all masked characters)
            Rectangle {
                id: dot
                anchors.centerIn: parent
                width: 8
                height: 8
                radius: 4
                color: Colors.primary
                opacity: !charDelegate.isRevealed ? 1.0 : 0.0
                scale: !charDelegate.isRevealed ? 1.0 : 0.2

                Behavior on opacity {
                    NumberAnimation {
                        duration: Motion.durationNormal
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Motion.standard
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: Motion.durationNormal
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Motion.emphasized
                    }
                }
            }
        }

        // Animated cursor as footer
        footer: Item {
            width: 4
            height: 24
            visible: hiddenInput.activeFocus

            Rectangle {
                anchors.centerIn: parent
                width: 2
                height: 16
                radius: 1
                color: Colors.primary

                SequentialAnimation on opacity {
                    running: hiddenInput.activeFocus
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.0; duration: 450 }
                    NumberAnimation { to: 0.0; duration: 450 }
                }
            }
        }
    }

    TapHandler {
        onTapped: hiddenInput.forceActiveFocus()
    }
}
