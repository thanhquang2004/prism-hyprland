-- keybinds.lua: your JaKooLit keybinds converted for Hyprland 0.57 (Lua config).
-- Generated from `hyprctl binds -j` on Hyprland 0.56.2 (configs/Keybinds.conf + UserConfigs/UserKeybinds.conf).
-- Use it from hyprland.lua with:  require("keybinds")
-- Load it AFTER any dotfiles/shell that defines its own binds so yours win.

local mainMod     = "SUPER"
local scripts     = os.getenv("HOME") .. "/.config/hypr/scripts"
local userScripts = os.getenv("HOME") .. "/.config/hypr/UserScripts"

-- Cursor zoom (replaces the old `hyprctl keyword cursor:zoom_factor` one-liners)
local function zoom(factor)
    return function()
        local cur = tonumber(hl.get_config("cursor.zoom_factor")) or 1
        if cur < 1 then cur = 1 end
        hl.config({ cursor = { zoom_factor = math.max(1, cur * factor) } })
    end
end

------------------------------------------------------------
-- Apps & launchers
------------------------------------------------------------
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("pkill rofi || true && rofi -show drun -modi drun,filebrowser,run,window"), { description = "app launcher" })
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("xdg-open \"https://\""), { description = "open default browser" })
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(scripts .. "/OverviewToggle.sh"), { description = "desktop overview" })
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("kitty"), { description = "Open terminal" })
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("thunar"), { description = "file manager" })
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(scripts .. "/ThemeChanger.sh"), { description = "Global theme switcher using Wallust" })
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd(scripts .. "/KeyHints.sh"), { description = "help / cheat sheet" })
hl.bind(mainMod .. " + ALT + R", hl.dsp.exec_cmd("quickshell kill -p ~/.config/prism/shell; quickshell -p ~/.config/prism/shell -d"), { description = "restart Prism" })
hl.bind(mainMod .. " + ALT + E", hl.dsp.exec_cmd(scripts .. "/RofiEmoji.sh"), { description = "emoji menu" })
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd(scripts .. "/RofiSearch.sh"), { description = "web search" })
hl.bind(mainMod .. " + CTRL + S", hl.dsp.exec_cmd("rofi -show window"), { description = "window switcher" })
hl.bind(mainMod .. " + ALT + O", hl.dsp.exec_cmd("quickshell ipc -p ~/.config/prism/shell call hypr toggleBlur"), { description = "toggle blur" })
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd("quickshell ipc -p ~/.config/prism/shell call hypr toggleGameMode"), { description = "toggle game mode" })
hl.bind(mainMod .. " + ALT + L", hl.dsp.exec_cmd("quickshell ipc -p ~/.config/prism/shell call hypr toggleLayout"), { description = "toggle master/dwindle layout" })
hl.bind(mainMod .. " + ALT + V", hl.dsp.exec_cmd(scripts .. "/ClipManager.sh"), { description = "clipboard manager" })
hl.bind(mainMod .. " + CTRL + R", hl.dsp.exec_cmd(scripts .. "/RofiThemeSelector.sh"), { description = "rofi theme selector" })
hl.bind(mainMod .. " + CTRL + SHIFT + R", hl.dsp.exec_cmd("pkill rofi || true && " .. scripts .. "/RofiThemeSelector-modified.sh"), { description = "rofi theme selector (modified)" })
-- TODO SUPER + ALT + space (Float all windows): workspaceopt allfloat was removed in the Lua API; no direct replacement
-- Drop-down terminal: a kitty living on a special workspace (rules in hyprland.lua)
hl.bind(mainMod .. " + SHIFT + Return", function()
    hl.exec_cmd("pgrep -f 'kitty --class kitty-dropterm' >/dev/null || kitty --class kitty-dropterm")
    hl.dispatch(hl.dsp.workspace.toggle_special("dropterm"))
end, { description = "DropDown terminal" })
hl.bind(mainMod .. " + ALT + mouse_down", zoom(2.0), { description = "zoom in" })
hl.bind(mainMod .. " + ALT + mouse_up", zoom(0.5), { description = "zoom out" })
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd(scripts .. "/Hyprsunset.sh toggle"), { description = "toggle night light" })
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd(userScripts .. "/RofiBeats.sh"), { description = "online music" })
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(userScripts .. "/WallpaperSelect.sh"), { description = "select wallpaper" })
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(userScripts .. "/WallpaperEffects.sh"), { description = "wallpaper effects" })
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.exec_cmd(scripts .. "/KeyBinds.sh"), { description = "search keybinds" })
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd(scripts .. "/Animations.sh"), { description = "animations menu" })
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd(userScripts .. "/ZshChangeTheme.sh"), { description = "change oh-my-zsh theme" })
hl.bind(mainMod .. " + ALT + C", hl.dsp.exec_cmd(userScripts .. "/RofiCalc.sh"), { description = "calculator" })
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd(scripts .. "/KillActiveProcess.sh"), { description = "Terminate active process" })
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("quickshell ipc -p ~/.config/prism/shell call notifs toggle"), { description = "notification panel" })
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd(scripts .. "/Kool_Quick_Settings.sh"), { description = "Quick settings menu" })
hl.bind(mainMod .. " + M", hl.dsp.layout("splitratio 0.3"), { description = "set split ratio 0.3" })

