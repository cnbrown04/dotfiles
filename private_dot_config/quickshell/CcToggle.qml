// Round toggle button (macOS Control Center): white with a dark glyph when on, translucent when off.
// Squishes on press and springs back.
import QtQuick

Rectangle {
    id: toggle

    property bool checked: false
    property int code
    property int size: 32
    property bool interactive: true
    signal clicked()

    implicitWidth: size
    implicitHeight: size
    radius: size / 2
    color: checked ? Theme.accent : mouse.containsMouse && interactive ? Theme.controlHover : Theme.control
    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }

    scale: mouse.pressed && interactive ? 0.86 : 1
    Behavior on scale { SpringAnimation { spring: 5; damping: 0.28; epsilon: 0.002 } }

    Glyph {
        anchors.centerIn: parent
        code: toggle.code
        size: Math.round(toggle.size * 0.56)
        color: toggle.checked ? Theme.accentFg : Theme.accent
        Behavior on color { ColorAnimation { duration: 220 } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: toggle.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (toggle.interactive) toggle.clicked()
    }
}
