# Prism

Personal Hyprland desktop: frosted glass, one floating bar per screen.
Design brief: see `docs/DESIGN.md`.

## Run (testing alongside the current setup)

```sh
hyprctl keyword layerrule "match:namespace prism-bar, blur on"
hyprctl keyword layerrule "match:namespace prism-bar, ignore_alpha 0.1"
hyprctl keyword layerrule "match:namespace prism-power, blur on"
quickshell -p ~/.config/prism/shell
```

## Layout

- `shell/`: Quickshell (QML) UI
  - `shell.qml`: entry point, one floating bar per screen
  - `Theme.qml`: design tokens (colors, type, motion)
  - `bar/`: the bar and its modules
  - `power/`: fullscreen power menu (`quickshell ipc -p ~/.config/prism/shell call power toggle`)
  - `Icons.qml`: monochrome icon set