------------------------------------------------------------
-- Window management
------------------------------------------------------------
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), { description = "fullscreen" })
hl.bind(mainMod .. " + CTRL + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }), { description = "maximize window" })
hl.bind(mainMod .. " + space", hl.dsp.window.float({ action = "toggle" }), { description = "Float current window" })
hl.bind(mainMod .. " + CTRL + O", hl.dsp.window.set_prop({ prop = "opaque", value = "toggle" }), { description = "toggle active window opacity" })
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "close active window" })
hl.bind(mainMod .. " + CTRL + D", hl.dsp.layout("removemaster"), { description = "remove master" })
hl.bind(mainMod .. " + I", hl.dsp.layout("addmaster"), { description = "add master" })
hl.bind(mainMod .. " + CTRL + Return", hl.dsp.layout("swapwithmaster"), { description = "swap with master" })
hl.bind(mainMod .. " + SHIFT + I", hl.dsp.layout("togglesplit"), { description = "toggle split (dwindle)" })
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo(), { description = "toggle pseudo (dwindle)" })
hl.bind("ALT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end, { description = "cycle next window + bring active to top" })
hl.bind(mainMod .. " + SHIFT + Left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true, description = "resize left (-50)" })
hl.bind(mainMod .. " + SHIFT + Right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true, description = "resize right (+50)" })
hl.bind(mainMod .. " + SHIFT + Up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true, description = "resize up (-50)" })
hl.bind(mainMod .. " + SHIFT + Down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true, description = "resize down (+50)" })
hl.bind(mainMod .. " + CTRL + Left", hl.dsp.window.move({ direction = "left" }), { description = "move window left" })
hl.bind(mainMod .. " + CTRL + Right", hl.dsp.window.move({ direction = "right" }), { description = "move window right" })
hl.bind(mainMod .. " + CTRL + Up", hl.dsp.window.move({ direction = "up" }), { description = "move window up" })
hl.bind(mainMod .. " + CTRL + Down", hl.dsp.window.move({ direction = "down" }), { description = "move window down" })
hl.bind(mainMod .. " + ALT + Left", hl.dsp.window.swap({ direction = "left" }), { description = "swap window left" })
hl.bind(mainMod .. " + ALT + Right", hl.dsp.window.swap({ direction = "right" }), { description = "swap window right" })
hl.bind(mainMod .. " + ALT + Up", hl.dsp.window.swap({ direction = "up" }), { description = "swap window up" })
hl.bind(mainMod .. " + ALT + Down", hl.dsp.window.swap({ direction = "down" }), { description = "swap window down" })
hl.bind(mainMod .. " + Left", hl.dsp.focus({ direction = "left" }), { description = "focus left" })
hl.bind(mainMod .. " + Right", hl.dsp.focus({ direction = "right" }), { description = "focus right" })
hl.bind(mainMod .. " + Up", hl.dsp.focus({ direction = "up" }), { description = "focus up" })
hl.bind(mainMod .. " + Down", hl.dsp.focus({ direction = "down" }), { description = "focus down" })
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "move window" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "resize window" })
hl.bind(mainMod .. " + J", hl.dsp.window.cycle_next())
hl.bind(mainMod .. " + K", hl.dsp.window.cycle_next({ next = false }))

------------------------------------------------------------
-- Groups
------------------------------------------------------------
hl.bind(mainMod .. " + G", hl.dsp.group.toggle(), { description = "toggle group" })
hl.bind(mainMod .. " + Tab", function()
    hl.dispatch(hl.dsp.group.next())
    hl.dispatch(hl.dsp.focus({ workspace = "m+1" }))
end, { description = "Change Group Forward + next workspace" })
hl.bind(mainMod .. " + CTRL + Tab", hl.dsp.group.next(), { description = "change active in group" })
hl.bind(mainMod .. " + SHIFT + Tab", function()
    hl.dispatch(hl.dsp.group.prev())
    hl.dispatch(hl.dsp.focus({ workspace = "m-1" }))
end, { description = "Change Group Back + previous workspace" })
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.move({ into_group = "left" }), { description = "Move left into group" })
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.move({ into_group = "right" }), { description = "Move Right into group" })
hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.move({ out_of_group = true }), { description = "Move active out of group" })

