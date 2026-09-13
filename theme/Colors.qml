pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var palette: ({})

    readonly property color background: palette.background ?? "#18111a"
    readonly property color error: palette.error ?? "#ffb4ab"
    readonly property color error_container: palette.error_container ?? "#93000a"
    readonly property color inverse_on_surface: palette.inverse_on_surface ?? "#362e38"
    readonly property color inverse_primary: palette.inverse_primary ?? "#9600d4"
    readonly property color inverse_surface: palette.inverse_surface ?? "#ecdeec"
    readonly property color on_background: palette.on_background ?? "#ecdeec"
    readonly property color on_error: palette.on_error ?? "#690005"
    readonly property color on_error_container: palette.on_error_container ?? "#ffdad6"
    readonly property color on_primary: palette.on_primary ?? "#500074"
    readonly property color on_primary_container: palette.on_primary_container ?? "#f6d9ff"
    readonly property color on_primary_fixed: palette.on_primary_fixed ?? "#310049"
    readonly property color on_primary_fixed_variant: palette.on_primary_fixed_variant ?? "#7200a3"
    readonly property color on_secondary: palette.on_secondary ?? "#422741"
    readonly property color on_secondary_container: palette.on_secondary_container ?? "#fed7f9"
    readonly property color on_secondary_fixed: palette.on_secondary_fixed ?? "#2b122b"
    readonly property color on_secondary_fixed_variant: palette.on_secondary_fixed_variant ?? "#5a3d59"
    readonly property color on_surface: palette.on_surface ?? "#ecdeec"
    readonly property color on_surface_variant: palette.on_surface_variant ?? "#cfc3d0"
    readonly property color on_tertiary: palette.on_tertiary ?? "#4c213f"
    readonly property color on_tertiary_container: palette.on_tertiary_container ?? "#ffd8ed"
    readonly property color on_tertiary_fixed: palette.on_tertiary_fixed ?? "#340b29"
    readonly property color on_tertiary_fixed_variant: palette.on_tertiary_fixed_variant ?? "#663757"
    readonly property color outline: palette.outline ?? "#988d9a"
    readonly property color outline_variant: palette.outline_variant ?? "#4d444f"
    readonly property color primary: palette.primary ?? "#e8b3ff"
    readonly property color primary_container: palette.primary_container ?? "#7200a3"
    readonly property color primary_fixed: palette.primary_fixed ?? "#f6d9ff"
    readonly property color primary_fixed_dim: palette.primary_fixed_dim ?? "#e8b3ff"
    readonly property color scrim: palette.scrim ?? "#000000"
    readonly property color secondary: palette.secondary ?? "#e1bbdd"
    readonly property color secondary_container: palette.secondary_container ?? "#5a3d59"
    readonly property color secondary_fixed: palette.secondary_fixed ?? "#fed7f9"
    readonly property color secondary_fixed_dim: palette.secondary_fixed_dim ?? "#e1bbdd"
    readonly property color shadow: palette.shadow ?? "#000000"
    readonly property color source_color: palette.source_color ?? "#5a376b"
    readonly property color surface: palette.surface ?? "#18111a"
    readonly property color surface_bright: palette.surface_bright ?? "#3f3641"
    readonly property color surface_container: palette.surface_container ?? "#241d27"
    readonly property color surface_container_high: palette.surface_container_high ?? "#2f2731"
    readonly property color surface_container_highest: palette.surface_container_highest ?? "#3a323c"
    readonly property color surface_container_low: palette.surface_container_low ?? "#201923"
    readonly property color surface_container_lowest: palette.surface_container_lowest ?? "#120c15"
    readonly property color surface_dim: palette.surface_dim ?? "#18111a"
    readonly property color surface_tint: palette.surface_tint ?? "#e8b3ff"
    readonly property color surface_variant: palette.surface_variant ?? "#4d444f"
    readonly property color tertiary: palette.tertiary ?? "#f3b4da"
    readonly property color tertiary_container: palette.tertiary_container ?? "#663757"
    readonly property color tertiary_fixed: palette.tertiary_fixed ?? "#ffd8ed"
    readonly property color tertiary_fixed_dim: palette.tertiary_fixed_dim ?? "#f3b4da"

    FileView {
        path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/quickshell/colors.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                if (parsed && typeof parsed === "object")
                    root.palette = parsed;
            } catch (error) {
                return;
            }
        }
    }
}
