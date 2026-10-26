// macOS Tahoe-style dock, bottom-center on every screen. Styled after the MacTahoe GTK theme's
// Dash-to-Dock (github.com/vinceliuice/MacTahoe-gtk-theme): white 10% glass over Hyprland's blur,
// 1px white 20% inner rim, 32px radius, 12px padding, 12px from the screen edge.
//   - pinned apps | running apps that aren't pinned | Trash   (separated by dividers)
//   - icons: MacTahoe icon theme, pre-rendered by ~/.local/bin/dock-icons into ~/.cache/dock-icons;
//     apps MacTahoe doesn't cover get a generated tile in the same style
//   - dot under apps with open windows (brighter = focused), name label above the hovered icon
//   - click: launch (with a bounce until its window appears) / focus / cycle that app's windows
//   - middle-click: open a new instance
//   - auto-hide (Theme.dockAutoHide): touch the bottom edge of the screen to reveal it
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick

Scope {
    id: root

    // Pinned apps: desktop entry id + the window app ids that belong to it
    // (find a window's app id with: hyprctl activewindow).
    readonly property var pinned: [
        { entry: "brave-browser",               appIds: ["brave-browser"] },
        { entry: "com.mitchellh.ghostty",       appIds: ["com.mitchellh.ghostty"] },
        { entry: "org.gnome.Nautilus",          appIds: ["org.gnome.Nautilus"] },
        { entry: "com.onepassword.OnePassword", appIds: ["com.onepassword.OnePassword", "1Password"] },
        { entry: "com.orcaslicer.OrcaSlicer",   appIds: ["orca-slicer", "OrcaSlicer"] },
    ]

    // MacTahoe dash-to-dock metrics
    readonly property int iconSize: Theme.dockIconSize
    readonly property int padding: 12           // $dash_padding
    readonly property int spacing: 10           // between icons
    readonly property int edgeGap: 12           // $dash_edge_offset
    // Concentric corners: dock radius = icon tile radius + gap between tile and dock edge.
    // MacTahoe tiles fill 87.5% of the icon with corners 0.229 of the tile (measured).
    readonly property real tileSize: iconSize * 0.875
    readonly property real tileRadius: tileSize * 0.229
    readonly property int radius: Math.round(tileRadius + padding + (iconSize - tileSize) / 2)
    readonly property int dividerWidth: 21      // 1px line + 10px each side
    readonly property int dockHeight: iconSize + 2 * padding
    readonly property string iconCache: Quickshell.env("HOME") + "/.cache/dock-icons"

    property bool trashFull: false

    // Item kinds: "app" { entry, windows, appId, pinned }, "divider", "trash"
    readonly property var items: {
        // Desktop entries load asynchronously after startup; reading the list here
        // makes this binding re-run once they're available.
        const loadedApps = DesktopEntries.applications.values.length;
        const tops = ToplevelManager.toplevels.values;
        const out = [];
        const claimed = new Set();
        for (const p of pinned) {
            const entry = DesktopEntries.byId(p.entry);
            p.appIds.forEach(a => claimed.add(a));
            if (!entry) continue; // app not installed
            out.push({ kind: "app", key: p.entry, entry: entry, pinned: true, appId: p.appIds[0],
                       windows: tops.filter(t => p.appIds.includes(t.appId)) });
        }
        const extra = new Map();
        for (const t of tops) {
            if (!t.appId || claimed.has(t.appId)) continue;
            if (!extra.has(t.appId)) extra.set(t.appId, []);
            extra.get(t.appId).push(t);
        }
        if (extra.size > 0) out.push({ kind: "divider", key: "divider-running" });
        for (const [appId, wins] of extra)
            out.push({ kind: "app", key: appId, entry: DesktopEntries.heuristicLookup(appId), pinned: false,
                       appId: appId, windows: wins });
        out.push({ kind: "divider", key: "divider-trash" });
        out.push({ kind: "trash", key: "trash", windows: [] });
        return out;
    }

    function iconName(item) {
        if (item.kind === "trash") return trashFull ? "user-trash-full" : "user-trash";
        return item.entry?.icon || item.appId || "";
    }

    function displayName(item) {
        if (item.kind === "trash") return "Trash";
        return item.entry?.name ?? item.appId;
    }

    // Pre-rendered icon from dock-icons (Icon= may be a theme name or an absolute path)
    function tileFor(item) {
        const n = iconName(item);
        if (!n) return "";
        const key = n.startsWith("/") ? n.split("/").pop().replace(/\.[^.]+$/, "") : n;
        return "file://" + iconCache + "/" + key + ".png";
    }

    function activate(item) {
        const wins = item.windows;
        if (wins.length === 0) return false;
        // Already focused: cycle to the next window of the same app
        const cur = wins.findIndex(w => w.activated);
        wins[cur >= 0 ? (cur + 1) % wins.length : 0].activate();
        return true;
    }

    // Trash empty/full icon
    Process {
        id: trashCheck
        command: ["sh", "-c", "find \"$HOME/.local/share/Trash/files\" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: root.trashFull = this.text.trim() !== "" }
    }
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: trashCheck.running = true
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: dock
            required property var modelData
            screen: modelData

            // Full width so touching the bottom edge anywhere reveals the dock
            anchors { bottom: true; left: true; right: true }
            color: "transparent"
            WlrLayershell.namespace: "quickshell-dock"
            WlrLayershell.layer: WlrLayer.Top

            // Dock + room for the name label (and launch bounce) above it
            implicitHeight: root.dockHeight + root.edgeGap + 48

            // Auto-hide: overlay windows instead of reserving space
            exclusionMode: Theme.dockAutoHide ? ExclusionMode.Ignore : ExclusionMode.Normal
            exclusiveZone: Theme.dockAutoHide ? 0 : root.dockHeight + root.edgeGap

            property bool shown: !Theme.dockAutoHide
            Timer {
                id: hideTimer
                interval: 600
                onTriggered: if (Theme.dockAutoHide && !dock.hovered) dock.shown = false
            }
            // Hover is tracked by a HoverHandler on `content`, the parent of every dock item.
            // Qt only reports hover to the item under the pointer and its ancestors, so a handler on a
            // sibling (or a MouseArea) loses hover whenever an icon's MouseArea takes it, and the dock
            // would hide under the pointer.
            readonly property bool hovered: hoverHandler.hovered
            onHoveredChanged: {
                if (hovered) { hideTimer.stop(); shown = true; }
                else hideTimer.restart();
            }

            // Input only where it matters: the bottom-edge strip while hidden, the dock while shown
            mask: Region { item: dock.shown ? dockArea : trigger }

            Item {
                id: content
                anchors.fill: parent      // not transformed: covers the bottom-edge trigger while hidden

                HoverHandler { id: hoverHandler }

                Item {
                    id: trigger
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: 2
                }

                // The dock plus the gap below it (so moving to the screen edge doesn't hide it)
                Item {
                    id: dockArea
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: glass.width
                    height: root.dockHeight + root.edgeGap
                }

                // Everything visible slides down off-screen when hidden
                Item {
                    id: slider
                    anchors.fill: parent
                    transform: Translate {
                        y: dock.shown ? 0 : root.dockHeight + root.edgeGap + 4
                        Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                    }

                    // Glass: white 10% over the compositor blur, 1px white 20% inner rim
                    Rectangle {
                        id: glass
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: root.edgeGap
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: row.implicitWidth + 2 * root.padding
                        height: root.dockHeight
                        radius: root.radius
                        color: Theme.dockBg
                        border.width: 1
                        border.color: Theme.dockBorder
                    }

                    Row {
                        id: row
                        anchors.verticalCenter: glass.verticalCenter
                        anchors.horizontalCenter: glass.horizontalCenter
                        spacing: root.spacing

                        Repeater {
                            model: root.items

                            delegate: Item {
                                id: cell
                                required property var modelData

                                readonly property bool isDivider: modelData.kind === "divider"
                                readonly property bool running: modelData.windows?.length > 0
                                readonly property bool focused: modelData.windows?.some(w => w.activated) ?? false
                                property bool launching: false

                                width: isDivider ? 1 : root.iconSize
                                height: root.iconSize

                                // Divider (spacing on both sides comes from the Row)
                                Rectangle {
                                    visible: cell.isDivider
                                    anchors.centerIn: parent
                                    width: 1
                                    height: root.iconSize * 0.75
                                    color: Theme.dockDivider
                                }

                                Item {
                                    id: icon
                                    visible: !cell.isDivider
                                    anchors.fill: parent
                                    transform: Translate { id: bounce; y: 0 }

                                    Image {
                                        id: tile
                                        anchors.fill: parent
                                        source: cell.isDivider ? "" : root.tileFor(cell.modelData)
                                        sourceSize: Qt.size(256, 256)
                                        smooth: true
                                        mipmap: true
                                        cache: false
                                    }

                                    // Fallback (no pre-rendered icon yet): theme icon or initial on a light tile
                                    Rectangle {
                                        visible: tile.status !== Image.Ready
                                        anchors.fill: parent
                                        anchors.margins: (root.iconSize - root.tileSize) / 2
                                        radius: width * 0.229
                                        gradient: Gradient {
                                            GradientStop { position: 0; color: "#ffffff" }
                                            GradientStop { position: 1; color: "#e2e2e6" }
                                        }

                                        IconImage {
                                            id: themeIcon
                                            anchors.centerIn: parent
                                            implicitSize: parent.width * 0.66
                                            source: {
                                                const n = cell.isDivider ? "" : root.iconName(cell.modelData);
                                                return n ? Quickshell.iconPath(n, true) : "";
                                            }
                                            visible: source != ""
                                        }

                                        Text {
                                            visible: themeIcon.source == ""
                                            anchors.centerIn: parent
                                            text: (root.displayName(cell.modelData) ?? "?").charAt(0).toUpperCase()
                                            color: "#3a3a3a"
                                            font.family: Theme.font
                                            font.pixelSize: parent.height * 0.5
                                            font.bold: true
                                        }
                                    }
                                }

                                // Bounce while launching, until a window shows up (max 8s)
                                SequentialAnimation {
                                    running: cell.launching
                                    loops: Animation.Infinite
                                    NumberAnimation { target: bounce; property: "y"; to: -root.iconSize * 0.4; duration: 260; easing.type: Easing.OutQuad }
                                    NumberAnimation { target: bounce; property: "y"; to: 0; duration: 260; easing.type: Easing.InQuad }
                                    onStopped: bounce.y = 0
                                }
                                Timer { running: cell.launching; interval: 8000; onTriggered: cell.launching = false }
                                onRunningChanged: if (running) launching = false

                                // Running indicator, in the padding under the icon
                                Rectangle {
                                    visible: cell.running
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.bottom
                                    anchors.topMargin: 4
                                    width: 4
                                    height: 4
                                    radius: 2
                                    color: cell.focused ? Theme.dockDotFocused : Theme.dockDot
                                }

                                // Name label above the hovered icon (MacTahoe .dash-label: black 75%, 6px radius,
                                // 6x12 padding, white 85% text, 8px above the dock edge)
                                Rectangle {
                                    visible: iconMouse.containsMouse
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.top
                                    anchors.bottomMargin: root.padding + 8
                                    width: label.implicitWidth + 24
                                    height: label.implicitHeight + 12
                                    radius: Theme.buttonRadius
                                    color: Theme.tooltipBg

                                    Text {
                                        id: label
                                        anchors.centerIn: parent
                                        text: root.displayName(cell.modelData) ?? ""
                                        color: Theme.tooltipFg
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize
                                    }
                                }

                                MouseArea {
                                    id: iconMouse
                                    enabled: !cell.isDivider
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                    onClicked: mouse => {
                                        const item = cell.modelData;
                                        if (item.kind === "trash") {
                                            Quickshell.execDetached(["nautilus", "trash:///"]);
                                            return;
                                        }
                                        const launchNew = mouse.button === Qt.MiddleButton;
                                        if (!launchNew && root.activate(item)) return;
                                        if (item.entry) {
                                            // New windows open on the focused monitor, so focus this dock's first
                                            const mon = Hyprland.monitorFor(dock.screen);
                                            if (mon) Hyprland.dispatch(`hl.dsp.focus({ monitor = '${mon.name}' })`);
                                            item.entry.execute();
                                            if (!cell.running) cell.launching = true;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