------------------------------------------------------------
-- Workspaces & monitors
------------------------------------------------------------
hl.bind(mainMod .. " + CTRL + F9", hl.dsp.workspace.move({ monitor = "l" }), { description = "move workspace to left monitor" })
hl.bind(mainMod .. " + CTRL + F10", hl.dsp.workspace.move({ monitor = "r" }), { description = "move workspace to right monitor" })
hl.bind(mainMod .. " + CTRL + F11", hl.dsp.workspace.move({ monitor = "u" }), { description = "move workspace to up monitor" })
hl.bind(mainMod .. " + CTRL + F12", hl.dsp.workspace.move({ monitor = "d" }), { description = "move workspace to down monitor" })
hl.bind(mainMod .. " + SHIFT + U", hl.dsp.window.move({ workspace = "special:special" }), { description = "move to special workspace" })
hl.bind(mainMod .. " + U", hl.dsp.workspace.toggle_special("special"), { description = "toggle special workspace" })
hl.bind(mainMod .. " + code:10", hl.dsp.focus({ workspace = 1 }), { description = "workspace 1" })
hl.bind(mainMod .. " + code:11", hl.dsp.focus({ workspace = 2 }), { description = "workspace 2" })
hl.bind(mainMod .. " + code:12", hl.dsp.focus({ workspace = 3 }), { description = "workspace 3" })
hl.bind(mainMod .. " + code:13", hl.dsp.focus({ workspace = 4 }), { description = "workspace 4" })
hl.bind(mainMod .. " + code:14", hl.dsp.focus({ workspace = 5 }), { description = "workspace 5" })
hl.bind(mainMod .. " + code:15", hl.dsp.focus({ workspace = 6 }), { description = "workspace 6" })
hl.bind(mainMod .. " + code:16", hl.dsp.focus({ workspace = 7 }), { description = "workspace 7" })
hl.bind(mainMod .. " + code:17", hl.dsp.focus({ workspace = 8 }), { description = "workspace 8" })
hl.bind(mainMod .. " + code:18", hl.dsp.focus({ workspace = 9 }), { description = "workspace 9" })
hl.bind(mainMod .. " + code:19", hl.dsp.focus({ workspace = 10 }), { description = "workspace 10" })
hl.bind(mainMod .. " + SHIFT + code:10", hl.dsp.window.move({ workspace = 1 }), { description = "move to workspace 1" })
hl.bind(mainMod .. " + SHIFT + code:11", hl.dsp.window.move({ workspace = 2 }), { description = "move to workspace 2" })
hl.bind(mainMod .. " + SHIFT + code:12", hl.dsp.window.move({ workspace = 3 }), { description = "move to workspace 3" })
hl.bind(mainMod .. " + SHIFT + code:13", hl.dsp.window.move({ workspace = 4 }), { description = "move to workspace 4" })
hl.bind(mainMod .. " + SHIFT + code:14", hl.dsp.window.move({ workspace = 5 }), { description = "move to workspace 5" })
hl.bind(mainMod .. " + SHIFT + code:15", hl.dsp.window.move({ workspace = 6 }), { description = "move to workspace 6" })
hl.bind(mainMod .. " + SHIFT + code:16", hl.dsp.window.move({ workspace = 7 }), { description = "move to workspace 7" })
hl.bind(mainMod .. " + SHIFT + code:17", hl.dsp.window.move({ workspace = 8 }), { description = "move to workspace 8" })
hl.bind(mainMod .. " + SHIFT + code:18", hl.dsp.window.move({ workspace = 9 }), { description = "move to workspace 9" })
hl.bind(mainMod .. " + SHIFT + code:19", hl.dsp.window.move({ workspace = 10 }), { description = "move to workspace 10" })
hl.bind(mainMod .. " + SHIFT + bracketleft", hl.dsp.window.move({ workspace = -1 }), { description = "move to previous workspace" })
hl.bind(mainMod .. " + SHIFT + bracketright", hl.dsp.window.move({ workspace = "+1" }), { description = "move to next workspace" })
hl.bind(mainMod .. " + CTRL + code:10", hl.dsp.window.move({ workspace = 1, follow = false }), { description = "move silently to workspace 1" })
hl.bind(mainMod .. " + CTRL + code:11", hl.dsp.window.move({ workspace = 2, follow = false }), { description = "move silently to workspace 2" })
hl.bind(mainMod .. " + CTRL + code:12", hl.dsp.window.move({ workspace = 3, follow = false }), { description = "move silently to workspace 3" })
hl.bind(mainMod .. " + CTRL + code:13", hl.dsp.window.move({ workspace = 4, follow = false }), { description = "move silently to workspace 4" })
hl.bind(mainMod .. " + CTRL + code:14", hl.dsp.window.move({ workspace = 5, follow = false }), { description = "move silently to workspace 5" })
hl.bind(mainMod .. " + CTRL + code:15", hl.dsp.window.move({ workspace = 6, follow = false }), { description = "move silently to workspace 6" })
hl.bind(mainMod .. " + CTRL + code:16", hl.dsp.window.move({ workspace = 7, follow = false }), { description = "move silently to workspace 7" })
hl.bind(mainMod .. " + CTRL + code:17", hl.dsp.window.move({ workspace = 8, follow = false }), { description = "move silently to workspace 8" })
hl.bind(mainMod .. " + CTRL + code:18", hl.dsp.window.move({ workspace = 9, follow = false }), { description = "move silently to workspace 9" })
hl.bind(mainMod .. " + CTRL + code:19", hl.dsp.window.move({ workspace = 10, follow = false }), { description = "move silently to workspace 10" })
hl.bind(mainMod .. " + CTRL + bracketleft", hl.dsp.window.move({ workspace = -1, follow = false }), { description = "move silently to previous workspace" })
hl.bind(mainMod .. " + CTRL + bracketright", hl.dsp.window.move({ workspace = "+1", follow = false }), { description = "move silently to next workspace" })
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "next workspace" })
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "previous workspace" })
hl.bind(mainMod .. " + period", hl.dsp.focus({ workspace = "e+1" }), { description = "next workspace" })
hl.bind(mainMod .. " + comma", hl.dsp.focus({ workspace = "e-1" }), { description = "previous workspace" })

