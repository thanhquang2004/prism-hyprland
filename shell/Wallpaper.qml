pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Wallpapers: a new image on every screen once a day, picked from Prism's
// own set, never the same image on two screens. Portrait screens use the
// portrait set plus detail-aware portrait cuts of the landscape set. The primary output's image drives the
// accent color (see Theme).
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/Pictures/wallpapers/prism"
    readonly property string cropDir: Quickshell.env("HOME") + "/.cache/prism/wallpaper-portrait"
    readonly property string primaryOutput: "eDP-1"

    property var byOutput: ({})          // output name -> image path (as swww reports it)
    readonly property string primary: byOutput[primaryOutput] ?? Object.values(byOutput)[0] ?? ""

    property var pools: ({ landscape: [], portrait: [] })
    property bool poolsReady: false

    function today() { return Qt.formatDate(new Date(), "yyyy-MM-dd"); }
    function poolFor(screen) { return screen.height > screen.width ? pools.portrait : pools.landscape; }
    // "ghibli-majo002.jpg" -> "ghibli"; used to vary styles across screens
    function sourceOf(path) { return path.split("/").pop().split("-")[0]; }

    // Persisted state: { day, byOutput, recent }
    FileView {
        id: stateFile
        path: Quickshell.env("HOME") + "/.cache/prism/wallpaper.json"
        printErrors: false
        blockLoading: true
        watchChanges: true                // e.g. edited by hand
        onFileChanged: reload()
    }
    function loadState() {
        try { return JSON.parse(stateFile.text()); } catch (e) { return { day: "", byOutput: {}, recent: [] }; }
    }
    function saveState(s) { stateFile.setText(JSON.stringify(s, null, 2)); }

    function pick(screen, taken, recent) {
        const pool = poolFor(screen);
        if (pool.length === 0) return "";
        const takenSources = taken.map(sourceOf);
        // Prefer images not on screen, not shown recently, in a style the other screens aren't using
        const tiers = [
            pool.filter(p => !taken.includes(p) && !recent.includes(p) && !takenSources.includes(sourceOf(p))),
            pool.filter(p => !taken.includes(p) && !recent.includes(p)),
            pool.filter(p => !taken.includes(p)),
            pool,
        ];
        const choices = tiers.find(t => t.length > 0);
        // Pick a style first so big sources don't crowd out small ones
        const sources = [...new Set(choices.map(sourceOf))];
        const src = sources[Math.floor(Math.random() * sources.length)];
        const inSrc = choices.filter(p => sourceOf(p) === src);
        return inSrc[Math.floor(Math.random() * inSrc.length)];
    }

    function apply(output, path) {
        Quickshell.execDetached(["swww", "img", "-o", output, path,
            "--resize", "crop",
            "--transition-type", "grow", "--transition-pos", "0.5,0.5",
            "--transition-duration", "1.2", "--transition-fps", "60"]);
        const m = Object.assign({}, byOutput);
        m[output] = path;
        byOutput = m;
        requery.restart();
    }

    // New image on one screen (by output name), or on every screen when empty
    function next(output) {
        if (!poolsReady) return;
        const s = loadState();
        const current = Object.assign({}, s.byOutput ?? {});
        let recent = s.recent ?? [];
        const targets = Quickshell.screens.filter(sc => !output || sc.name === output);
        // One screen: avoid what every screen shows now. All screens: avoid this round's picks.
        const taken = output ? Quickshell.screens.map(sc => current[sc.name]).filter(Boolean) : [];
        for (const sc of targets) {
            const p = pick(sc, taken, recent);
            if (!p) continue;
            taken.push(p);
            current[sc.name] = p;
            recent = [p].concat(recent.filter(r => r !== p)).slice(0, 40);
            apply(sc.name, p);
        }
        saveState({ day: today(), byOutput: current, recent: recent });
    }

    // New day -> new wallpapers. Same day -> put today's picks back if
    // something else replaced them (e.g. after a reboot).
    function sync() {
        if (!poolsReady) return;
        const s = loadState();
        if (s.day !== today()) { next(""); return; }
        for (const sc of Quickshell.screens) {
            const want = s.byOutput?.[sc.name];
            if (!want) next(sc.name);
            else if (byOutput[sc.name] !== want) apply(sc.name, want);
        }
    }

    // Refresh the portrait cuts first, then list everything
    Process {
        id: crops
        command: ["python", "-I", Quickshell.env("HOME") + "/.config/prism/wallpaper/crop_portrait.py",
            root.dir + "/landscape", root.cropDir, "1080", "1920"]
        onExited: scan.running = true
    }
    Process {
        id: scan
        command: ["find", root.dir + "/landscape", root.dir + "/portrait", root.cropDir, "-type", "f",
            "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", "-o", "-iname", "*.webp", ")"]
        property var acc: ({ landscape: [], portrait: [] })
        stdout: SplitParser {
            onRead: line => scan.acc[line.startsWith(root.dir + "/landscape/") ? "landscape" : "portrait"].push(line)
        }
        onExited: {
            acc.landscape.sort();
            // A cut is redundant when the set already has a portrait version of that image
            const stem = p => p.split("/").pop().replace(/\.[^.]+$/, "");
            const own = acc.portrait.filter(p => !p.startsWith(root.cropDir)).map(stem);
            acc.portrait = acc.portrait.filter(p => !p.startsWith(root.cropDir) || !own.includes(stem(p))).sort();
            root.pools = acc;
            acc = { landscape: [], portrait: [] };
            root.poolsReady = true;
            // Give the first swww query time to land so sync() can compare
            syncSoon.restart();
        }
    }
    Component.onCompleted: crops.running = true

    Timer { id: syncSoon; interval: 1500; onTriggered: root.sync() }

    // Day rollover
    Timer {
        interval: 60000
        running: root.poolsReady
        repeat: true
        onTriggered: if (root.loadState().day !== root.today()) root.next("")
    }

    // ": eDP-1: 1920x1200, scale: 1, currently displaying: image: /path.png"
    Process {
        id: query
        command: ["swww", "query"]
        property var acc: ({})
        stdout: SplitParser {
            onRead: line => {
                const m = line.match(/^:?\s*([^:]+):.*image:\s*(.+)$/);
                if (m) query.acc[m[1].trim()] = m[2].trim();
            }
        }
        onExited: {
            if (JSON.stringify(acc) !== JSON.stringify(root.byOutput)) root.byOutput = acc;
            acc = {};
        }
    }
    Timer { id: requery; interval: 2000; onTriggered: query.running = true }
    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: query.running = true
    }

    IpcHandler {
        target: "wallpaper"
        function next(output: string): void { root.next(output); }
        function rescan(): void { crops.running = true; }
        function state(): string {
            return JSON.stringify({ day: root.loadState().day, byOutput: root.byOutput,
                landscape: root.pools.landscape.length, portrait: root.pools.portrait.length });
        }
    }
}
