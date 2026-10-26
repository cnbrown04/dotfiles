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

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            onClicked: mouse => {
                                const item = trayIcon.modelData;
                                if (mouse.button === Qt.MiddleButton) {
                                    item.secondaryActivate();
                                } else if (mouse.button === Qt.RightButton) {
                                    if (item.hasMenu) {
                                        const p = trayIcon.mapToItem(null, 0, trayIcon.height);
                                        item.display(bar, p.x, p.y + 10);
                                    }
                                } else {
                                    item.activate();
                                }
                            }
                        }
                    }
                }

                // Do Not Disturb indicator
                Glyph {
                    anchors.verticalCenter: parent?.verticalCenter
                    visible: ShellState.doNotDisturb
                    code: 0xF0594  // moon
                    size: 15
                    color: Theme.panelFg
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
