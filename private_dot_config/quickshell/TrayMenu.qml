// Menu for a system tray item, drawn in QML from its DBusMenu (via QsMenuOpener) so it matches the other
// popovers. Quickshell's own item.display() needs QApplication mode and draws unstyled Qt menus.
// Drops down under the clicked icon; closes on a click outside, on picking an entry, or when the item goes away.
// Flat menus only: none of the current tray apps use submenus, so entries with children are just shown disabled.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

// A fixed-size, mostly transparent layer surface (like Popover.qml) instead of an xdg popup sized to the menu:
// the DBusMenu entries load and the column lays out a frame or two after opening, and resizing a mapped
// popup showed a tiny box first. Here the surface never resizes; only the box is drawn and takes input
// (mask), and it fades in once its layout is ready.
PanelWindow {
    id: menu

    required property var bar
    property var trayItem: null
    property real iconX: 0            // left edge of the clicked icon, in screen coordinates
    property bool open: false
    property var closedFor: null      // item whose menu the focus grab just closed, so re-clicking its icon toggles
    property real closedAt: 0

    function toggle(item, icon) {
        if (open && trayItem === item) { open = false; return; }
        if (!open && closedFor === item && Date.now() - closedAt < 300) return;
        trayItem = item;
        iconX = icon.mapToItem(null, 0, 0).x;
        open = true;
    }

    readonly property int edge: 8
    readonly property bool ready: open && entries.length > 0 && col.height > 0

    screen: bar.screen
    visible: open || box.opacity > 0
    anchors { top: true; right: true }
    margins.top: Theme.barHeight - 6
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-popover"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    implicitWidth: 560
    implicitHeight: 900
    color: "transparent"
    mask: Region { item: box }

    onTrayItemChanged: if (!trayItem) open = false

    QsMenuOpener { id: opener; menu: menu.trayItem?.menu ?? null }
    readonly property var entries: opener.children.values

    HyprlandFocusGrab {
        windows: [menu]
        active: menu.open
        onCleared: {
            menu.closedFor = menu.trayItem;
            menu.closedAt = Date.now();
            menu.open = false;
        }
    }

    FontMetrics { id: fm; font.family: Theme.font; font.pixelSize: Theme.fontBody }
    readonly property int pad: 6
    readonly property int markWidth: 22
    readonly property int rowWidth: Math.max(160, ...entries.map(e => fm.advanceWidth(e.text ?? ""))) + markWidth + 14

    Rectangle {
        id: box
        // Left-aligned under the icon, kept inside the window (and so on screen)
        x: Math.max(menu.edge, Math.min(menu.iconX - 10 - (menu.screen.width - menu.width),
                                        menu.width - width - menu.edge))
        y: 8
        opacity: menu.ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: menu.ready ? 120 : 100; easing.type: Easing.OutCubic } }
        focus: true
        Keys.onEscapePressed: menu.open = false
        width: col.width + 2 * menu.pad
        height: col.height + 2 * menu.pad
        radius: Theme.moduleRadius
        color: Qt.rgba(Theme.panelBase.r, Theme.panelBase.g, Theme.panelBase.b, 0.96)
        border.width: 1
        border.color: Theme.popoverBorder

        // Faint inner rim, like the popovers
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius - 1
            color: "transparent"
            border.width: 1
            border.color: Theme.popoverRim
        }

        Column {
            id: col
            x: menu.pad
            y: menu.pad

            Repeater {
                model: opener.children

                delegate: Item {
                    id: row
                    required property var modelData
                    readonly property bool sep: modelData.isSeparator
                    readonly property bool usable: !sep && modelData.enabled && !modelData.hasChildren
                    width: menu.rowWidth
                    height: sep ? 9 : 26

                    Rectangle {
                        visible: row.sep
                        anchors.centerIn: parent
                        width: parent.width - 16
                        height: 1
                        color: Theme.divider
                    }

                    Rectangle {
                        visible: !row.sep
                        anchors.fill: parent
                        radius: Theme.buttonRadius
                        color: !row.usable ? "transparent"
                             : rowMouse.pressed ? Theme.controlPressed
                             : rowMouse.containsMouse ? Theme.hoverFill : "transparent"
                    }

                    // Check / radio mark
                    Text {
                        visible: !row.sep
                        x: 4
                        width: menu.markWidth - 4
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignHCenter
                        text: row.modelData.checkState !== Qt.Checked ? ""
                            : row.modelData.buttonType === QsMenuButtonType.RadioButton ? "•" : "✓"
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: Theme.fontBody
                    }

                    Text {
                        visible: !row.sep
                        x: menu.markWidth
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.text ?? ""
                        color: row.usable ? Theme.fg : Theme.dim
                        font.family: Theme.font
                        font.pixelSize: Theme.fontBody
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        enabled: row.usable
                        hoverEnabled: true
                        onClicked: {
                            row.modelData.triggered();
                            menu.open = false;
                        }
                    }
                }
            }
        }
    }
}
