// Notification daemon (org.freedesktop.Notifications) + banners, top-right of the focused monitor.
// Banners follow the MacTahoe GTK theme's GNOME Shell .notification-banner (dark):
// 18px radius, #242424 at Theme.panelOpacity, 1px black 75% border, soft shadow, header with app icon + name,
// bold title, dimmer body, full-width 36px buttons on a 5% fill.
// Replaces dunst/mako. Test with: notify-send -A ok=OK "Hello" "World"
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

Scope {
    NotificationServer {
        id: server
        keepOnReload: false
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true

        // Do Not Disturb (Control Center) drops everything but critical notifications
        onNotification: notification => {
            if (!ShellState.doNotDisturb || notification.urgency === NotificationUrgency.Critical)
                notification.tracked = true;
        }
    }

    PanelWindow {
        id: popups

        readonly property var focusedScreen: {
            const name = Hyprland.focusedMonitor?.name;
            return Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0];
        }

        screen: focusedScreen
        visible: server.trackedNotifications.values.length > 0
        anchors {
            top: true
            right: true
        }
        margins {
            top: Theme.barHeight
            right: 4
        }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-notifications"
        implicitWidth: 440 + 2 * 12
        implicitHeight: column.implicitHeight + 2 * 12
        color: "transparent"

        ColumnLayout {
            id: column
            x: 12
            y: 12
            width: 440
            spacing: 12

            Repeater {
                model: server.trackedNotifications

                delegate: Item {
                    id: banner
                    required property var modelData
                    readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
                    // Many apps (e.g. Ghostty, used by Claude Code) send no app name/icon, only a desktop-entry hint
                    readonly property var entry: modelData.desktopEntry
                        ? DesktopEntries.byId(modelData.desktopEntry)
                        : DesktopEntries.heuristicLookup(modelData.appName)
                    readonly property string appName: modelData.appName || entry?.name || ""
                    readonly property string appIconSource: {
                        const n = modelData.appIcon || entry?.icon || "";
                        if (!n) return "";
                        return n.startsWith("/") || n.startsWith("file:") ? n : Quickshell.iconPath(n, true);
                    }
                    // "default" is the click-the-banner action (empty label by spec), not a button
                    readonly property var defaultAction: modelData.actions.find(a => a.identifier === "default") ?? null
                    readonly property var buttons: modelData.actions.filter(a => a.identifier !== "default" && a.text !== "")
                    // Only real pictures get the big image; an icon name passed as image-path would just
                    // duplicate the header icon
                    readonly property bool hasPicture: {
                        const i = modelData.image;
                        return i !== "" && !i.startsWith("image://icon/");
                    }

                    Layout.fillWidth: true
                    implicitHeight: card.implicitHeight

                    // Auto-dismiss after 6s unless critical. Hovering pauses the timer.
                    Timer {
                        interval: 6000
                        running: !banner.critical && !bannerHover.hovered
                        onTriggered: banner.modelData.expire()
                    }

                    // box-shadow: 0 3px 5px rgba(black, 0.15)
                    Rectangle {
                        anchors.fill: card
                        anchors.topMargin: 3
                        anchors.bottomMargin: -3
                        radius: Theme.notificationRadius
                        color: Theme.shadow
                    }

                    Rectangle {
                        id: card
                        width: parent.width
                        implicitHeight: content.implicitHeight + 2 * 12
                        radius: Theme.notificationRadius
                        color: Theme.popoverBg
                        border.width: 1
                        border.color: banner.critical ? Theme.urgentBorder : Theme.popoverBorder

                        HoverHandler { id: bannerHover }

                        // Click anywhere (outside buttons): run the default action if any (e.g. focus the app), then dismiss
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                const n = banner.modelData;
                                if (banner.defaultAction) banner.defaultAction.invoke();   // e.g. focus the Ghostty window
                                if (n.tracked) n.dismiss();
                            }
                        }

                        ColumnLayout {
                            id: content
                            x: 12
                            y: 12
                            width: parent.width - 24
                            spacing: 8

                            // Header: app icon + app name
                            RowLayout {
                                spacing: 6
                                visible: banner.appName !== "" || banner.appIconSource !== ""

                                IconImage {
                                    visible: banner.appIconSource !== ""
                                    implicitSize: 16
                                    source: banner.appIconSource
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: banner.appName
                                    color: Theme.altFg
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSizeSmall
                                    elide: Text.ElideRight
                                }
                            }

                            RowLayout {
                                spacing: 12

                                Image {
                                    visible: banner.hasPicture
                                    source: banner.modelData.image
                                    Layout.preferredWidth: 48
                                    Layout.preferredHeight: 48
                                    Layout.alignment: Qt.AlignTop
                                    fillMode: Image.PreserveAspectCrop
                                    sourceSize.width: 96
                                    sourceSize.height: 96
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        Layout.fillWidth: true
                                        text: banner.modelData.summary
                                        color: Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize
                                        font.weight: Font.Bold
                                        wrapMode: Text.Wrap
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: banner.modelData.body
                                        visible: text !== ""
                                        color: Theme.altFg
                                        textFormat: Text.StyledText
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 6
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            // Actions: full-width buttons (.notification-button)
                            RowLayout {
                                visible: banner.buttons.length > 0
                                Layout.fillWidth: true
                                Layout.topMargin: 2
                                spacing: 6

                                Repeater {
                                    model: banner.buttons

                                    delegate: Rectangle {
                                        id: actionButton
                                        required property var modelData
                                        Layout.fillWidth: true
                                        implicitHeight: Theme.buttonHeight
                                        radius: Theme.buttonRadius
                                        color: actionMouse.pressed ? Theme.track
                                             : actionMouse.containsMouse ? Theme.divider : Theme.fill

                                        Text {
                                            anchors.centerIn: parent
                                            text: actionButton.modelData.text
                                            color: actionMouse.containsMouse ? Theme.fg : Theme.altFg
                                            font.family: Theme.font
                                            font.pixelSize: Theme.fontSize
                                            font.weight: Font.Medium
                                        }

                                        MouseArea {
                                            id: actionMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: actionButton.modelData.invoke()
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
