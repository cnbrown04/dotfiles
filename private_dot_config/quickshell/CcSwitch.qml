// Pill switch for the detail pages' headers. The knob slides with a little overshoot.
import QtQuick

Rectangle {
    id: sw

    property bool checked: false
    signal toggled()

    implicitWidth: 40
    implicitHeight: 24
    radius: height / 2
    color: checked ? Theme.accent : Theme.switchOff
    Behavior on color { ColorAnimation { duration: 200 } }

    Rectangle {
        id: knob
        width: sw.height - 4 + (mouse.pressed ? 4 : 0)
        height: sw.height - 4
        radius: height / 2
        y: 2
        x: sw.checked ? sw.width - width - 2 : 2
        color: sw.checked ? Theme.accentFg : Theme.accent
        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.8 } }
        Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: sw.toggled()
    }
}
