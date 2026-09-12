import QtQuick
import qs.services
import qs.theme
import qs.components

Item {
    id: root

    anchors.fill: parent

    signal actionTriggered()

    ListView {
        id: powerList
        anchors.fill: parent
        clip: true
        spacing: Metrics.layoutSpacing
        model: Power.actions
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        delegate: DeviceListItem {
            required property var modelData

            readonly property bool isDanger: modelData.label === "Shut down"

            width: powerList.width
            icon: modelData.icon
            title: modelData.label
            danger: isDanger

            onClicked: {
                root.actionTriggered();
                Power.run(modelData.command);
            }
        }
    }
}
