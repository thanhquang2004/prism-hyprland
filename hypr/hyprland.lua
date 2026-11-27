-- Hyprland 0.57 config for the Prism desktop.
-- Lives in ~/.config/prism/hypr and is linked to ~/.config/hypr/hyprland.lua.
-- Settings come from the old JaKooLit .conf files (ported by hand), window
-- rules from gen_rules.py (rules.lua), binds from keybinds.lua.

local home   = os.getenv("HOME")
local prism  = home .. "/.config/prism"
local scripts = home .. "/.config/hypr/scripts"
local qsPrism = "quickshell -p " .. prism .. "/shell"

require("monitors")

---------------------------------------------------------------- environment

hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_QUICK_CONTROLS_STYLE", "org.hyprland.style")
hl.env("GDK_SCALE", "1")
hl.env("QT_SCALE_FACTOR", "1")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("EDITOR", "vim")

---------------------------------------------------------------- autostart

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("swww-daemon --format xrgb")
    hl.exec_cmd(scripts .. "/Polkit.sh")
    hl.exec_cmd(scripts .. "/Hyprsunset.sh init")
    hl.exec_cmd("kitty --class kitty-dropterm")
    hl.exec_cmd(scripts .. "/KeybindsLayoutInit.sh")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("qs -c overview")
    hl.exec_cmd("easyeffects --service-mode --hide-window")
    hl.exec_cmd("sh -c 'sleep 4; easyeffects -l waner-sg2-smooth'")
    -- Prism: shell (bar, notifications, OSD, control center, wallpapers) and idle/lock
    hl.exec_cmd(qsPrism)
    hl.exec_cmd("hypridle -c " .. prism .. "/lock/hypridle.conf")
end)

---------------------------------------------------------------- look and feel

hl.config({
    general = {
        border_size = 2,
        gaps_in = 3,
        gaps_out = 6,
        resize_on_border = true,
        layout = "dwindle",
        col = {
            active_border = "rgb(F67C8B)",
            inactive_border = "rgb(525974)",
        },
    },
    decoration = {
        rounding = 12,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        fullscreen_opacity = 1.0,
        dim_inactive = false,
        dim_strength = 0.1,
        dim_special = 0.8,
        shadow = {
            enabled = true,
            range = 3,
            render_power = 1,
            color = "rgb(F67C8B)",
            color_inactive = "rgb(525974)",
        },
        blur = {
            enabled = true,
            size = 6,
            passes = 3,
            new_optimizations = true,
            xray = false,
            ignore_opacity = true,
            special = true,
            popups = true,
        },
        -- 0.57: windows wobble while they are dragged or resized
        wobble = {
            enabled = true,
        },
    },
    group = {
        col = { border_active = "rgb(8ED9E7)" },
        groupbar = { col = { active = "rgb(3E3E40)" } },
    },
    dwindle = {
        preserve_split = true,
        special_scale_factor = 0.8,
    },
    master = {
        new_status = "master",
        new_on_top = true,
        mfact = 0.5,
    },
    input = {
        kb_layout = "us",
        repeat_rate = 50,
        repeat_delay = 300,
        sensitivity = 0.6,
        accel_profile = "adaptive",
        force_no_accel = false,
        numlock_by_default = true,
        left_handed = false,
        follow_mouse = 1,
        float_switch_override_focus = false,
        touchpad = {
            disable_while_typing = true,
            natural_scroll = true,
            clickfinger_behavior = false,
            middle_button_emulation = false,
            tap_to_click = true,
            tap_and_drag = false,
            drag_lock = false,
            scroll_factor = 1.2,
        },
        touchdevice = { enabled = true },
    },
    gestures = {
        workspace_swipe_distance = 500,
        workspace_swipe_invert = true,
        workspace_swipe_min_speed_to_force = 30,
        workspace_swipe_cancel_ratio = 0.5,
        workspace_swipe_create_new = true,
        workspace_swipe_forever = true,
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        vrr = 2,
        mouse_move_enables_dpms = true,
        enable_swallow = false,
        swallow_regex = "^(kitty)$",
        focus_on_activate = false,
        initial_workspace_tracking = 0,
        middle_click_paste = false,
        enable_anr_dialog = true,
        anr_missed_pings = 15,
        allow_session_lock_restore = true,
        on_focus_under_fullscreen = 1,
    },
    binds = {
        workspace_back_and_forth = true,
        allow_workspace_cycles = true,
        pass_mouse_when_bound = false,
    },
    xwayland = {
        enabled = true,
        force_zero_scaling = true,
    },
    render = {
        direct_scanout = 0,
    },
    cursor = {
        sync_gsettings_theme = true,
        no_hardware_cursors = false,
        enable_hyprcursor = true,
        warp_on_change_workspace = 2,
        no_warps = true,
    },
})

