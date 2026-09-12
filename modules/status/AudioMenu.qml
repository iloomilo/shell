import QtQuick
import QtQuick.Layouts
import qs.services
import qs.theme
import qs.components

Item {
    id: root

    anchors.fill: parent

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // Volume Control Card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 84
            radius: Metrics.radiusCard
            color: Colors.surface_container

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                anchors.topMargin: 12
                anchors.bottomMargin: 12
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        text: "Volume"
                        font.pixelSize: Typography.sizeBody
                        font.weight: Typography.weightMedium
                        color: Colors.on_surface
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        text: AudioService.muted ? "Muted" : (Math.round(AudioService.volume * 100) + "%")
                        font.pixelSize: Typography.sizeCaption
                        font.weight: Typography.weightBold
                        color: AudioService.muted ? Colors.error : Colors.primary
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    IconButton {
                        icon: AudioService.iconName
                        pixelSize: 18
                        touchTarget: 32
                        Layout.alignment: Qt.AlignVCenter
                        onClicked: AudioService.toggleMute()
                    }

                    Slider {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        value: AudioService.volume
                        activeColor: AudioService.muted ? Colors.error : Colors.primary
                        thumbColor: AudioService.muted ? Colors.error : Colors.primary
                        onMoved: val => AudioService.setVolume(val, true)
                    }
                }
            }
        }

        // Output Devices Header
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 2
            Layout.leftMargin: 2
            Layout.rightMargin: 2

            StyledText {
                text: "OUTPUT DEVICES"
                font.pixelSize: Typography.sizeSmall
                font.weight: Typography.weightBold
                color: Colors.on_surface_variant
                Layout.fillWidth: true
            }

            StyledText {
                text: AudioService.sinks.length + (AudioService.sinks.length === 1 ? " device" : " devices")
                font.pixelSize: Typography.sizeSmall
                color: Colors.outline
            }
        }

        // Sink Switcher List
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            EmptyState {
                anchors.centerIn: parent
                visible: AudioService.sinks.length === 0
                icon: "volume_off"
                text: "No output devices found"
            }

            ListView {
                id: sinkList
                anchors.fill: parent
                clip: true
                spacing: Metrics.layoutSpacing
                model: AudioService.sinks
                boundsBehavior: Flickable.StopAtBounds

                delegate: DeviceListItem {
                    required property var modelData

                    readonly property bool isDefault: AudioService.sink && modelData ? (AudioService.sink.id === modelData.id) : false

                    width: sinkList.width
                    active: isDefault
                    icon: AudioService.sinkIcon(modelData)
                    title: AudioService.cleanSinkName(modelData)
                    subtitle: isDefault ? "Active output" : "Ready"
                    showCheckmark: isDefault

                    onClicked: AudioService.setDefaultSink(modelData.id)
                }
            }
        }
    }
}
