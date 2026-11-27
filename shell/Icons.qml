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
    readonly property string chevronUp: "\u{F0143}"

    // Power menu
    readonly property string lock: "\u{F033E}"
    readonly property string logout: "\u{F0343}"
    readonly property string suspend: "\u{F04B2}"
    readonly property string reboot: "\u{F0709}"
    readonly property string shutdown: "\u{F0425}"
}