hl.device({ name = "elan0678:00-04f3:3195-touchpad", enabled = true })
hl.device({ name = "cx-2.4g-receiver-mouse", sensitivity = -0.3 })
hl.device({ name = "wch.cn-usb2iic_ctp_control", enabled = false })

---------------------------------------------------------------- animations

hl.config({ animations = { enabled = true } })

hl.curve("wind",      { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("winIn",     { type = "bezier", points = { { 0.1, 1.1 },  { 0.1, 1.1 } } })
hl.curve("winOut",    { type = "bezier", points = { { 0.3, -0.3 }, { 0, 1 } } })
hl.curve("liner",     { type = "bezier", points = { { 1, 1 },      { 1, 1 } } })
hl.curve("overshot",  { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("smoothOut", { type = "bezier", points = { { 0.5, 0 },    { 0.99, 0.99 } } })

hl.animation({ leaf = "windows",       enabled = true, speed = 6,   bezier = "wind",      style = "slide" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 5,   bezier = "winIn",     style = "slide" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 3,   bezier = "smoothOut", style = "slide" })
hl.animation({ leaf = "windowsMove",   enabled = true, speed = 5,   bezier = "wind",      style = "slide" })
hl.animation({ leaf = "border",        enabled = true, speed = 1,   bezier = "liner" })
hl.animation({ leaf = "borderangle",   enabled = true, speed = 100, bezier = "liner",     style = "loop" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3,   bezier = "smoothOut" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 5,   bezier = "overshot" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 5,   bezier = "winIn",     style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 5,   bezier = "winOut",    style = "slide" })

---------------------------------------------------------------- gestures

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "up", action = function() hl.exec_cmd(scripts .. "/OverviewToggle.sh") end })
-- Prism: three fingers down opens the control center on the focused screen
hl.gesture({ fingers = 3, direction = "down", action = function() hl.exec_cmd(qsPrism:gsub("^quickshell", "quickshell ipc") .. " call cc toggle") end })
hl.gesture({ fingers = 4, direction = "up",   action = "cursor_zoom", zoom_level = 1.5, mode = "mult" })
hl.gesture({ fingers = 4, direction = "down", action = "cursor_zoom", zoom_level = 0.667, mode = "mult" })

---------------------------------------------------------------- drop-down terminal

hl.window_rule({
    name = "dropterm",
    match = { class = "^(kitty-dropterm)$" },
    float = true,
    size = "(monitor_w*0.7) (monitor_h*0.55)",
    move = "(monitor_w*0.15) (monitor_h*0.06)",
    workspace = "special:dropterm silent",
})
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "wind", style = "slidevert" })

---------------------------------------------------------------- Prism layers

for _, ns in ipairs({ "prism-bar", "prism-notifs", "prism-osd", "prism-cc" }) do
    hl.layer_rule({ match = { namespace = ns }, blur = true, ignore_alpha = 0.1 })
end
hl.layer_rule({ match = { namespace = "prism-power" }, blur = true })

---------------------------------------------------------------- rules and binds

require("rules")
require("keybinds")
