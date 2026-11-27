import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import "cyber"

// Prism lock screen. Started by `prism-lock`, which first saves a frame of
// every screen and writes ~/.cache/prism/lock/session.json:
//   { user, accent, theme, outputs: { "<name>": { shot, wall } } }
// theme: "prism" (LockSurface.qml) or "cyberpunk" (cyber/CyberSurface.qml).
// The process locks the session at once and quits after a successful unlock.
//
// PRISM_LOCK_TEST=1 never talks to PAM (Enter is ignored) and accepts
// `quickshell ipc -p <this dir> call lock testUnlock`, for previews.
ShellRoot {
    id: root

    readonly property bool testMode: Quickshell.env("PRISM_LOCK_TEST") === "1"
    readonly property string cache: Quickshell.env("HOME") + "/.cache/prism/lock"

    property string phase: "enter"      // enter | idle | checking | unlocking
    property string buffer: ""
    property string message: ""
    property int wrongCount: 0
    property string pamNote: ""         // last non-prompt PAM message (e.g. faillock)

    readonly property date now: clock.date
    SystemClock { id: clock; precision: SystemClock.Seconds }

    FileView { id: sessionFile; path: root.cache + "/session.json"; blockLoading: true; printErrors: false }
    readonly property var session: { try { return JSON.parse(sessionFile.text()); } catch (e) { return {}; } }
    readonly property color accent: "#" + (session.accent ?? "9ab4ff")
    readonly property string theme: session.theme ?? "prism"

    // Weather: written by the desktop's weather script
    FileView { id: weatherFile; path: Quickshell.env("HOME") + "/.cache/.weather_cache"; blockLoading: true; printErrors: false }
    readonly property string weather: {
        const lines = weatherFile.text().split("\n");
        if (lines.length < 3) return "";
        const desc = lines[1].trim().split(/\s{2,}/);
        const temp = (lines[2].match(/-?\d+°C/) ?? [""])[0];
        return (desc[0] ?? "") + "   " + temp + "  " + (desc[1] ?? "");
    }
    // "34°C OVERCAST", for the HUD
    readonly property string weatherShort: {
        const lines = weatherFile.text().split("\n");
        if (lines.length < 3) return "--";
        const desc = lines[1].trim().split(/\s{2,}/);
        const temp = (lines[2].match(/-?\d+°C/) ?? ["--"])[0];
        return (temp + " " + (desc[1] ?? "")).toUpperCase();
    }

    // user, host, kernel and boot time for the HUD
    property var sys: ({})
    property real bootEpoch: 0
    Process {
        running: true
        command: ["sh", "-c", "id -un; uname -n; uname -r; cut -d' ' -f1 /proc/uptime"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n");
                root.sys = { user: l[0], host: l[1], kernel: l[2] };
                root.bootEpoch = Date.now() / 1000 - parseFloat(l[3] || "0");
            }
        }
    }
    // CPU load 0..1 from /proc/stat, for the HUD graph
    property real cpu: 0
    property var cpuLast: null
    Process {
        id: cpuProc
        command: ["head", "-1", "/proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(/\s+/).slice(1).map(Number);
                const idle = f[3] + (f[4] || 0), total = f.reduce((a, b) => a + b, 0);
                if (root.cpuLast) {
                    const dt = total - root.cpuLast.total, di = idle - root.cpuLast.idle;
                    if (dt > 0) root.cpu = Math.max(0, Math.min(1, 1 - di / dt));
                }
                root.cpuLast = { total: total, idle: idle };
            }
        }
    }
    Timer { interval: 700; running: true; repeat: true; triggeredOnStart: true; onTriggered: cpuProc.running = true }

    readonly property string uptime: {
        const t = Math.max(0, Math.floor(now.getTime() / 1000 - bootEpoch));
        const p = n => String(n).padStart(2, "0");
        return p(Math.floor(t / 3600)) + ":" + p(Math.floor(t / 60) % 60) + ":" + p(t % 60);
    }

    // Keyboard layout of the main keyboard
    property string layout: ""
    Process {
        running: true
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const kb = JSON.parse(text).keyboards ?? [];
                    root.layout = (kb.find(k => k.main) ?? kb[0])?.active_keymap ?? "";
                } catch (e) {}
            }
        }
    }

    function type(t) {
        if (phase === "checking" || phase === "unlocking") return;
        message = "";
        buffer += t;
    }
    function backspace() { if (phase !== "checking" && phase !== "unlocking") buffer = buffer.slice(0, -1); }
    function clear() { if (phase !== "checking" && phase !== "unlocking") { buffer = ""; message = ""; } }
    function submit() {
        if (phase === "checking" || phase === "unlocking" || buffer === "") return;
        if (testMode) { message = "Preview mode: password not checked"; return; }
        pamNote = "";
        phase = "checking";
        pam.start();
    }
    function succeed() {
        message = "";
        phase = "unlocking";
        release.start();
    }

    PamContext {
        id: pam
        onMessageChanged: if (message && !responseRequired) root.pamNote = message
        onResponseRequiredChanged: if (responseRequired) respond(root.buffer)
        onCompleted: result => {
            if (result === PamResult.Success) {
                root.succeed();
                return;
            }
            root.buffer = "";
            root.phase = "idle";
            root.message = root.pamNote || (result === PamResult.MaxTries ? "Too many attempts" : "Wrong password");
            root.wrongCount++;
        }
        onError: err => {
            root.buffer = "";
            root.phase = "idle";
            root.message = root.pamNote || "Authentication error";
            root.wrongCount++;
        }
    }

    // Let the exit animation finish, then hand the screens back
    SequentialAnimation {
        id: release
        PauseAnimation { duration: 1560 }
        ScriptAction { script: lock.locked = false }
        PauseAnimation { duration: 150 }
        ScriptAction { script: Qt.quit() }
    }

    WlSessionLock {
        id: lock
        locked: true

        WlSessionLockSurface {
            id: surface
            color: "black"

            // Keys go to this wrapper; the theme only draws
            Item {
                anchors.fill: parent
                focus: true
                Component.onCompleted: forceActiveFocus()

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.submit();
                    else if (event.key === Qt.Key_Escape) root.clear();
                    else if (event.key === Qt.Key_Backspace) root.backspace();
                    else if (event.text && event.text.charCodeAt(0) >= 32) root.type(event.text);
                    else return;
                    event.accepted = true;
                }

                Loader {
                    anchors.fill: parent
                    Component.onCompleted: setSource(root.theme === "cyberpunk" ? "cyber/CyberSurface.qml" : "LockSurface.qml",
                                                     { ctx: root, screenName: surface.screen?.name ?? "" })
                }
            }
        }
    }

    IpcHandler {
        target: "lock"
        function state(): string { return JSON.stringify({ locked: lock.locked, secure: lock.secure, phase: root.phase }); }
        function testUnlock(): void { if (root.testMode) root.succeed(); }
        function testType(t: string): void { if (root.testMode) root.type(t); }
        function testWrong(): void { if (root.testMode) { root.buffer = ""; root.message = "Wrong password"; root.wrongCount++; } }
    }
}
