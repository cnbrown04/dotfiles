import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.cc
// Imports stay above this header: Quickshell only finds "import qs.…" lines near the top of a file.
// macOS-style Control Center that drops down from the bar's right pill (click the pill; Esc or a click
// outside closes it). One instance per bar; `bar` is that screen's PanelWindow.
//
// It's a small framework; everything it shows lives in cc/:
//   modules/  cards on the home screens (Connectivity, AirPods, Sound, NowPlaying, Power)
//   rows/     one-line toggles that go in a row group card (Wifi, Bluetooth, AirDrop, Tailscale…)
//   pages/    detail pages that slide in (Wifi, Bluetooth, AirDrop, NightShift, Tailscale, ProtonVpn,
//             TrayMenu = any tray app's menu)
//   Cc*.qml   building blocks: CcRow, CcTile, CcRowGroup, CcPage, CcListRow, CcSwitchRow, CcActionRow,
//             CcList, CcSection, CcText, CcDivider, CcPlaceholder, CcToggle, CcSwitch, CcSlider,
//             CcPowerButton, CcSlot (loads a file by name), CcUtil (shared state + helpers)
//
// Home screens: `screens` below. Each screen is a list, top to bottom, of
//   "Name"            -> modules/Name.qml
//   ["A", "B", …]     -> one card holding rows/A.qml, rows/B.qml, …
// With more than one screen, dots appear under them; click a dot, swipe sideways on the touchpad, or scroll
// over the dots to switch. The panel reopens on the first screen.
//
// Adding things:
//   a toggle row   rows/Foo.qml:  CcRow { title; subtitle; code; checked; busy; page: "Foo"; onToggled: … }
//                  then add "Foo" to a row group in `screens`
//   a page         pages/Foo.qml: CcPage { title; checked; onToggled: …; <CcListRow / CcSwitchRow / …> }
//                  open it with page: "Foo" on a row/tile, or cc.push("Foo", { prop: value })
//   a tray app     no code: CcRow { …; page: "TrayMenu"; pageProps: ({ trayId: "vicinae" }) }
//   a module       modules/Foo.qml: CcModule { property var cc; shown: cc.open; … }, add "Foo" to `screens`
// Every loaded file gets `cc` (this object): cc.open, cc.close(), cc.push(page, props), cc.back(), cc.home().
// A row or module with `property bool available: false` drops out of the layout (AirPods while disconnected).
// Open a page from outside:  qs ipc call controlcenter showPage Tailscale
//
// Panel: Popover.qml (blurred by the popover-blur layer rule). Modules drop in staggered, pages slide.

