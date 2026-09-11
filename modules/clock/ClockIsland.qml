import QtQuick
import qs.services
import qs.theme
import qs.components

GlassContainer {
    id: root
    height: 32
    width: timeText.implicitWidth + 28

    StyledText {
        id: timeText
        anchors.centerIn: parent
        text: Time.time
        font.pixelSize: Typography.sizeTitle
        font.weight: Typography.weightBold
    }
}
