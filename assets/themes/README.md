# Theme selection

The wallpaper picker has a theme dropdown with **Dynamic**, **Nord**, and all
four Catppuccin flavors: **Latte**, **Frappé**, **Macchiato**, and **Mocha**.
Only Dynamic shows the Matugen scheme chips (Tonal spot, Content, etc.).
`[` / `]` cycle those chips only while Dynamic is selected. Switching back to
Dynamic restores the last dynamic scheme selected during the shell session.

Preview, Enter to apply, and Escape to restore the previous selection work for
all themes. Applying saves the theme in the existing wallpaper state, so later
wallpaper choices keep using it.

The JSON files map fixed theme colors onto the Material color roles used by
the shell and configured app templates. They are adaptations of the palettes,
rather than native themes for each app:

- [Catppuccin palettes](https://catppuccin.com/palette/), with mauve as the primary accent.
- [Nord palette](https://www.nordtheme.com/docs/colors-and-palettes/), with frost as the primary accent.

`scripts/set-wallpaper.sh` imports them with `matugen json`, using the existing
Matugen configuration, output paths, and reload hooks. Latte supplies light
colors; the other palettes supply dark colors. The image only sets the
wallpaper in this mode and does not affect the colors. Matugen must support
its `json` subcommand.

To add another static theme, provide a JSON palette here, allow its ID in
`scripts/set-wallpaper.sh`, and add its label to `WallpaperService.themes`.
