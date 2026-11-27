pragma Singleton

import QtQuick
import Quickshell

// Monochrome icon set: Material Design Icons from the Nerd Font, drawn in
// the current ink color. Apps are matched by app id keywords.
Singleton {
    readonly property var apps: [
        [["chrome", "chromium"], "\u{F02AF}"],
        [["firefox", "zen"], "\u{F0239}"],
        [["kitty", "alacritty", "foot", "wezterm", "terminal", "ghostty"], "\u{F018D}"],
        [["code", "vscodium", "cursor"], "\u{F0A1E}"],
        [["claude", "anthropic"], "\u{F06A9}"],
        [["thunar", "nautilus", "dolphin", "nemo", "files"], "\u{F024B}"],
        [["discord", "vesktop"], "\u{F066F}"],
        [["slack"], "\u{F04B1}"],
        [["telegram", "zalo", "signal", "whatsapp"], "\u{F0B79}"],
        [["outlook", "thunderbird", "mail"], "\u{F01EE}"],
        [["teams"], "\u{F02BB}"],
        [["spotify"], "\u{F04C7}"],
        [["mpv", "vlc", "celluloid"], "\u{F0567}"],
        [["steam"], "\u{F04D3}"],
        [["docker"], "\u{F0868}"],
        [["obsidian", "notion", "logseq"], "\u{F0219}"],
        [["gimp", "krita", "inkscape", "figma"], "\u{F02E9}"],
        [["calculator", "qalculate"], "\u{F00EC}"],
        [["settings", "pavucontrol", "nwg-displays", "blueman"], "\u{F0493}"]
    ]
    readonly property string fallback: "\u{F08C6}"

    function app(appId) {
        const id = (appId || "").toLowerCase();
        for (const [keys, glyph] of apps)
            if (keys.some(k => id.includes(k))) return glyph;
        return fallback;
    }

    // Notifications
    readonly property string bell: "\u{F009A}"
    readonly property string bellNone: "\u{F009C}"
    readonly property string bellOff: "\u{F009B}"
    readonly property string close: "\u{F0156}"
    readonly property string chevronDown: "\u{F0140}"

    // OSD and privacy
    readonly property string volHigh: "\u{F057E}"
    readonly property string volMid: "\u{F0580}"
    readonly property string volLow: "\u{F057F}"
    readonly property string volMute: "\u{F075F}"
    readonly property string mic: "\u{F036C}"
    readonly property string micOff: "\u{F036D}"
    readonly property string camera: "\u{F05A0}"
    readonly property string share: "\u{F0118}"
    readonly property string brightness: "\u{F00E0}"

    // Control center
    readonly property string wifi: "\u{F05A9}"
    readonly property string wifiOff: "\u{F05AA}"
    readonly property string wifiLock: "\u{F0341}"
    readonly property string bluetooth: "\u{F00AF}"
    readonly property string bluetoothOff: "\u{F00B2}"
    readonly property string bluetoothOn: "\u{F00B1}"
    readonly property string airplane: "\u{F001D}"
    readonly property string nightLight: "\u{F059B}"
    readonly property string darkMode: "\u{F050E}"
    readonly property string gamepad: "\u{F0297}"
    readonly property string blur: "\u{F00B5}"
    readonly property string layout: "\u{F0574}"
    readonly property string screenshot: "\u{F0E51}"
    readonly property string wallpaper: "\u{F02E9}"
    readonly property string speaker: "\u{F04C3}"
    readonly property string headphones: "\u{F02CB}"
    readonly property string check: "\u{F012C}"
    readonly property string chevronRight: "\u{F0142}"
    readonly property string chevronLeft: "\u{F0141}"

    // Theme
    readonly property string sun: "\u{F0599}"
    readonly property string moon: "\u{F0594}"

    // Power menu
    readonly property string lock: "\u{F033E}"
    readonly property string logout: "\u{F0343}"
    readonly property string suspend: "\u{F04B2}"
    readonly property string reboot: "\u{F0709}"
    readonly property string shutdown: "\u{F0425}"
}
