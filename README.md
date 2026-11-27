# Prism

Personal Hyprland desktop: frosted glass, one floating bar per screen.
Design brief: see `docs/DESIGN.md`.

## Run (testing alongside the current setup)

```sh
hyprctl keyword layerrule "match:namespace prism-bar, blur on"
hyprctl keyword layerrule "match:namespace prism-bar, ignore_alpha 0.1"
hyprctl keyword layerrule "match:namespace prism-power, blur on"
hyprctl keyword layerrule "match:namespace prism-notifs, blur on"
hyprctl keyword layerrule "match:namespace prism-notifs, ignore_alpha 0.1"
hyprctl keyword layerrule "match:namespace prism-osd, blur on"
hyprctl keyword layerrule "match:namespace prism-osd, ignore_alpha 0.1"
hyprctl keyword layerrule "match:namespace prism-cc, blur on"
hyprctl keyword layerrule "match:namespace prism-cc, ignore_alpha 0.1"
quickshell -p ~/.config/prism/shell
```

## Layout

- `shell/`: Quickshell (QML) UI
  - `shell.qml`: entry point, one floating bar per screen
  - `Theme.qml`: design tokens (colors, type, motion)
  - `bar/`: the bar and its modules
  - `notifs/`: notification daemon UI: panel (grouped by app) and popups. Prism owns `org.freedesktop.Notifications`; swaync D-Bus auto-start is disabled by overrides in `~/.local/share/dbus-1/services/` (delete them to bring swaync back)
  - `power/`: fullscreen power menu (`quickshell ipc -p ~/.config/prism/shell call power toggle`)
  - `osd/`: volume / mic / brightness OSD (`Osd.qml` listens to PipeWire and kernel backlight uevents)
  - `Privacy.qml` + `bar/PrivacyIndicator.qml`: mic / camera / screen-share indicator
  - `cc/`: control center (quick toggles, sliders, Wi-Fi / Bluetooth / Sound pages); `Hypr.qml` sets Hyprland options on 0.56 and 0.57; `Wallpaper.qml` feeds the accent color
  - `Wallpaper.qml`: daily wallpaper per screen from `~/Pictures/wallpapers/prism/{landscape,portrait}` via swww; state in `~/.cache/prism/wallpaper.json` (`quickshell ipc -p ~/.config/prism/shell call wallpaper next [output]`, `rescan`, `state`)
- `wallpaper/crop_portrait.py`: portrait cuts of the landscape set, cached in `~/.cache/prism/wallpaper-portrait`
- `lock/`: lock screen. `prism-lock` (in `~/.local/bin`, Ctrl+Alt+L, hypridle `lock_cmd`) snapshots each screen and runs the Quickshell lock in `lock/qml` (WlSessionLock + PAM), falling back to a generated hyprlock config; `prism-lock --preview` runs it without PAM (unlock: `quickshell ipc -p ~/.config/prism/lock/qml call lock testUnlock`). `hypridle.conf` is started from `~/.config/hypr/configs/Startup_Apps.conf`
- `bin/prism-wall`: random wallpaper now (`prism-wall` = focused screen, `prism-wall all`, `prism-wall DP-1`); linked into `~/.local/bin`, bound to Ctrl+Alt+W / Ctrl+Alt+Shift+W in `~/.config/hypr/UserConfigs/UserKeybinds.conf` and `keybinds.lua`
  - `Icons.qml`: monochrome icon set
