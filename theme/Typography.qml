pragma Singleton

import Quickshell
import QtQuick

Singleton {
    // TODO: check the Google Sans Flex setup: it only works when registered with fontconfig (~/.local/share/fonts/GoogleSansFlex.ttf -> assets/fonts/GoogleSansFlex.ttf, then fc-cache -f); consider managing the symlink with chezmoi
    readonly property string family: "Google Sans Flex"
    readonly property string iconFamily: "Material Symbols Rounded"

    readonly property int sizeSmall: 10
    readonly property int sizeCaption: 11
    readonly property int sizeBody: 12
    readonly property int sizeTitle: 13
    readonly property int sizeHeader: 14
    readonly property int sizeIconSmall: 14
    readonly property int sizeIconMedium: 18
    readonly property int sizeIconLarge: 24

    readonly property int weightNormal: Font.Normal
    readonly property int weightMedium: Font.Medium
    readonly property int weightBold: Font.DemiBold
}
