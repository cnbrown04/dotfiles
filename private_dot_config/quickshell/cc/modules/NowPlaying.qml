// Now Playing (MPRIS: the playing player, else the first one): art, title, artist, transport, progress.
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs
import qs.cc

CcModule {
    id: media

    property var cc
    readonly property bool available: CcUtil.player !== null
    readonly property var p: CcUtil.player

    shown: cc.open
    padding: 10

    // MPRIS doesn't push position updates; poll while playing
    Timer {
        running: media.cc.open && (media.p?.isPlaying ?? false)
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: media.p.positionChanged()
    }

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

                // Keyboard navigation (ControlCenter.qml): Enter/Space play/pause
                readonly property bool ccNav: true
                readonly property int navRadius: 19
                function navActivate() { if (media.p?.canTogglePlaying) media.p.togglePlaying(); }
                function navToggle() { navActivate(); }

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
