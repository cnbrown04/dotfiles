// macOS-style Control Center that drops down from the bar's right pill (click the pill; Esc or a click
// outside closes it). One instance per bar; `bar` is that screen's PanelWindow.
//   - Wi-Fi / Bluetooth / Ethernet: click the circle to toggle, the row to open its list page
//     (Wi-Fi: join networks, asks for a password if needed; Bluetooth: connect paired devices)
//   - AirDrop (AirDrop.qml): circle starts/stops the receiver, the row opens a page with Send File…
//   - AirPods (AirPods.qml, shown while connected): batteries, listening mode, Conversation Awareness
//   - Do Not Disturb (hides non-critical banners), Keep Awake (Wayland idle inhibitor -> hypridle waits)
//   - Sound + microphone sliders (click the icon to mute), Now Playing (MPRIS), power buttons
//     (Log Out / Restart / Shut Down need a second click)
// Panel: Popover.qml (same look as the notification banners, blurred by the popover-blur layer rule).
// Animations: panel springs open from the pill, modules drop in staggered, pages slide.
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Scope {
    id: cc

    required property var bar
    property bool open: false
    property string page: "main"      // "main" | "wifi" | "bluetooth" | "airdrop"

    readonly property int panelWidth: 344
    readonly property int pad: 12
    readonly property int panelRadius: Theme.panelRadius

    function close() { open = false; }
    function toggle() { open = !open; }

    // Audio
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    // Network
    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wiredDevice: Networking.devices.values.find(d => d.type === DeviceType.Wired) ?? null
    readonly property var wifiNetwork: wifiDevice?.networks.values.find(n => n.connected) ?? null

    // Bluetooth
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool btOn: adapter?.enabled ?? false
    readonly property var btConnected: adapter?.devices.values.filter(d => d.connected) ?? []

    // Media: the playing player, else the first one
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    PwObjectTracker { objects: [cc.sink, cc.source] }

    IdleInhibitor {
        window: cc.bar
        enabled: ShellState.keepAwake
    }

    // Scan for networks only while the Wi-Fi page is showing
    Binding {
        when: cc.wifiDevice !== null
        target: cc.wifiDevice
        property: "scannerEnabled"
        value: cc.open && cc.page === "wifi"
    }

    // Poll the AirDrop daemon faster while the panel is open
    Binding {
        when: cc.open
        target: AirDrop
        property: "watching"
        value: true
    }

    // MPRIS doesn't push position updates; poll while playing
    Timer {
        running: cc.open && (cc.player?.isPlaying ?? false)
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: cc.player.positionChanged()
    }

    // Back to the main page once the close animation has finished
    onOpenChanged: if (!open) resetPage.restart()
    Timer { id: resetPage; interval: 300; onTriggered: if (!cc.open) cc.page = "main" }

    function wifiGlyph(strength) {
        const s = strength > 1 ? strength / 100 : strength;
        return s > 0.75 ? 0xF0928 : s > 0.5 ? 0xF0925 : s > 0.25 ? 0xF0922 : 0xF091F;
    }

    function btGlyph(icon) {
        if (/headset|headphone/.test(icon)) return 0xF02CB;
        if (/audio|speaker/.test(icon)) return 0xF04C3;
        if (/keyboard/.test(icon)) return 0xF030C;
        if (/mouse|tablet/.test(icon)) return 0xF037D;
        if (/gaming|joystick/.test(icon)) return 0xF0296;
        if (/phone/.test(icon)) return 0xF011C;
        if (/computer/.test(icon)) return 0xF0322;
        return 0xF00AF;
    }

    function percent(v) { return Math.round(v <= 1 ? v * 100 : v) + "%"; }

    // ---- Small building blocks ---------------------------------------------------------------

    // Row in the connectivity module: toggle circle + title/subtitle, opens a list page on click
    component ConnRow: Item {
        id: row

        property int code
        property string title
        property string subtitle
        property bool checked
        property bool toggleable: true
        property bool hasPage: false
        signal toggled()
        signal opened()

        Layout.fillWidth: true
        implicitHeight: 44

        Rectangle {
            anchors.fill: parent
            radius: Theme.rowRadius
            color: rowMouse.pressed ? Theme.rowPressed : rowMouse.containsMouse ? Theme.rowHover : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            enabled: row.hasPage
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.opened()
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            spacing: 10

            CcToggle {
                code: row.code
                checked: row.checked
                interactive: row.toggleable
                onClicked: row.toggled()
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: row.title
                    color: Theme.panelFg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontBody
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: row.subtitle
                    color: Theme.altFg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontCaption
                    elide: Text.ElideRight
                }
            }

            Glyph {
                visible: row.hasPage
                code: 0xF0142  // chevron-right
                size: 14
                color: Theme.altFg
                opacity: rowMouse.containsMouse ? 1 : 0
                transform: Translate { x: rowMouse.containsMouse ? 0 : -6; Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } } }
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }
    }

    // Square-ish tile with a toggle circle and a label (Do Not Disturb, Keep Awake)
    component Tile: CcModule {
        id: tile

        property int code
        property string label
        property bool checked
        signal toggled()

        Layout.fillWidth: true
        Layout.fillHeight: true
        implicitHeight: 56
        color: tileMouse.containsMouse ? Theme.hoverFill : Theme.moduleBg
        Behavior on color { ColorAnimation { duration: 150 } }

        MouseArea {
            id: tileMouse
            width: tile.width - 2 * tile.padding
            height: tile.height - 2 * tile.padding
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.toggled()
        }

        RowLayout {
            width: tile.width - 2 * tile.padding
            height: tile.height - 2 * tile.padding
            spacing: 8

            CcToggle {
                code: tile.code
                checked: tile.checked
                onClicked: tile.toggled()
            }
            Text {
                Layout.fillWidth: true
                text: tile.label
                color: Theme.panelFg
                font.family: Theme.font
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Bold
                wrapMode: Text.WordWrap
                lineHeight: 0.95
            }
        }
    }

    // Header of a list page: back, title, power switch
    component PageHeader: RowLayout {
        id: header

        property string title
        property bool checked
        signal toggled()

        Layout.fillWidth: true
        spacing: 6

        CcIconButton {
            code: 0xF0141  // chevron-left
            size: 30
            glyphSize: 16
            onClicked: cc.page = "main"
        }
        Text {
            Layout.fillWidth: true
            text: header.title
            color: Theme.panelFg
            font.family: Theme.font
            font.pixelSize: Theme.fontTitle
            font.weight: Font.Bold
        }
        CcSwitch {
            Layout.rightMargin: 4
            checked: header.checked
            onToggled: header.toggled()
        }
    }

    // Plain clickable row: glyph circle + label (AirDrop page actions)
    component ActionRow: Item {
        id: action

        property int code
        property string label
        signal clicked()

        Layout.fillWidth: true
        implicitHeight: 40

        Rectangle {
            anchors.fill: parent
            radius: Theme.rowRadius
            color: actionMouse.pressed ? Theme.rowPressed : actionMouse.containsMouse ? Theme.rowHover : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.clicked()
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            spacing: 10

            CcToggle {
                size: 28
                interactive: false
                code: action.code
            }
            Text {
                Layout.fillWidth: true
                text: action.label
                color: Theme.panelFg
                font.family: Theme.font
                font.pixelSize: Theme.fontBody
                elide: Text.ElideRight
            }
        }
    }

    // Listening-mode button in the AirPods module: circle + caption underneath
    component ModeButton: ColumnLayout {
        id: modeBtn

        property int code
        property string label
        property string mode            // LibrePods' menu text for this mode
        readonly property bool available: AirPods.modes.some(e => e.text === mode)

        Layout.fillWidth: true
        Layout.preferredWidth: 1        // equal widths
        spacing: 4
        visible: available

        CcToggle {
            Layout.alignment: Qt.AlignHCenter
            size: 36
            code: modeBtn.code
            checked: AirPods.mode === modeBtn.mode
            onClicked: AirPods.setMode(modeBtn.mode)
        }
        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: modeBtn.label
            color: AirPods.mode === modeBtn.mode ? Theme.panelFg : Theme.altFg
            font.family: Theme.font
            font.pixelSize: 10
            wrapMode: Text.WordWrap
            lineHeight: 0.95
        }
    }

    component Divider: Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        implicitHeight: 1
        color: Theme.divider
    }

    component Placeholder: Text {
        Layout.fillWidth: true
        Layout.topMargin: 14
        Layout.bottomMargin: 14
        horizontalAlignment: Text.AlignHCenter
        color: Theme.dim
        font.family: Theme.font
        font.pixelSize: Theme.fontSizeSmall
    }

    // Shared slide-in for the three pages: on-screen when `active`, off to `awayX` otherwise
    component Page: ColumnLayout {
        id: pg
        property bool active
        property real awayX
        x: cc.pad + (active ? 0 : awayX)
        y: cc.pad
        width: cc.panelWidth - 2 * cc.pad
        spacing: 10
        opacity: active ? 1 : 0
        visible: opacity > 0
        enabled: active
        Behavior on x { NumberAnimation { duration: 420; easing.type: Easing.OutQuint } }
        Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    }

    // ---- Window -----------------------------------------------------------------------------

    Popover {
        id: win

        bar: cc.bar
        open: cc.open
        align: "right"
        panelWidth: cc.panelWidth
        panelHeight: pager.height
        panelRadius: cc.panelRadius
        onCloseRequested: cc.close()
        backAction: () => {
            if (cc.page === "main") return false;
            cc.page = "main";
            return true;
        }

        // Pages; the panel's height follows the visible one
        Item {
            id: pager

            width: parent.width
            height: 2 * cc.pad + (cc.page === "wifi" ? wifiPage.implicitHeight
                                : cc.page === "bluetooth" ? btPage.implicitHeight
                                : cc.page === "airdrop" ? airdropPage.implicitHeight
                                : mainPage.implicitHeight)
            clip: true
            Behavior on height { NumberAnimation { duration: 420; easing.type: Easing.OutQuint } }

            // ---- Main page ----
            Page {
                id: mainPage
                active: cc.page === "main"
                awayX: -width * 0.3

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    // Connectivity
                    CcModule {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        padding: 4
                        shown: cc.open
                        delay: 0

                        ColumnLayout {
                            width: parent.width
                            spacing: 2

                            ConnRow {
                                code: Networking.wifiEnabled ? (cc.wifiNetwork ? cc.wifiGlyph(cc.wifiNetwork.signalStrength) : 0xF05A9) : 0xF05AA
                                title: "Wi-Fi"
                                subtitle: !Networking.wifiEnabled ? "Off" : cc.wifiNetwork?.name ?? "Not Connected"
                                checked: Networking.wifiEnabled
                                toggleable: cc.wifiDevice !== null
                                hasPage: cc.wifiDevice !== null
                                onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                                onOpened: cc.page = "wifi"
                            }
                            ConnRow {
                                code: !cc.btOn ? 0xF00B2 : cc.btConnected.length > 0 ? 0xF00B1 : 0xF00AF
                                title: "Bluetooth"
                                subtitle: !cc.adapter ? "Unavailable"
                                        : !cc.btOn ? "Off"
                                        : cc.btConnected.length === 1 ? cc.btConnected[0].name
                                        : cc.btConnected.length > 1 ? cc.btConnected.length + " Devices"
                                        : "On"
                                checked: cc.btOn
                                toggleable: cc.adapter !== null
                                hasPage: cc.adapter !== null
                                onToggled: cc.adapter.enabled = !cc.adapter.enabled
                                onOpened: cc.page = "bluetooth"
                            }
                            ConnRow {
                                code: 0xF0003  // access-point
                                title: "AirDrop"
                                subtitle: AirDrop.status === "off" ? "Off" : AirDrop.status === "idle" || AirDrop.status === "armed" ? "Receiving" : AirDrop.summary
                                checked: AirDrop.on
                                hasPage: true
                                onToggled: AirDrop.toggle()
                                onOpened: cc.page = "airdrop"
                            }
                            ConnRow {
                                visible: cc.wiredDevice !== null
                                code: 0xF0200
                                title: "Ethernet"
                                subtitle: cc.wiredDevice?.hasLink ? "Connected" : "Unplugged"
                                checked: cc.wiredDevice?.hasLink ?? false
                                toggleable: false
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.preferredWidth: 124
                        Layout.maximumWidth: 124
                        Layout.fillHeight: true
                        spacing: 10

                        Tile {
                            shown: cc.open
                            delay: 40
                            code: 0xF0594  // moon
                            label: "Do Not Disturb"
                            checked: ShellState.doNotDisturb
                            onToggled: ShellState.doNotDisturb = !ShellState.doNotDisturb
                        }
                        Tile {
                            shown: cc.open
                            delay: 70
                            code: 0xF0176  // coffee
                            label: "Keep Awake"
                            checked: ShellState.keepAwake
                            onToggled: ShellState.keepAwake = !ShellState.keepAwake
                        }
                    }
                }

                // AirPods (while connected)
                CcModule {
                    Layout.fillWidth: true
                    visible: AirPods.connected
                    shown: cc.open
                    delay: 85
                    padding: 10

                    ColumnLayout {
                        width: parent.width
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            CcToggle {
                                size: 32
                                interactive: false
                                checked: true
                                code: 0xF184F  // earbuds
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    Layout.fillWidth: true
                                    text: AirPods.device?.name ?? "AirPods"
                                    color: Theme.panelFg
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontBody
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    function fmt(label, b) {
                                        return b.level < 0 ? "" : label + " " + b.level + "%" + (b.charging ? "⚡" : "");
                                    }
                                    text: !AirPods.running ? "LibrePods isn't running"
                                        : [fmt("L", AirPods.left), fmt("R", AirPods.right), fmt("Case", AirPods.caseBattery)]
                                            .filter(s => s !== "").join("  ") || "Connected"
                                    color: Theme.altFg
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontCaption
                                    elide: Text.ElideRight
                                }
                            }
                            CcIconButton {
                                visible: AirPods.running
                                code: 0xF01D8  // dots-horizontal
                                size: 28
                                glyphSize: 16
                                onClicked: { cc.close(); AirPods.openWindow(); }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            visible: AirPods.modes.length > 0
                            spacing: 4

                            ModeButton { code: 0xF10D3; label: "Off"; mode: "Off" }                       // circle-off-outline
                            ModeButton { code: 0xF02CB; label: "Noise Cancel"; mode: "Noise Cancellation" } // headphones
                            ModeButton { code: 0xF07C5; label: "Transparency"; mode: "Transparency" }       // ear-hearing
                            ModeButton { code: 0xF0068; label: "Adaptive"; mode: "Adaptive" }               // auto-fix
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 4
                            Layout.rightMargin: 4
                            visible: AirPods.conversation !== null
                            spacing: 8

                            Glyph {
                                code: 0xF05CB  // account-voice
                                size: 16
                                color: Theme.accent
                            }
                            Text {
                                Layout.fillWidth: true
                                text: "Conversation Awareness"
                                color: Theme.panelFg
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSizeSmall
                                elide: Text.ElideRight
                            }
                            CcSwitch {
                                opacity: AirPods.conversation?.enabled ? 1 : 0.4
                                checked: AirPods.conversation?.checkState === Qt.Checked
                                onToggled: AirPods.toggleConversation()
                            }
                        }
                    }
                }

                // Sound
                CcModule {
                    Layout.fillWidth: true
                    shown: cc.open
                    delay: 100
                    padding: 12

                    ColumnLayout {
                        width: parent.width
                        spacing: 8

                        Text {
                            text: "Sound"
                            color: Theme.panelFg
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Bold
                        }
                        CcSlider {
                            Layout.fillWidth: true
                            readonly property var audio: cc.sink?.audio ?? null
                            value: audio?.volume ?? 0
                            muted: audio?.muted ?? true
                            code: muted || value <= 0 ? 0xF075F : value < 0.34 ? 0xF057F : value < 0.67 ? 0xF0580 : 0xF057E
                            onMoved: v => { if (audio) { audio.muted = false; ShellState.setVolume(cc.sink, v); } }
                            onIconClicked: if (audio) audio.muted = !audio.muted
                        }
                        Text {
                            Layout.topMargin: 2
                            text: "Microphone"
                            color: Theme.panelFg
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Bold
                        }
                        CcSlider {
                            Layout.fillWidth: true
                            readonly property var audio: cc.source?.audio ?? null
                            value: audio?.volume ?? 0
                            muted: audio?.muted ?? true
                            code: muted ? 0xF036D : 0xF036C
                            onMoved: v => { if (audio) { audio.muted = false; ShellState.setVolume(cc.source, v); } }
                            onIconClicked: if (audio) audio.muted = !audio.muted
                        }
                    }
                }

                // Now Playing
                CcModule {
                    id: media
                    Layout.fillWidth: true
                    visible: cc.player !== null
                    shown: cc.open
                    delay: 130
                    padding: 10

                    readonly property var p: cc.player

                    ColumnLayout {
                        width: parent.width
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            ClippingRectangle {
                                implicitWidth: 46
                                implicitHeight: 46
                                radius: 8
                                color: Theme.control

                                Glyph {
                                    anchors.centerIn: parent
                                    code: 0xF075A  // music
                                    size: 20
                                    color: Theme.altFg
                                    visible: art.status !== Image.Ready
                                }
                                Image {
                                    id: art
                                    anchors.fill: parent
                                    source: media.p?.trackArtUrl ?? ""
                                    fillMode: Image.PreserveAspectCrop
                                    sourceSize.width: 92
                                    sourceSize.height: 92
                                    asynchronous: true
                                    opacity: status === Image.Ready ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: 300 } }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: media.p?.trackTitle || media.p?.identity || "Not Playing"
                                    color: Theme.panelFg
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontBody
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: media.p?.trackArtist || media.p?.identity || ""
                                    color: Theme.altFg
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontCaption
                                    elide: Text.ElideRight
                                }
                            }

                            CcIconButton {
                                code: 0xF04AE  // skip-previous
                                enabledLook: media.p?.canGoPrevious ?? false
                                onClicked: media.p.previous()
                            }

                            // Play/pause: the two glyphs cross-fade and swap scale
                            Item {
                                implicitWidth: 34
                                implicitHeight: 34

                                Rectangle {
                                    anchors.fill: parent
                                    radius: width / 2
                                    color: playMouse.pressed ? Theme.controlPressed : playMouse.containsMouse ? Theme.hoverFill : "transparent"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                Repeater {
                                    model: [{ code: 0xF040A, playing: false }, { code: 0xF03E4, playing: true }]
                                    delegate: Glyph {
                                        required property var modelData
                                        readonly property bool on: (media.p?.isPlaying ?? false) === modelData.playing
                                        anchors.centerIn: parent
                                        code: modelData.code
                                        size: 22
                                        color: Theme.accent
                                        opacity: on ? 1 : 0
                                        scale: on ? (playMouse.pressed ? 0.8 : 1) : 0.4
                                        rotation: on ? 0 : (modelData.playing ? -90 : 90)
                                        Behavior on opacity { NumberAnimation { duration: 200 } }
                                        Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 2 } }
                                        Behavior on rotation { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                                    }
                                }
                                MouseArea {
                                    id: playMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (media.p?.canTogglePlaying) media.p.togglePlaying()
                                }
                            }

                            CcIconButton {
                                code: 0xF04AD  // skip-next
                                enabledLook: media.p?.canGoNext ?? false
                                onClicked: media.p.next()
                            }
                        }

                        // Progress
                        Rectangle {
                            Layout.fillWidth: true
                            visible: (media.p?.lengthSupported ?? false) && media.p.length > 0
                            implicitHeight: 4
                            radius: 2
                            color: Theme.progressTrack

                            Rectangle {
                                height: parent.height
                                radius: 2
                                color: Theme.accent
                                width: media.p && media.p.length > 0
                                    ? parent.width * Math.min(1, media.p.position / media.p.length) : 0
                                Behavior on width { NumberAnimation { duration: 1000 } }
                            }
                        }
                    }
                }

                // Power
                CcModule {
                    Layout.fillWidth: true
                    shown: cc.open
                    delay: 160
                    padding: 10

                    RowLayout {
                        width: parent.width
                        spacing: 0

                        CcPowerButton {
                            Layout.fillWidth: true
                            code: 0xF033E  // lock
                            label: "Lock"
                            onTriggered: { cc.close(); Quickshell.execDetached(["loginctl", "lock-session"]); }
                        }
                        CcPowerButton {
                            Layout.fillWidth: true
                            code: 0xF0343  // logout
                            label: "Log Out"
                            confirm: true
                            onTriggered: Quickshell.execDetached(["sh", "-c", "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"])
                        }
                        CcPowerButton {
                            Layout.fillWidth: true
                            code: 0xF0709  // restart
                            label: "Restart"
                            confirm: true
                            onTriggered: Quickshell.execDetached(["systemctl", "reboot"])
                        }
                        CcPowerButton {
                            Layout.fillWidth: true
                            code: 0xF0425  // power
                            label: "Shut Down"
                            confirm: true
                            onTriggered: Quickshell.execDetached(["systemctl", "poweroff"])
                        }
                    }
                }
            }

            // ---- Wi-Fi page ----
            Page {
                id: wifiPage
                active: cc.page === "wifi"
                awayX: width
                spacing: 6

                PageHeader {
                    title: "Wi-Fi"
                    checked: Networking.wifiEnabled
                    onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                }
                Divider {}

                Placeholder {
                    visible: wifiList.count === 0
                    text: !Networking.wifiEnabled ? "Wi-Fi is off" : "Looking for networks…"
                }

                ListView {
                    id: wifiList
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 360)
                    visible: count > 0
                    clip: true
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
                    model: ScriptModel {
                        values: !Networking.wifiEnabled || !cc.wifiDevice ? []
                            : [...cc.wifiDevice.networks.values]
                                .filter(n => n.name !== "")
                                .sort((a, b) => (b.connected - a.connected) || (b.known - a.known)
                                                || (b.signalStrength - a.signalStrength))
                    }

                    add: Transition {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220 }
                        NumberAnimation { property: "x"; from: 16; to: 0; duration: 320; easing.type: Easing.OutCubic }
                    }
                    displaced: Transition {
                        NumberAnimation { properties: "x,y"; duration: 300; easing.type: Easing.OutCubic }
                    }
                    move: displaced

                    delegate: Item {
                        id: net

                        required property var modelData
                        readonly property bool secure: modelData.security !== WifiSecurityType.Open
                                                    && modelData.security !== WifiSecurityType.Owe
                        property bool asking: false   // password field shown
                        property bool failed: false

                        width: ListView.view.width
                        height: 44 + (asking ? 46 : 0)
                        clip: true
                        Behavior on height { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

                        Connections {
                            target: net.modelData
                            function onConnectionFailed(reason) {
                                net.failed = true;
                                if (net.secure) {
                                    net.asking = true;
                                    password.forceActiveFocus();
                                }
                            }
                            function onConnectedChanged() {
                                if (net.modelData.connected) {
                                    net.failed = false;
                                    net.asking = false;
                                    password.text = "";
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 44
                            radius: Theme.rowRadius
                            color: netMouse.pressed ? Theme.rowPressed : netMouse.containsMouse ? Theme.rowHover : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: netMouse
                            width: parent.width
                            height: 44
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const n = net.modelData;
                                if (n.connected) {
                                    n.disconnect();
                                } else if (n.known || !net.secure) {
                                    net.failed = false;
                                    n.connect();
                                } else {
                                    net.asking = !net.asking;
                                    if (net.asking) password.forceActiveFocus();
                                }
                            }
                        }

                        RowLayout {
                            x: 6
                            width: parent.width - 12
                            height: 44
                            spacing: 10

                            CcToggle {
                                size: 28
                                interactive: false
                                checked: net.modelData.connected
                                code: cc.wifiGlyph(net.modelData.signalStrength)
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    Layout.fillWidth: true
                                    text: net.modelData.name
                                    color: Theme.panelFg
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontBody
                                    font.weight: net.modelData.connected ? Font.Bold : Font.Normal
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    readonly property string status: net.modelData.stateChanging ? "Connecting…"
                                        : net.modelData.connected ? "Connected"
                                        : net.failed ? "Couldn't connect" : ""
                                    visible: status !== ""
                                    text: status
                                    color: Theme.altFg
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontCaption
                                }
                            }
                            Glyph {
                                visible: net.secure
                                Layout.rightMargin: 14
                                code: 0xF033E  // lock
                                size: 12
                                color: Theme.dim
                            }
                        }

                        // Password entry for a new secured network
                        Rectangle {
                            x: 6
                            y: 48
                            width: parent.width - 12
                            height: 36
                            radius: Theme.rowRadius
                            color: Theme.inputBg
                            border.width: 1
                            border.color: password.activeFocus ? Theme.focusRing : Theme.divider
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            TextInput {
                                id: password
                                anchors.left: parent.left
                                anchors.right: join.left
                                anchors.leftMargin: 12
                                anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                echoMode: TextInput.Password
                                color: Theme.fg
                                selectionColor: Theme.focusRing
                                font.family: Theme.font
                                font.pixelSize: Theme.fontBody
                                clip: true
                                onAccepted: join.submit()

                                Text {
                                    visible: password.text === ""
                                    text: "Password"
                                    color: Theme.dim
                                    font: password.font
                                }
                            }

                            CcIconButton {
                                id: join
                                anchors.right: parent.right
                                anchors.rightMargin: 3
                                anchors.verticalCenter: parent.verticalCenter
                                size: 30
                                glyphSize: 16
                                code: 0xF0054  // arrow-right
                                enabledLook: password.text.length >= 8
                                function submit() {
                                    if (password.text.length < 8) return;
                                    net.failed = false;
                                    net.modelData.connectWithPsk(password.text);
                                }
                                onClicked: submit()
                            }
                        }
                    }
                }
            }

            // ---- Bluetooth page ----
            Page {
                id: btPage
                active: cc.page === "bluetooth"
                awayX: width
                spacing: 6

                PageHeader {
                    title: "Bluetooth"
                    checked: cc.btOn
                    onToggled: if (cc.adapter) cc.adapter.enabled = !cc.adapter.enabled
                }
                Divider {}

                Placeholder {
                    visible: btList.count === 0
                    text: !cc.btOn ? "Bluetooth is off" : "No paired devices"
                }

                ListView {
                    id: btList
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 360)
                    visible: count > 0
                    clip: true
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
                    model: ScriptModel {
                        values: !cc.btOn ? []
                            : cc.adapter.devices.values
                                .filter(d => d.paired || d.connected)
                                .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
                    }

                    add: Transition {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220 }
                        NumberAnimation { property: "x"; from: 16; to: 0; duration: 320; easing.type: Easing.OutCubic }
                    }
                    displaced: Transition {
                        NumberAnimation { properties: "x,y"; duration: 300; easing.type: Easing.OutCubic }
                    }
                    move: displaced

                    delegate: Item {
                        id: dev

                        required property var modelData
                        readonly property bool busy: modelData.state === BluetoothDeviceState.Connecting
                                                  || modelData.state === BluetoothDeviceState.Disconnecting
                                                  || modelData.pairing

                        width: ListView.view.width
                        height: 44

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.rowRadius
                            color: devMouse.pressed ? Theme.rowPressed : devMouse.containsMouse ? Theme.rowHover : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: devMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: dev.modelData.connected ? dev.modelData.disconnect() : dev.modelData.connect()
                        }

                        RowLayout {
                            x: 6
                            width: parent.width - 12
                            height: parent.height
                            spacing: 10

                            CcToggle {
                                size: 28
                                interactive: false
                                checked: dev.modelData.connected
                                code: cc.btGlyph(dev.modelData.icon)

                                // Pulses while connecting/disconnecting
                                SequentialAnimation on opacity {
                                    running: dev.busy
                                    loops: Animation.Infinite
                                    onStopped: parent.opacity = 1
                                    NumberAnimation { to: 0.4; duration: 500; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: 1; duration: 500; easing.type: Easing.InOutSine }
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    Layout.fillWidth: true
                                    text: dev.modelData.name
                                    color: Theme.panelFg
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontBody
                                    font.weight: dev.modelData.connected ? Font.Bold : Font.Normal
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: dev.modelData.state === BluetoothDeviceState.Connecting ? "Connecting…"
                                        : dev.modelData.state === BluetoothDeviceState.Disconnecting ? "Disconnecting…"
                                        : dev.modelData.connected
                                            ? "Connected" + (dev.modelData.batteryAvailable ? " · " + cc.percent(dev.modelData.battery) : "")
                                        : "Not Connected"
                                    color: Theme.altFg
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontCaption
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }

            // ---- AirDrop page ----
            Page {
                id: airdropPage
                active: cc.page === "airdrop"
                awayX: width
                spacing: 6

                PageHeader {
                    title: "AirDrop"
                    checked: AirDrop.on
                    onToggled: AirDrop.toggle()
                }
                Divider {}

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    Layout.leftMargin: 6
                    Layout.rightMargin: 6
                    spacing: 10

                    CcToggle {
                        size: 36
                        code: 0xF0003  // access-point
                        checked: AirDrop.on
                        onClicked: AirDrop.toggle()

                        // Pulses while starting up or moving a file
                        SequentialAnimation on opacity {
                            running: AirDrop.busy
                            loops: Animation.Infinite
                            onStopped: parent.opacity = 1
                            NumberAnimation { to: 0.4; duration: 600; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutSine }
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            Layout.fillWidth: true
                            text: AirDrop.summary
                            color: Theme.panelFg
                            font.family: Theme.font
                            font.pixelSize: Theme.fontBody
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: AirDrop.on ? "Uses the Wi-Fi card while on" : "Receive files from iPhone and Mac"
                            color: Theme.altFg
                            font.family: Theme.font
                            font.pixelSize: Theme.fontCaption
                            elide: Text.ElideRight
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: 6
                    Layout.rightMargin: 6
                    Layout.bottomMargin: 4
                    text: AirDrop.status === "error" ? AirDrop.detail
                        : AirDrop.on
                        ? "On the iPhone, set AirDrop to Everyone for 10 Minutes, then share to this computer. Files land in Downloads; AirDrop turns itself off a minute after the last one."
                        : "Turn on, then on the iPhone set AirDrop to Everyone for 10 Minutes and share to this computer."
                    color: AirDrop.status === "error" ? Theme.altFg : Theme.dim
                    font.family: Theme.font
                    font.pixelSize: Theme.fontCaption
                    wrapMode: Text.WordWrap
                }

                Divider {}

                ActionRow {
                    code: 0xF022A  // file-send
                    label: "Send File…"
                    onClicked: { cc.close(); AirDrop.sendFiles(); }
                }
                ActionRow {
                    code: 0xF024D  // folder-download
                    label: "Open Downloads"
                    onClicked: { cc.close(); AirDrop.openDownloads(); }
                }
            }
        }
    }
}