------------------------------------------------------------
-- Screenshots
------------------------------------------------------------
hl.bind("Print", hl.dsp.exec_cmd("~/.local/bin/screenshot.sh"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("pkill -x grim; pkill -x swappy; sleep 0.1; grim -g \"$(slurp)\" - | wl-copy"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd(scripts .. "/ScreenShot.sh --now"), { description = "screenshot now" })
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd(scripts .. "/ScreenShot.sh --area"), { description = "screenshot (area)" })
hl.bind(mainMod .. " + CTRL + Print", hl.dsp.exec_cmd(scripts .. "/ScreenShot.sh --in5"), { description = "screenshot in 5s" })
hl.bind(mainMod .. " + CTRL + SHIFT + Print", hl.dsp.exec_cmd(scripts .. "/ScreenShot.sh --in10"), { description = "screenshot in 10s" })
hl.bind("ALT + Print", hl.dsp.exec_cmd(scripts .. "/ScreenShot.sh --active"), { description = "screenshot active window" })
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(scripts .. "/ScreenShot.sh --swappy"), { description = "screenshot (swappy)" })
hl.bind(mainMod .. " + F6", hl.dsp.exec_cmd(scripts .. "/ScreenShot.sh --now"))
hl.bind(mainMod .. " + SHIFT + F6", hl.dsp.exec_cmd(scripts .. "/ScreenShot.sh --area"))
hl.bind(mainMod .. " + CTRL + F6", hl.dsp.exec_cmd(scripts .. "/ScreenShot.sh --in5"))
hl.bind(mainMod .. " + ALT + F6", hl.dsp.exec_cmd(scripts .. "/ScreenShot.sh --in10"))
hl.bind("ALT + F6", hl.dsp.exec_cmd(scripts .. "/ScreenShot.sh --active"))

