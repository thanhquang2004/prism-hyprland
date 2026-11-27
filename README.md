# Prism

Personal Hyprland desktop: frosted glass, one island per screen, no bar.
Design brief: see `docs/DESIGN.md`.

## Run (testing alongside the current setup)

```sh
hyprctl keyword layerrule "match:namespace prism-island, blur on"
hyprctl keyword layerrule "match:namespace prism-island, ignore_alpha 0.3"
quickshell -p ~/.config/prism/shell
```

## Layout

- `shell/`: Quickshell (QML) UI
  - `shell.qml`: entry point, one island per screen
  - `Theme.qml`: design tokens (colors, type, motion)
  - `island/`: the island and its parts
