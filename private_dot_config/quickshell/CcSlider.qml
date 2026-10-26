// macOS Control Center slider: white fill with the icon riding inside it, thickens while hovered or dragged.
// Click the icon to mute; drag/click the track or scroll to set the value.
import QtQuick

Item {
    id: slider

    property real value: 0          // 0..1
    property bool muted: false
    property int code
    signal moved(real value)
    signal iconClicked()

    readonly property bool engaged: mouse.containsMouse || mouse.pressed
    readonly property real shown: muted ? 0 : Math.max(0, Math.min(1, value))

    implicitHeight: 28

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: slider.engaged ? 28 : 24
        radius: height / 2
        color: Theme.sliderTrack
        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 2 } }

        Rectangle {
            id: fill
            height: parent.height
            radius: height / 2
            width: height + slider.shown * (parent.width - height)
            color: slider.muted ? Theme.sliderMuted : Theme.accent
            Behavior on width { enabled: !mouse.pressed; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 200 } }

            // Knob: a faint ring at the end of the fill
            Rectangle {
                anchors.right: parent.right
                width: parent.height
                height: parent.height
                radius: height / 2
                color: "transparent"
                border.width: 1
                border.color: Theme.knobRing
            }
        }

        Glyph {
            x: (track.height - width) / 2
            anchors.verticalCenter: parent.verticalCenter
            code: slider.code
            size: 15
            color: Theme.accentFg
            scale: iconMouse.pressed ? 0.8 : 1
            Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.002 } }
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: slider.muted ? "Muted" : Math.round(slider.value * 100) + "%"
            color: fill.width > track.width - 44 ? Theme.accentFg : Theme.altFg
            font.family: Theme.font
            font.pixelSize: Theme.fontCaption
            opacity: slider.engaged ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.PointingHandCursor

        function set(x) {
            const h = track.height;
            slider.moved(Math.max(0, Math.min(1, (x - h / 2) / (width - h))));
        }
        onPressed: m => { if (m.x > track.height) set(m.x); }
        onPositionChanged: m => { if (pressed && !iconMouse.pressed) set(m.x); }
        onWheel: w => slider.moved(Math.max(0, Math.min(1, slider.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
    }

    // On top of the track's MouseArea: the icon end toggles mute
    MouseArea {
        id: iconMouse
        width: track.height
        height: parent.height
        cursorShape: Qt.PointingHandCursor
        onClicked: slider.iconClicked()
    }
}