------------------------------------------------------------
-- Media, volume, brightness & hardware keys
------------------------------------------------------------
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(scripts .. "/Volume.sh --inc"), { locked = true, repeating = true, description = "volume up" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(scripts .. "/Volume.sh --dec"), { locked = true, repeating = true, description = "volume down" })
hl.bind("ALT + XF86AudioRaiseVolume", hl.dsp.exec_cmd(scripts .. "/Volume.sh --inc-precise"), { locked = true, repeating = true, description = "volume up precise" })
hl.bind("ALT + XF86AudioLowerVolume", hl.dsp.exec_cmd(scripts .. "/Volume.sh --dec-precise"), { locked = true, repeating = true, description = "volume down precise" })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(scripts .. "/Volume.sh --toggle-mic"), { locked = true, description = "toggle mic mute" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(scripts .. "/Volume.sh --toggle"), { locked = true, description = "toggle mute" })
hl.bind("XF86Sleep", hl.dsp.exec_cmd("systemctl suspend"), { locked = true, description = "sleep" })
hl.bind("XF86RFKill", hl.dsp.exec_cmd(scripts .. "/AirplaneMode.sh"), { locked = true, description = "airplane mode" })
-- TODO INVALID:xf86AudioPlayPause (play/pause): not a real XKB key name, so this bind never fired on 0.56 either
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(scripts .. "/MediaCtrl.sh --pause"), { locked = true, description = "pause" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd(scripts .. "/MediaCtrl.sh --pause"), { locked = true, description = "play" })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd(scripts .. "/MediaCtrl.sh --nxt"), { locked = true, description = "next track" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd(scripts .. "/MediaCtrl.sh --prv"), { locked = true, description = "previous track" })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd(scripts .. "/MediaCtrl.sh --stop"), { locked = true, description = "stop" })
hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd(scripts .. "/BrightnessKbd.sh --dec"), { repeating = true })
hl.bind("XF86KbdBrightnessUp", hl.dsp.exec_cmd(scripts .. "/BrightnessKbd.sh --inc"), { repeating = true })
hl.bind("XF86Launch1", hl.dsp.exec_cmd("rog-control-center"))
hl.bind("XF86Launch3", hl.dsp.exec_cmd("asusctl led-mode -n"))
hl.bind("XF86Launch4", hl.dsp.exec_cmd("asusctl profile -n"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(scripts .. "/Brightness.sh --dec"), { repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(scripts .. "/Brightness.sh --inc"), { repeating = true })
hl.bind("XF86TouchpadToggle", hl.dsp.exec_cmd(scripts .. "/TouchPad.sh"))

------------------------------------------------------------
-- Session, system & misc
------------------------------------------------------------
hl.bind("CTRL + ALT + W", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/prism-wall"), { description = "random wallpaper (focused screen)" })
hl.bind("CTRL + ALT + SHIFT + W", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/prism-wall all"), { description = "random wallpaper (all screens)" })
hl.bind("ALT + Shift_L", hl.dsp.exec_cmd(scripts .. "/KeyboardLayout.sh switch"), { locked = true, non_consuming = true, description = "switch keyboard layout globally" })
hl.bind("SHIFT + Alt_L", hl.dsp.exec_cmd(scripts .. "/Tak0-Per-Window-Switch.sh"), { locked = true, non_consuming = true, description = "switch keyboard layout per-window" })
hl.bind("CTRL + ALT + Delete", hl.dsp.exit(), { description = "exit Hyprland" })
hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/prism-lock"), { description = "lock screen" })
hl.bind("CTRL + ALT + P", hl.dsp.exec_cmd("quickshell ipc -p ~/.config/prism/shell call power toggle"), { description = "power menu" })

-- Prism
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("quickshell ipc -p ~/.config/prism/shell call cc toggle"), { description = "control center" })
