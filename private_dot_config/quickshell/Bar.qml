// Top bar, styled after the MacTahoe GTK theme's GNOME Shell panel (transparent variant):
// no background, items are pill buttons that light up on hover.
//   left:   workspace numbers (active one in a highlighted pill); click for the workspace overview
//           (WorkspaceOverview.qml), scroll to switch workspaces on this monitor
//   center: clock; click for the calendar (CalendarMenu.qml)
//   right:  system tray + volume; click for the Control Center (ControlCenter.qml),
//           scroll to change the volume, middle-click to mute
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick

Scope {
    id: root

    // Tray icons to hide, matched by StatusNotifierItem id prefix.
    // List current ids with: busctl --user get-property org.kde.StatusNotifierWatcher
    //   /StatusNotifierWatcher org.kde.StatusNotifierWatcher RegisteredStatusNotifierItems
    readonly property var hiddenTrayIds: ["1Password"]
    // Tray items whose left-click Activate does something useful; every other item opens its menu on left-click
    // (LibrePods, Proton VPN and Electron apps ignore Activate)
    readonly property var activateTrayIds: ["vicinae"]

    // Keep the default sink bound so its volume/mute properties are live.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Toggle a menu on the focused monitor (e.g. for keybinds):
    //   qs ipc call controlcenter toggle  |  qs ipc call calendar toggle  |  qs ipc call workspaces toggle
    function focusedBar() {
        const name = Hyprland.focusedMonitor?.name;
        return bars.instances.find(b => b.modelData.name === name) ?? bars.instances[0];
    }
    IpcHandler {
        target: "controlcenter"
        function toggle(): void { root.focusedBar()?.controlCenter.toggle(); }
        // Open it on a page: qs ipc call controlcenter showPage Tailscale  (a file in cc/pages/)
        function showPage(page: string): void {
            const cc = root.focusedBar()?.controlCenter;
            if (!cc) return;
            cc.open = true;
            cc.push(page);
        }
    }
    IpcHandler {
        target: "calendar"
        function toggle(): void { root.focusedBar()?.calendar.toggle(); }
    }
    IpcHandler {
        target: "workspaces"
        function toggle(): void { root.focusedBar()?.overview.toggle(); }
    }

    Variants {
        id: bars
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData
            readonly property alias controlCenter: controlCenter
            readonly property alias calendar: calendar
            readonly property alias overview: overview
            readonly property var hyprMonitor: Hyprland.monitorFor(modelData)

            screen: modelData
            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: Theme.barHeight
            color: "transparent"

            // Soft scrim so white text stays readable over bright wallpapers (not in MacTahoe)
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0; color: Theme.barScrimTop }
                    GradientStop { position: 1; color: "transparent" }
                }
            }

            WorkspaceOverview {
                id: overview
                bar: bar
            }

            // Left: workspace numbers; click for the overview, scroll to switch
            PanelPill {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                hpadding: 14
                active: overview.open
                onClicked: overview.toggle()
                onWheel: wheel => Hyprland.dispatch(`hl.dsp.focus({ workspace = "${wheel.angleDelta.y > 0 ? "m-1" : "m+1"}" })`)

                Repeater {
                    model: Hyprland.workspaces

                    delegate: Rectangle {
                        id: dot
                        required property var modelData
                        visible: modelData.id > 0 && modelData.monitor === bar.hyprMonitor
                        anchors.verticalCenter: parent?.verticalCenter
                        width: modelData.active ? 30 : 18
                        height: 22
                        radius: height / 2
                        color: modelData.active ? Theme.panelActive : "transparent"
                        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Text {
                            anchors.centerIn: parent
                            text: dot.modelData.id
                            color: Theme.panelFg
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: dot.modelData.active ? Font.Bold : Font.Medium
                            opacity: dot.modelData.active || dot.modelData.urgent ? 1 : 0.5
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }

                    }
                }
            }

            CalendarMenu {
                id: calendar
                bar: bar
            }

            // Center: clock, click for the calendar
            PanelPill {
                anchors.centerIn: parent
                hpadding: 18
                active: calendar.open
                onClicked: calendar.toggle()

                Text {
                    text: Qt.formatDateTime(clock.date, "ddd MMM d   HH:mm")
                    color: Theme.panelFg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    font.weight: Font.Medium
                    style: Text.Raised
                    styleColor: Theme.panelTextShadow
                }
            }

            TrayMenu { id: trayMenu; bar: bar }

            ControlCenter {
                id: controlCenter
                bar: bar
            }

            // Right: tray + volume, opens the Control Center
            PanelPill {
                id: status
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                hpadding: 14

                readonly property var sink: Pipewire.defaultAudioSink
                readonly property bool muted: sink?.audio?.muted ?? false
                readonly property real volume: sink?.audio?.volume ?? 0

                active: controlCenter.open
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                onClicked: mouse => {
                    if (mouse.button === Qt.MiddleButton) {
                        if (sink) sink.audio.muted = !sink.audio.muted;
                    } else {
                        controlCenter.toggle();
                    }
                }
                onWheel: wheel => {
                    if (!sink) return;
                    const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                    ShellState.setVolume(sink, sink.audio.volume + step);
                }

                // System tray (udiskie, nm-applet, etc. if they expose a StatusNotifierItem)
                Repeater {
                    model: SystemTray.items

                    delegate: IconImage {
                        id: trayIcon
                        required property var modelData
                        visible: !root.hiddenTrayIds.some(prefix => (modelData.id ?? "").startsWith(prefix))
                        anchors.verticalCenter: parent?.verticalCenter
                        implicitSize: 16
                        source: modelData.icon

                        // App name for the hover label: Title, else the tooltip title, else the id
                        readonly property string appName: modelData.title || modelData.tooltipTitle || modelData.id || ""

                        function showMenu() { trayMenu.toggle(trayIcon.modelData, trayIcon); }

                        MouseArea {
                            id: trayMouse
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            onClicked: mouse => {
                                const item = trayIcon.modelData;
                                hoverDelay.stop();
                                const wantsMenu = item.hasMenu && (mouse.button === Qt.RightButton
                                    || (mouse.button === Qt.LeftButton && !root.activateTrayIds.includes(item.id)));
                                // Opening a menu: the label stays until the menu is laid out, then the two
                                // crossfade (see tipWanted). Anything else: drop the label now.
                                if (!wantsMenu) trayIcon.tipShown = false;
                                if (wantsMenu) trayIcon.showMenu();
                                else if (mouse.button === Qt.MiddleButton) item.secondaryActivate();
                                else if (mouse.button === Qt.LeftButton) item.activate();
                            }
                            onContainsMouseChanged: {
                                trayIcon.tipShown = false;
                                // No labels while a tray menu is open (macOS behaviour)
                                if (containsMouse && !trayMenu.open) hoverDelay.restart(); else hoverDelay.stop();
                            }
                        }

                        // Short delay so sweeping across the tray doesn't flash labels
                        property bool tipShown: false
                        readonly property bool tipWanted: tipShown && appName !== "" && !trayMenu.ready
                        // Once a menu has taken over, keep the label away until the pointer leaves and comes back
                        Connections {
                            target: trayMenu
                            function onReadyChanged() { if (trayMenu.ready) trayIcon.tipShown = false; }
                        }
                        Timer { id: hoverDelay; interval: 350; onTriggered: trayIcon.tipShown = true }

                        // Name label under the hovered icon, same look as the dock's (.dash-label)
                        PopupWindow {
                            visible: trayIcon.tipWanted || tip.opacity > 0
                            anchor.item: trayIcon
                            anchor.edges: Edges.Bottom
                            anchor.gravity: Edges.Bottom
                            anchor.rect.x: trayIcon.width / 2
                            anchor.rect.y: 14
                            implicitWidth: tip.width
                            implicitHeight: tip.height
                            color: "transparent"

                            Rectangle {
                                id: tip
                                width: tipText.implicitWidth + 24
                                height: tipText.implicitHeight + 12
                                radius: Theme.buttonRadius
                                color: Theme.tooltipBg
                                opacity: trayIcon.tipWanted ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                                Text {
                                    id: tipText
                                    anchors.centerIn: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    text: trayIcon.appName
                                        + (trayIcon.modelData.tooltipDescription ? "\n" + trayIcon.modelData.tooltipDescription : "")
                                    color: Theme.tooltipFg
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize
                                }
                            }
                        }
                    }
                }

                // AirDrop indicator (receiver on)
                Glyph {
                    anchors.verticalCenter: parent?.verticalCenter
                    visible: AirDrop.on
                    code: 0xF0003  // access-point
                    size: 15
                    color: Theme.panelFg
                }

                // Volume icon (MacTahoe symbolic icons)
                IconImage {
                    anchors.verticalCenter: parent?.verticalCenter
                    implicitSize: 16
                    source: {
                        const v = status.volume;
                        const name = !status.sink ? "audio-volume-muted-symbolic"
                            : status.muted || v <= 0 ? "audio-volume-muted-symbolic"
                            : v < 0.34 ? "audio-volume-low-symbolic"
                            : v < 0.67 ? "audio-volume-medium-symbolic"
                            : "audio-volume-high-symbolic";
                        return Quickshell.iconPath(name, true);
                    }
                }
            }
        }
    }
}
