// Workspace overview, dropped down from the bar's workspace pill (click it; Esc or a click outside closes it).
// Every workspace is a miniature of its monitor (same aspect ratio) with live thumbnails of its windows where
// they actually sit, grouped by monitor.
//   - click a workspace to go there, click a window to focus it
//   - drag a window onto another workspace to move it there (it tilts as you fling it; the target lights up);
//     drop it on "+" to give it a fresh workspace
//   - the extra "+" card opens a new empty workspace on that monitor
// Thumbnails are ScreencopyViews of each toplevel (hyprland-toplevel-export), only live while open.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Scope {
    id: ov

    required property var bar
    property bool open: false

    function close() { open = false; }
    function toggle() { open = !open; }

    readonly property int pad: 14
    readonly property int gap: 12
    readonly property string iconCache: Quickshell.env("HOME") + "/.cache/dock-icons"

    // Window positions/sizes come from Hyprland's IPC objects, which only update on refresh
    function refresh() {
        Hyprland.refreshMonitors();
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
    }
    onOpenChanged: if (open) refresh()
    Timer { id: refreshSoon; interval: 200; onTriggered: ov.refresh() }

    function dispatch(cmd) {
        Hyprland.dispatch(cmd);
        refreshSoon.restart();
    }

    readonly property var monitors: Hyprland.monitors.values.slice().sort((a, b) => a.x - b.x)
    readonly property var workspaces: Hyprland.workspaces.values.filter(w => w.id > 0)
    readonly property int nextFreeId: workspaces.reduce((m, w) => Math.max(m, w.id), 0) + 1

    function addr(toplevel) {
        const a = toplevel.address;
        return a.startsWith("0x") ? a : "0x" + a;
    }

    function workspacesOn(mon) {
        return workspaces.filter(w => w.monitor === mon).sort((a, b) => a.id - b.id);
    }
    function aspect(mon) { return mon.height > 0 ? mon.width / mon.height : 16 / 9; }

    // Card height: as big as 132px, shrunk so the widest monitor row fits on this screen
    readonly property real cardHeight: {
        const maxRow = (bar.screen?.width ?? 1920) - 120 - 2 * pad;
        let h = 132;
        for (const m of monitors) {
            const n = workspacesOn(m).length + 1;   // + the "new" card
            h = Math.min(h, (maxRow - (n - 1) * gap) / (n * aspect(m)));
        }
        return Math.max(60, h);
    }

    function iconFor(appId) {
        const entry = DesktopEntries.heuristicLookup(appId);
        const n = entry?.icon || appId || "";
        if (!n) return "";
        if (n.startsWith("/")) return "file://" + iconCache + "/" + n.split("/").pop().replace(/\.[^.]+$/, "") + ".png";
        return "file://" + iconCache + "/" + n + ".png";
    }

    // One workspace (or the "+" card when ws is null) as a miniature of its monitor
    component WorkspaceCard: Item {
        id: card

        property var ws: null
        required property var mon
        property int delay: 0
        readonly property bool isNew: ws === null
        readonly property bool active: !isNew && mon.activeWorkspace === ws
        readonly property real s: width / (mon.width / mon.scale)   // logical px -> card px
        readonly property bool lit: drop.containsDrag || (hover.hovered && !ov.dragging)

        width: Math.round(ov.cardHeight * ov.aspect(mon))
        height: Math.round(ov.cardHeight)

        // Entrance: drop in after `delay`, like the Control Center modules
        opacity: 0
        transform: Translate { id: drift; y: -12 }
        states: State {
            name: "shown"
            when: ov.open
            PropertyChanges { target: card; opacity: 1 }
            PropertyChanges { target: drift; y: 0 }
            PropertyChanges { target: body; scale: 1 }
        }
        transitions: [
            Transition {
                to: "shown"
                SequentialAnimation {
                    PauseAnimation { duration: card.delay }
                    ParallelAnimation {
                        NumberAnimation { target: card; property: "opacity"; duration: 260; easing.type: Easing.OutCubic }
                        NumberAnimation { target: drift; property: "y"; duration: 480; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                        NumberAnimation { target: body; property: "scale"; duration: 480; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
                    }
                }
            },
            Transition {
                from: "shown"
                NumberAnimation { targets: [card, drift, body]; properties: "opacity,y,scale"; duration: 140; easing.type: Easing.InCubic }
            }
        ]

        HoverHandler { id: hover }

        DropArea {
            id: drop
            anchors.fill: parent
            keys: ["window"]
            readonly property var targetCard: card
        }

        Item {
            id: body
            anchors.fill: parent
            scale: 0.9
            // Lifts under the pointer / a dragged window (scale is also driven by the entrance state)
            transform: Scale {
                origin.x: body.width / 2
                origin.y: body.height / 2
                xScale: card.lit ? (drop.containsDrag ? 1.06 : 1.03) : 1
                yScale: xScale
                Behavior on xScale { SpringAnimation { spring: 4; damping: 0.3; epsilon: 0.001 } }
            }

            ClippingRectangle {
                id: screenRect
                anchors.fill: parent
                radius: Theme.cardRadius
                color: drop.containsDrag ? Theme.cardDrop : card.lit ? Theme.cardHover : Theme.cardBg
                Behavior on color { ColorAnimation { duration: 180 } }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (card.isNew) {
                            ov.dispatch(`hl.dsp.focus({ monitor = "${card.mon.name}" })`);
                            ov.dispatch(`hl.dsp.focus({ workspace = ${ov.nextFreeId} })`);
                        } else {
                            ov.dispatch(`hl.dsp.focus({ workspace = ${card.ws.id} })`);
                        }
                        ov.close();
                    }
                }

                // "+" for a new workspace
                Glyph {
                    anchors.centerIn: parent
                    visible: card.isNew
                    code: 0xF0415  // plus
                    size: 26
                    color: card.lit ? Theme.panelFg : Theme.dim
                    rotation: card.lit ? 90 : 0
                    Behavior on rotation { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Windows, where they sit on the monitor
                Repeater {
                    model: card.isNew ? [] : card.ws.toplevels.values

                    delegate: Item {
                        id: slot

                        required property var modelData
                        readonly property var ipc: modelData.lastIpcObject
                        readonly property bool placed: ipc?.at !== undefined
                        property bool dropped: false

                        visible: placed && !(ipc?.hidden ?? false)
                        x: placed ? (ipc.at[0] - card.mon.x) * card.s : 0
                        y: placed ? (ipc.at[1] - card.mon.y) * card.s : 0
                        width: placed ? Math.max(12, ipc.size[0] * card.s) : 0
                        height: placed ? Math.max(12, ipc.size[1] * card.s) : 0
                        z: ipc?.floating ? 1 : 0

                        MouseArea {
                            id: grab
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                            drag.target: thumb
                            drag.threshold: 6

                            property real lastX: 0
                            onPressed: lastX = mouseX
                            onPositionChanged: {
                                if (!drag.active) return;
                                // Tilt with horizontal speed, springs back upright
                                thumb.tilt = Math.max(-14, Math.min(14, (mouseX - lastX) * 1.2));
                                lastX = mouseX;
                            }
                            onClicked: {
                                ov.dispatch(`hl.dsp.focus({ window = "address:${ov.addr(slot.modelData)}" })`);
                                ov.close();
                            }
                            onReleased: {
                                thumb.tilt = 0;
                                const target = thumb.Drag.target?.targetCard;
                                if (!target || target === card) return;
                                slot.dropped = true;
                                const id = target.isNew ? ov.nextFreeId : target.ws.id;
                                ov.dispatch(`hl.dsp.window.move({ workspace = ${id}, follow = false, window = "address:${ov.addr(slot.modelData)}" })`);
                                // A new workspace is created on the window's monitor; put it where it was dropped
                                if (target.isNew && target.mon !== card.mon)
                                    ov.dispatch(`hl.dsp.workspace.move({ workspace = ${id}, monitor = "${target.mon.name}" })`);
                            }
                        }

                        Item {
                            id: thumb

                            property real tilt: 0
                            width: slot.width
                            height: slot.height
                            anchors.centerIn: slot
                            rotation: tilt
                            opacity: slot.dropped ? 0 : 1
                            Behavior on rotation { SpringAnimation { spring: 3; damping: 0.25; epsilon: 0.05 } }
                            Behavior on opacity { NumberAnimation { duration: 150 } }

                            Drag.active: grab.drag.active
                            Drag.keys: ["window"]
                            Drag.hotSpot.x: width / 2
                            Drag.hotSpot.y: height / 2

                            states: State {
                                when: grab.drag.active
                                ParentChange { target: thumb; parent: dragLayer }
                                AnchorChanges { target: thumb; anchors.horizontalCenter: undefined; anchors.verticalCenter: undefined }
                                PropertyChanges { target: thumb; scale: 1.08; z: 100 }
                            }
                            transitions: Transition {
                                ParentAnimation {
                                    AnchorAnimation { duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                                }
                                NumberAnimation { property: "scale"; duration: 250; easing.type: Easing.OutCubic }
                            }
                            Behavior on scale { NumberAnimation { duration: 200 } }

                            ClippingRectangle {
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: 5
                                color: Theme.thumbBg

                                ScreencopyView {
                                    id: shot
                                    anchors.fill: parent
                                    captureSource: ov.open ? slot.modelData.wayland : null
                                    live: true
                                }
                            }

                            // Outline: brighter on hover / while dragging
                            Rectangle {
                                anchors.fill: parent
                                radius: 6
                                color: "transparent"
                                border.width: 1
                                border.color: grab.containsMouse || grab.drag.active ? Theme.thumbOutlineHover : Theme.thumbOutline
                                Behavior on border.color { ColorAnimation { duration: 150 } }
                            }

                            // App icon badge, bottom-center like macOS Exposé
                            Image {
                                readonly property int iconSize: Math.max(16, Math.min(34, Math.min(thumb.width, thumb.height) * 0.42))
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: shot.hasContent ? -iconSize * 0.25 : (thumb.height - iconSize) / 2
                                width: iconSize
                                height: iconSize
                                source: ov.iconFor(slot.ipc?.class ?? slot.modelData.wayland?.appId ?? "")
                                sourceSize.width: 64
                                sourceSize.height: 64
                                smooth: true
                                mipmap: true
                            }
                        }
                    }
                }
            }

            // Active workspace ring + number chip (outside the clip so they stay crisp)
            Rectangle {
                anchors.fill: parent
                radius: Theme.cardRadius
                color: "transparent"
                border.width: card.active ? 2 : 1
                border.color: card.active ? Theme.accent : drop.containsDrag ? Theme.cardDropBorder : Theme.divider
                Behavior on border.color { ColorAnimation { duration: 180 } }
            }

            Rectangle {
                visible: !card.isNew
                x: 6
                y: 6
                implicitWidth: Math.max(20, chipText.implicitWidth + 12)
                implicitHeight: 20
                radius: height / 2
                color: card.active ? Theme.accent : Theme.chipBg

                Text {
                    id: chipText
                    anchors.centerIn: parent
                    text: card.ws?.id ?? ""
                    color: card.active ? Theme.accentFg : Theme.panelFg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontCaption
                    font.weight: Font.Bold
                }
            }
        }
    }

    readonly property bool dragging: dragLayer.children.length > 0

    Popover {
        id: pop
        bar: ov.bar
        open: ov.open
        align: "left"
        panelWidth: Math.max(260, column.implicitWidth + 2 * ov.pad)
        panelHeight: column.implicitHeight + 2 * ov.pad
        onCloseRequested: ov.close()

        ColumnLayout {
            id: column
            x: ov.pad
            y: ov.pad
            spacing: 10

            Repeater {
                model: ov.monitors

                delegate: ColumnLayout {
                    id: monRow
                    required property var modelData
                    required property int index
                    readonly property var spaces: ov.workspacesOn(modelData)
                    spacing: 6

                    Text {
                        Layout.leftMargin: 4
                        text: (monRow.modelData.lastIpcObject?.model || monRow.modelData.description || "")
                              + "  ·  " + monRow.modelData.name
                        color: Theme.altFg
                        font.family: Theme.font
                        font.pixelSize: Theme.fontCaption
                        font.weight: Font.Bold
                        opacity: ov.open ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                    }

                    Row {
                        spacing: ov.gap

                        Repeater {
                            model: monRow.spaces
                            delegate: WorkspaceCard {
                                required property var modelData
                                required property int index
                                ws: modelData
                                mon: monRow.modelData
                                delay: (monRow.index * 3 + index) * 45
                            }
                        }
                        WorkspaceCard {
                            mon: monRow.modelData
                            delay: (monRow.index * 3 + monRow.spaces.length) * 45
                        }
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Click to switch  ·  drag windows between spaces"
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: Theme.fontCaption
                opacity: ov.open ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 400 } }
            }
        }

        // Dragged thumbnails are reparented here so they float above every card
        Item {
            id: dragLayer
            anchors.fill: parent
        }
    }
}