Scope {
    id: center

    required property var bar
    property bool open: false

    // ---- What's on the home screens ------------------------------------------------------------
    readonly property var screens: [
        ["Connectivity", "AirPods", "Sound", "NowPlaying", "Power"],
        [["Tailscale", "ProtonVpn"]],
    ]

    readonly property int panelWidth: 376   // wide enough that no title or label wraps
    readonly property int pad: 12
    readonly property int panelRadius: Theme.panelRadius

    // ---- Navigation ------------------------------------------------------------------------------
    property int screen: 0                  // home screen shown
    property var stack: []                  // open pages (keys), top last; empty = home
    readonly property string top: stack.length > 0 ? stack[stack.length - 1] : ""

    function close() { open = false; }
    function toggle() { open = !open; }
    function showScreen(i) {
        const next = Math.max(0, Math.min(screens.length - 1, i));
        if (next === screen) return;
        screen = next;
        viewChanged(null);
    }
    function back() {
        if (stack.length === 0) return;
        stack = stack.slice(0, -1);
        viewChanged(navHistory.pop() ?? null);
    }
    function home() { stack = []; navHistory = []; viewChanged(null); }
    // Pages are created on first use and kept (going back and forth is instant, lists keep their place)
    function push(page, props) {
        const p = props ?? {};
        const key = page + ":" + JSON.stringify(p);
        let known = false;
        for (let i = 0; i < pageModel.count; i++)
            if (pageModel.get(i).key === key) known = true;
        if (!known) pageModel.append({ key: key, pagePath: "pages/" + page, propsJson: JSON.stringify(p) });
        if (top === key) return;
        navHistory.push(CcUtil.navItem);
        stack = [...stack, key];
        viewChanged(null);
    }

    // ---- Keyboard navigation ---------------------------------------------------------------------
    //   j / k / ↓ / ↑ / Tab   move the selection (focus ring)       g / G   first / last
    //   h / ←                 back on a page; previous screen at home
    //   l / →                 next screen at home; open the selection on a page
    //   Enter                 open the selection's page, or activate it
    //   Space                 toggle the selection (on a page with nothing selected: the header switch)
    //   1-9                   home screen              Esc   back, then close
    //   on a slider, h / l / ← / → adjust it; Enter/Space mute
    // A control takes part by declaring  readonly property bool ccNav: true  plus navActivate() and navToggle()
    // (optional: navAdjust(step), navRadius for the ring). CcRow, CcTile, CcListRow, CcSwitchRow, CcActionRow,
    // CcSlider, CcPowerButton and CcIconButton already do, so new rows and pages get it for free.
    property bool navActive: false          // keys used since opening: selection follows view changes
    property var navHistory: []             // selection under each open page, restored on back

    function currentView() {
        if (stack.length === 0) return screenRepeater.itemAt(screen) ?? null;
        for (let i = 0; i < pageRepeater.count; i++) {
            const slot = pageRepeater.itemAt(i);
            if (slot && slot.key === top) return slot.item;
        }
        return null;
    }

    // Navigable controls in the showing view, in reading order (each container's children by y, then x)
    function navItems() {
        const out = [];
        const walk = it => {
            if (!it || !it.visible || !it.enabled) return;
            if (it.ccNav === true) { out.push(it); return; }
            for (const child of Array.from(it.children).sort((a, b) => (a.y - b.y) || (a.x - b.x)))
                walk(child);
        };
        walk(currentView());
        return out;
    }

    function select(item) {
        CcUtil.navItem = item ?? null;
        win.focusPanel();            // take keys back from a text field (Wi-Fi password)
        if (!item) return;
        // Scroll a list so the selection is in view
        for (let p = item.parent; p; p = p.parent) {
            if (p.contentY === undefined || p.contentHeight === undefined) continue;
            const pos = item.mapToItem(p, 0, 0);
            if (pos.y < 0) p.contentY += pos.y;
            else if (pos.y + item.height > p.height) p.contentY += pos.y + item.height - p.height;
            break;
        }
    }

    function moveSelection(delta) {
        const items = navItems();
        if (items.length === 0) return;
        const i = items.indexOf(CcUtil.navItem);
        select(items[i < 0 ? (delta > 0 ? 0 : items.length - 1) : Math.max(0, Math.min(items.length - 1, i + delta))]);
    }

    // After switching screen/page: restore the selection (going back) or select the first item, if keys are in use
    // The incoming view counts as hidden until its fade-in starts (and tray menus load async), so retry briefly.
    property var navRestore: null
    function viewChanged(restore) {
        CcUtil.navItem = null;
        if (!navActive) return;
        navRestore = restore;
        navRetry.tries = 0;
        navRetry.restart();
    }
    Timer {
        id: navRetry
        property int tries: 0
        interval: 40
        repeat: true
        onTriggered: {
            const items = center.navItems();
            if (items.length === 0 && ++tries < 15) return;
            stop();
            center.select(center.navRestore && items.includes(center.navRestore) ? center.navRestore : items[0] ?? null);
        }
    }

    function handleKey(e) {
        const k = e.key;
        const shift = (e.modifiers & Qt.ShiftModifier) !== 0;
        const onPage = stack.length > 0;
        const items = navItems();
        const cur = items.includes(CcUtil.navItem) ? CcUtil.navItem : null;
        navActive = true;

        if (k === Qt.Key_J || k === Qt.Key_Down || (k === Qt.Key_Tab && !shift)) moveSelection(1);
        else if (k === Qt.Key_K || k === Qt.Key_Up || k === Qt.Key_Backtab) moveSelection(-1);
        else if (k === Qt.Key_G) select(shift ? items[items.length - 1] : items[0]);
        else if (k === Qt.Key_H || k === Qt.Key_Left) {
            if (cur?.navAdjust) cur.navAdjust(-1);
            else if (onPage) back();
            else showScreen(screen - 1);
        } else if (k === Qt.Key_L || k === Qt.Key_Right) {
            if (cur?.navAdjust) cur.navAdjust(1);
            else if (!onPage) showScreen(screen + 1);
            else if (cur) cur.navActivate();
            else moveSelection(1);
        } else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
            if (cur) cur.navActivate(); else moveSelection(1);
        } else if (k === Qt.Key_Space) {
            const view = currentView();
            if (cur) cur.navToggle();
            else if (onPage && view?.showSwitch) view.toggled();
        } else if (k >= Qt.Key_1 && k <= Qt.Key_9 && !onPage) showScreen(k - Qt.Key_1);
        else return false;
        return true;
    }

    // Back to the first home screen once the close animation has finished
    onOpenChanged: {
        if (open) return;
        resetNav.restart();
        navActive = false;
        navHistory = [];
        CcUtil.navItem = null;
    }
    Timer { id: resetNav; interval: 300; onTriggered: if (!center.open) { center.stack = []; center.screen = 0; } }

    IdleInhibitor {
        window: center.bar
        enabled: ShellState.keepAwake
    }

    // Services poll faster while the panel is open
    Binding { when: center.open; target: AirDrop; property: "watching"; value: true }
    Binding { when: center.open; target: Tailscale; property: "watching"; value: true }
    Binding { when: center.open; target: ProtonVpn; property: "watching"; value: true }

    // ---- Window ----------------------------------------------------------------------------------
    Popover {
        id: win

        bar: center.bar
        open: center.open
        align: "right"
        panelWidth: center.panelWidth
        panelHeight: pager.height
        panelRadius: center.panelRadius
        onCloseRequested: center.close()
        keyHandler: e => center.handleKey(e)
        backAction: () => {
            if (center.stack.length === 0) return false;
            center.back();
            return true;
        }

        // Home screens and pages; the panel's height follows whichever is showing
        Item {
            id: pager

            readonly property real pageHeight: {
                for (let i = 0; i < pageRepeater.count; i++) {
                    const slot = pageRepeater.itemAt(i);
                    if (slot && slot.key === center.top) return slot.item?.implicitHeight ?? 0;
                }
                return 0;
            }

            width: parent.width
            height: 2 * center.pad + (center.stack.length === 0 ? home.implicitHeight : pageHeight)
            clip: true
            Behavior on height { NumberAnimation { duration: 420; easing.type: Easing.OutQuint } }

            // ---- Home: screens side by side, dots under them ----
            Item {
                id: home

                readonly property bool isTop: center.stack.length === 0
                // itemAt() doesn't notify, so depend on count to re-evaluate once the screens exist
                readonly property real screenHeight: screenRepeater.count > center.screen
                    ? screenRepeater.itemAt(center.screen)?.implicitHeight ?? 0 : 0

                x: center.pad + (isTop ? 0 : -width * 0.3)
                y: center.pad
                width: center.panelWidth - 2 * center.pad
                implicitHeight: screenHeight + (dots.visible ? dots.height + 12 : 0)
                height: implicitHeight
                opacity: isTop ? 1 : 0
                visible: opacity > 0
                enabled: isTop
                Behavior on x { NumberAnimation { duration: 420; easing.type: Easing.OutQuint } }
                Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

                Repeater {
                    id: screenRepeater
                    model: center.screens

                    delegate: ColumnLayout {
                        required property var modelData
                        required property int index
                        readonly property bool current: index === center.screen

                        // Off-screen ones stay laid out (so heights are known before switching) but fade
                        // out and ignore input
                        x: (index - center.screen) * (home.width + 24)
                        width: home.width
                        spacing: 10
                        opacity: current ? 1 : 0
                        enabled: current
                        Behavior on x { NumberAnimation { duration: 420; easing.type: Easing.OutQuint } }
                        Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

                        Repeater {
                            model: modelData
                            delegate: CcSlot {
                                required property var modelData
                                required property int index
                                // A nested list arrives as an array-like object, not a JS Array
                                readonly property bool group: typeof modelData !== "string"
                                cc: center
                                file: group ? "CcRowGroup" : "modules/" + modelData
                                props: group ? { rows: Array.from(modelData), delay: index * 30 } : { delay: index * 30 }
                            }
                        }
                    }
                }

                // Touchpad: swipe sideways to switch screens (one switch per swipe)
                WheelHandler {
                    orientation: Qt.Horizontal
                    acceptedDevices: PointerDevice.TouchPad
                    property real sum: 0
                    onWheel: e => {
                        if (swipeCooldown.running) return;
                        sum += e.angleDelta.x;
                        if (Math.abs(sum) < 90) return;
                        center.showScreen(center.screen + (sum < 0 ? 1 : -1));
                        sum = 0;
                        swipeCooldown.restart();
                    }
                }
                Timer { id: swipeCooldown; interval: 450 }

                Row {
                    id: dots
                    visible: center.screens.length > 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: home.screenHeight + 12
                    height: 8
                    spacing: 8
                    Behavior on y { NumberAnimation { duration: 420; easing.type: Easing.OutQuint } }

                    Repeater {
                        model: center.screens.length
                        delegate: Rectangle {
                            required property int index
                            readonly property bool current: index === center.screen
                            anchors.verticalCenter: parent.verticalCenter
                            width: current ? 18 : 7
                            height: 7
                            radius: height / 2
                            color: current ? Theme.panelFg : dotMouse.containsMouse ? Theme.controlHover : Theme.control
                            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 150 } }

                            MouseArea {
                                id: dotMouse
                                anchors.fill: parent
                                anchors.margins: -5
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: center.showScreen(index)
                                onWheel: w => center.showScreen(center.screen + (w.angleDelta.y < 0 ? 1 : -1))
                            }
                        }
                    }
                }
            }

            // ---- Pages: slide in from the right; the ones underneath move left ----
            // Keyboard selection ring, drawn over the selected control and following it as things move
            Rectangle {
                id: navRing

                readonly property var target: center.open ? CcUtil.navItem : null
                function sync() {
                    if (!target) return;
                    const p = target.mapToItem(pager, 0, 0);
                    x = p.x - 3;
                    y = p.y - 3;
                    width = target.width + 6;
                    height = target.height + 6;
                }

                z: 10
                visible: target !== null && target.visible
                radius: (target?.navRadius ?? Theme.rowRadius) + 3
                color: "transparent"
                border.width: 2
                border.color: Qt.rgba(1, 1, 1, 0.6)
                onTargetChanged: sync()

                FrameAnimation { running: navRing.visible; onTriggered: navRing.sync() }
            }

            ListModel { id: pageModel }

            Repeater {
                id: pageRepeater
                model: pageModel

                delegate: CcSlot {
                    id: slot

                    required property string key
                    required property string pagePath
                    required property string propsJson
                    readonly property int depth: center.stack.indexOf(key)
                    readonly property bool isTop: depth >= 0 && depth === center.stack.length - 1

                    cc: center
                    file: pagePath
                    props: JSON.parse(propsJson)

                    x: center.pad + (isTop ? 0 : depth >= 0 ? -width * 0.3 : width)
                    y: center.pad
                    width: center.panelWidth - 2 * center.pad
                    height: item ? item.implicitHeight : 0
                    opacity: isTop ? 1 : 0
                    visible: opacity > 0
                    enabled: isTop
                    Behavior on x { NumberAnimation { duration: 420; easing.type: Easing.OutQuint } }
                    Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

                    Binding {
                        when: slot.item !== null
                        target: slot.item
                        property: "active"
                        value: slot.isTop && center.open
                    }
                }
            }
        }
    }
}
